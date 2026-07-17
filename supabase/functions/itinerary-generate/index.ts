// Supabase Edge Function — Atlas Itinerary generation (OpenAI JSON).
// Deploy: supabase functions deploy itinerary-generate
// Secret: supabase secrets set OPENAI_API_KEY=sk-...

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, accept",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const apiKey = Deno.env.get("OPENAI_API_KEY");
    if (!apiKey) {
      return jsonError("OPENAI_API_KEY manquante", 503);
    }

    const body = await req.json();
    const model = typeof body.model === "string" ? body.model : "gpt-4o-mini";
    const seedTrip = body.seed_trip ?? null;
    const request = body.request ?? {};
    const candidates = Array.isArray(body.candidate_places)
      ? body.candidate_places
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
    });

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
      const errText = await upstream.text();
      return jsonError(`OpenAI error: ${errText}`, 502);
    }

    const payload = await upstream.json();
    const content = payload.choices?.[0]?.message?.content ?? "{}";
    let parsed: Record<string, unknown>;
    try {
      parsed = JSON.parse(content);
    } catch {
      parsed = { trip: seedTrip, warnings: ["JSON AI invalide"] };
    }

    if (!parsed.trip && seedTrip) {
      parsed = { trip: seedTrip, warnings: ["trip manquant — seed conservé"] };
    }

    return new Response(JSON.stringify(parsed), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return jsonError(String(error), 500);
  }
});

function jsonError(message: string, status: number) {
  return new Response(JSON.stringify({ error: message, warnings: [message] }), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
