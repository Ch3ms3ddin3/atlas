// Supabase Edge Function — Atlas Assistant (OpenAI streaming).
// Deploy: supabase functions deploy assistant-chat
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
    const system =
      typeof body.system === "string"
        ? body.system
        : "Tu es l'Assistant Atlas pour le Maroc.";
    const messages = Array.isArray(body.messages) ? body.messages : [];
    const knowledge = Array.isArray(body.knowledge) ? body.knowledge : [];

    const knowledgeBlock = knowledge.length
      ? "\n\nExtraits Atlas (RAG stub):\n" +
        knowledge
          .map(
            (k: { title?: string; content?: string }) =>
              `- ${k.title ?? "source"}: ${k.content ?? ""}`,
          )
          .join("\n")
      : "";

    const openAiMessages = [
      { role: "system", content: system + knowledgeBlock },
      ...messages
        .filter(
          (m: { role?: string; content?: string }) =>
            m &&
            (m.role === "user" || m.role === "assistant") &&
            typeof m.content === "string",
        )
        .map((m: { role: string; content: string }) => ({
          role: m.role,
          content: m.content,
        })),
    ];

    const upstream = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model,
        stream: true,
        stream_options: { include_usage: true },
        messages: openAiMessages,
        temperature: 0.4,
      }),
    });

    if (!upstream.ok || !upstream.body) {
      const errText = await upstream.text();
      return jsonError(`OpenAI error: ${errText}`, 502);
    }

    const encoder = new TextEncoder();
    const decoder = new TextDecoder();
    let buffer = "";

    const stream = new ReadableStream({
      async start(controller) {
        const reader = upstream.body!.getReader();
        try {
          while (true) {
            const { done, value } = await reader.read();
            if (done) break;
            buffer += decoder.decode(value, { stream: true });
            const lines = buffer.split("\n");
            buffer = lines.pop() ?? "";
            for (const raw of lines) {
              const line = raw.trim();
              if (!line.startsWith("data:")) continue;
              const data = line.slice(5).trim();
              if (data === "[DONE]") {
                controller.enqueue(
                  encoder.encode(`data: ${JSON.stringify({ type: "done" })}\n\n`),
                );
                continue;
              }
              try {
                const parsed = JSON.parse(data);
                const delta = parsed.choices?.[0]?.delta?.content;
                if (typeof delta === "string" && delta.length > 0) {
                  controller.enqueue(
                    encoder.encode(
                      `data: ${JSON.stringify({ type: "delta", text: delta })}\n\n`,
                    ),
                  );
                }
                if (parsed.usage) {
                  controller.enqueue(
                    encoder.encode(
                      `data: ${
                        JSON.stringify({
                          type: "usage",
                          prompt_tokens: parsed.usage.prompt_tokens ?? 0,
                          completion_tokens: parsed.usage.completion_tokens ?? 0,
                        })
                      }\n\n`,
                    ),
                  );
                }
              } catch {
                // ignore malformed chunks
              }
            }
          }
          controller.enqueue(
            encoder.encode(`data: ${JSON.stringify({ type: "done" })}\n\n`),
          );
          controller.close();
        } catch (error) {
          controller.enqueue(
            encoder.encode(
              `data: ${
                JSON.stringify({
                  type: "error",
                  message: String(error),
                })
              }\n\n`,
            ),
          );
          controller.close();
        }
      },
    });

    return new Response(stream, {
      headers: {
        ...corsHeaders,
        "Content-Type": "text/event-stream; charset=utf-8",
        "Cache-Control": "no-cache",
        Connection: "keep-alive",
      },
    });
  } catch (error) {
    return jsonError(String(error), 500);
  }
});

function jsonError(message: string, status: number) {
  return new Response(JSON.stringify({ type: "error", message }), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
