// Supabase Edge Function — Atlas Assistant (OpenAI streaming).
// Deploy: supabase functions deploy assistant-chat
// Secrets: OPENAI_API_KEY (SUPABASE_URL / SUPABASE_ANON_KEY provided by platform)

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
      return jsonError("Service Assistant indisponible.", 503);
    }

    const body = await req.json();
    const model = resolveModel(body.model);
    const system =
      typeof body.system === "string"
        ? body.system
        : "Tu es l'Assistant Atlas pour le Maroc.";
    const messages = Array.isArray(body.messages) ? body.messages : [];
    const knowledge = Array.isArray(body.knowledge) ? body.knowledge : [];

    if (messages.length > 40) {
      return jsonError("Conversation trop longue.", 400);
    }

    const knowledgeBlock = knowledge.length
      ? "\n\nExtraits Atlas (RAG stub):\n" +
        knowledge
          .slice(0, 8)
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
          content: m.content.slice(0, 8000),
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
      return jsonError("Service Assistant temporairement indisponible.", 502);
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
                  encoder.encode(
                    `data: ${JSON.stringify({ type: "done" })}\n\n`,
                  ),
                );
                continue;
              }
              try {
                const parsed = JSON.parse(data);
                const delta = parsed.choices?.[0]?.delta?.content;
                if (typeof delta === "string" && delta.length > 0) {
                  controller.enqueue(
                    encoder.encode(
                      `data: ${
                        JSON.stringify({ type: "delta", text: delta })
                      }\n\n`,
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
                          completion_tokens:
                            parsed.usage.completion_tokens ?? 0,
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
        } catch {
          controller.enqueue(
            encoder.encode(
              `data: ${
                JSON.stringify({
                  type: "error",
                  message: "Flux Assistant interrompu.",
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
  } catch {
    return jsonError("Erreur Assistant.", 500);
  }
});
