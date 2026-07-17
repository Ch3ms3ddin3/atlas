// Supabase Edge Function — Atlas Itinerary generation (OpenAI JSON).
// Deploy: supabase functions deploy itinerary-generate

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import {
  corsHeaders,
  jsonError,
  requireUserAndRateLimit,
  resolveModel,
} from "../_shared/ai_guard.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const gate = await requireUserAndRateLimit(req);
    if (!gate.ok) return gate.response;

    const apiKey = Deno.env.get("OPENAI_API_KEY");
    if (!apiKey) {
      return jsonError("Service itinéraires indisponible.", 503);
    }

    const body = await req.json();
    const model = resolveModel(body.model);
    const seedTrip = body.seed_trip ?? null;
    const request = body.request ?? {};
    const candidates = Array.isArray(body.candidate_places)
      ? body.candidate_places.slice(0, 40)
      : [];

    const system = `Tu es le planificateur d'itinéraires Atlas pour le Maroc.
Règles:
- Réponds UNIQUEMENT en JSON valide: { "trip": {…}, "warnings": string[] }
- Ne invente PAS de lieux hors de candidate_places (utilise leurs id).
- Maximum 14 jours. Respecte start_date / end_date.
- Soft prayer-aware: notes seulement, ne retire pas d'arrêts.
- Weather-aware: notes si météo difficile.
- Conserve la structure seed_trip si fournie (id, days, stops).
- Titres en français.`;

    const userContent = JSON.stringify({
      request,
      candidate_places: candidates,
      seed_trip: seedTrip,
    }).slice(0, 120000);

    const upstream = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model,
        temperature: 0.3,
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: system },
          { role: "user", content: userContent },
        ],
      }),
    });

    if (!upstream.ok) {
      return jsonError("Service itinéraires temporairement indisponible.", 502);
    }

    const payload = await upstream.json();
    const content = payload.choices?.[0]?.message?.content ?? "{}";
    let parsed: Record<string, unknown>;
    try {
      parsed = JSON.parse(content);
    } catch {
      parsed = { trip: seedTrip, warnings: ["Réponse AI invalide"] };
    }

    if (!parsed.trip && seedTrip) {
      parsed = { trip: seedTrip, warnings: ["trip manquant — seed conservé"] };
    }

    return new Response(JSON.stringify(parsed), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch {
    return jsonError("Erreur itinéraires.", 500);
  }
});
