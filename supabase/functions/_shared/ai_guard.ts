// Shared AI guard for Atlas Edge Functions.
// Requires: SUPABASE_URL, SUPABASE_ANON_KEY (and user JWT on the request).
// Rate limits enforced via RPC consume_ai_request() (5 anon / 20 signed-in).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

export const ALLOWED_MODELS = new Set(["gpt-4o-mini"]);

export const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, accept",
};

export function jsonError(message: string, status: number) {
  // Never forward upstream provider error bodies to clients.
  return new Response(JSON.stringify({ type: "error", message }), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

export function resolveModel(_requested: unknown): string {
  // Client-supplied model is ignored — server allowlist only.
  return "gpt-4o-mini";
}

export async function requireUserAndRateLimit(req: Request): Promise<
  | { ok: true; userId: string; usage: Record<string, unknown> }
  | { ok: false; response: Response }
> {
  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.toLowerCase().startsWith("bearer ")) {
    return {
      ok: false,
      response: jsonError("Authentification requise.", 401),
    };
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  if (!supabaseUrl || !anonKey) {
    return {
      ok: false,
      response: jsonError("Configuration serveur incomplète.", 503),
    };
  }

  const supabase = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: userData, error: userError } = await supabase.auth.getUser();
  if (userError || !userData.user) {
    return {
      ok: false,
      response: jsonError("Session invalide.", 401),
    };
  }

  const { data: usage, error: usageError } = await supabase.rpc(
    "consume_ai_request",
  );
  if (usageError) {
    return {
      ok: false,
      response: jsonError("Limite IA indisponible.", 503),
    };
  }

  const payload = (usage ?? {}) as {
    allowed?: boolean;
    reason?: string;
    count?: number;
    limit?: number;
  };

  if (!payload.allowed) {
    const status = payload.reason === "unauthenticated" ? 401 : 429;
    return {
      ok: false,
      response: jsonError(
        payload.reason === "rate_limited"
          ? "Limite quotidienne d'Assistant Atlas atteinte."
          : "Authentification requise.",
        status,
      ),
    };
  }

  return {
    ok: true,
    userId: userData.user.id,
    usage: payload as Record<string, unknown>,
  };
}
