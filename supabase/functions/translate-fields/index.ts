// translate-fields — translate an array of Korean admission-data strings into
// English (or Uzbek) for the staff review screen. Staff-gated (fn_can_review_uni_db).
// Anthropic-only: Opus 4.7 primary, Sonnet 4.6 fallback (both Claude). No Gemini.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY");

// Opus first (best quality); Sonnet as a same-provider fallback so the function
// keeps working even if the account doesn't yet have Opus 4.7 access.
const MODELS = ["claude-opus-4-7", "claude-sonnet-4-6"];

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "content-type": "application/json" } });

const LANG_NAME: Record<string, string> = { en: "English", uz: "Uzbek" };

async function verifyReviewer(authHeader: string | null): Promise<string | null> {
  if (!authHeader?.startsWith("Bearer ")) return null;
  const userClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await userClient.auth.getUser();
  if (error || !data?.user) return null;
  const { data: ok } = await userClient.rpc("fn_can_review_uni_db");
  return ok === true ? data.user.id : null;
}

function buildSystem(target: string): string {
  const name = LANG_NAME[target] ?? "English";
  return (
    `You translate Korean university-admission text into ${name}. ` +
    `Keep proper names, numbers, dates, codes and percentages intact. ` +
    `If an input is empty or already ${name}, return it unchanged. ` +
    `Return ONLY a JSON object {"translations": [...]} whose array has exactly ` +
    `the same length and order as the input "texts" array.`
  );
}

async function callAnthropic(model: string, system: string, texts: string[]): Promise<string> {
  const resp = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "x-api-key": ANTHROPIC_API_KEY!,
      "anthropic-version": "2023-06-01",
      "content-type": "application/json",
    },
    body: JSON.stringify({
      model,
      max_tokens: 8000,
      temperature: 0,
      system,
      messages: [{ role: "user", content: JSON.stringify({ texts }) }],
    }),
  });
  if (!resp.ok) throw new Error(`anthropic(${model}) ${resp.status} ${(await resp.text()).slice(0, 200)}`);
  const d = await resp.json();
  const text = Array.isArray(d.content)
    ? d.content.filter((b: any) => b?.type === "text").map((b: any) => b.text).join("")
    : "";
  if (!text) throw new Error(`anthropic(${model}) empty response`);
  return text;
}

function parseTranslations(raw: string, n: number): string[] {
  let t = raw.trim().replace(/^```(?:json)?/i, "").replace(/```$/i, "").trim();
  let obj: any;
  try {
    obj = JSON.parse(t);
  } catch {
    const s = t.indexOf("{");
    const e = t.lastIndexOf("}");
    obj = s !== -1 && e > s ? JSON.parse(t.slice(s, e + 1)) : { translations: [] };
  }
  const arr = Array.isArray(obj.translations) ? obj.translations : [];
  return Array.from({ length: n }, (_, i) => (typeof arr[i] === "string" ? arr[i] : ""));
}

// Temporary diagnostic: record what happened so we can read it from SQL
// (the sandbox can't invoke the function or see response bodies).
async function logDiag(detail: string): Promise<void> {
  try {
    const svc = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, { auth: { persistSession: false } });
    await svc.from("uni_db_fn_errors").insert({ fn: "translate-fields", detail });
  } catch (_) { /* best-effort */ }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json(405, { error: "method_not_allowed" });

  const uid = await verifyReviewer(req.headers.get("Authorization"));
  if (!uid) return json(403, { error: "forbidden" });
  if (!ANTHROPIC_API_KEY) {
    // Diagnostic: report which AI-ish secret NAMES are visible (never values),
    // to pinpoint a name/project mismatch.
    const candidates = ["ANTHROPIC_API_KEY", "ANTHROPIC_KEY", "ANTHROPIC", "CLAUDE_API_KEY",
                        "CLAUDE_KEY", "ANTHROPIC_API", "ANTHROPICAPIKEY", "Anthropic_Api_Key"];
    const present = candidates.filter((c) => !!Deno.env.get(c));
    let aiNames: string[] = [];
    try { aiNames = Object.keys(Deno.env.toObject()).filter((k) => /ANTHROP|CLAUDE|GEMINI/i.test(k)); } catch (_) { /* enum may be restricted */ }
    await logDiag(`ai_not_configured. exact_name_present=${JSON.stringify(present)} ai_env_names=${JSON.stringify(aiNames)}`);
    return json(500, { error: "ai_not_configured" });
  }

  let body: any;
  try { body = await req.json(); } catch { return json(400, { error: "invalid_json" }); }

  const texts = Array.isArray(body.texts) ? body.texts.map((x: unknown) => String(x ?? "")) : null;
  if (!texts) return json(400, { error: "texts_array_required" });
  if (texts.length === 0) return json(200, { translations: [] });
  if (texts.length > 100) return json(400, { error: "too_many_texts" });

  const target = body.target_lang === "uz" ? "uz" : "en";
  const system = buildSystem(target);

  const errors: string[] = [];
  for (const model of MODELS) {
    try {
      const raw = await callAnthropic(model, system, texts);
      await logDiag(`ok via ${model}`);
      return json(200, { translations: parseTranslations(raw, texts.length), target_lang: target, model });
    } catch (e) {
      errors.push(String(e).slice(0, 200));
    }
  }
  const joined = errors.join(" | ");
  console.error("translate-fields error", joined);
  await logDiag(joined.slice(0, 1000));
  return json(502, { error: "translation_failed", detail: joined });
});
