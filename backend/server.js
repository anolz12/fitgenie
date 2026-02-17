const express = require("express");
const cors = require("cors");

const app = express();
const port = process.env.PORT || 8080;

app.use(cors());
app.use(express.json({ limit: "1mb" }));

app.get("/health", (_req, res) => {
  res.status(200).json({ ok: true });
});

function getApiKey() {
  return process.env.OPENROUTER_API_KEY || process.env.API_KEY;
}

function getModel() {
  return process.env.OPENROUTER_MODEL || "openai/gpt-4o-mini";
}

function appHeaders(apiKey) {
  return {
    "Content-Type": "application/json",
    Authorization: `Bearer ${apiKey}`,
    "HTTP-Referer":
      process.env.OPENROUTER_REFERER || "https://fitgenie-g82z.onrender.com",
    "X-Title": process.env.OPENROUTER_APP_NAME || "FitGenie",
  };
}

async function openRouterChat({ apiKey, messages, temperature = 0.6, maxTokens = 500 }) {
  const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
    method: "POST",
    headers: appHeaders(apiKey),
    body: JSON.stringify({
      model: getModel(),
      messages,
      temperature,
      max_tokens: maxTokens,
    }),
  });

  if (response.status === 429) {
    return {
      ok: false,
      status: 429,
      data: null,
      error: {
        reply:
          "I am temporarily rate-limited right now. Please try again in about a minute.",
      },
    };
  }

  const data = await response.json();
  if (!response.ok) {
    return { ok: false, status: response.status, data: null, error: data };
  }

  const text = data?.choices?.[0]?.message?.content?.trim() || "";
  return { ok: true, status: 200, data: text, error: null };
}

function tryParseJsonText(text) {
  if (!text) return null;
  try {
    return JSON.parse(text);
  } catch (_) {
    // try fenced JSON block
    const fenceMatch = text.match(/```json\s*([\s\S]*?)\s*```/i);
    if (fenceMatch && fenceMatch[1]) {
      try {
        return JSON.parse(fenceMatch[1]);
      } catch (_) {}
    }
    const firstBrace = text.indexOf("{");
    const lastBrace = text.lastIndexOf("}");
    if (firstBrace >= 0 && lastBrace > firstBrace) {
      try {
        return JSON.parse(text.slice(firstBrace, lastBrace + 1));
      } catch (_) {}
    }
  }
  return null;
}

app.post("/chat", async (req, res) => {
  const apiKey = getApiKey();
  if (!apiKey) return res.status(500).json({ error: "Missing API key on server" });

  const message = (req.body?.message || "").toString().trim();
  const history = Array.isArray(req.body?.history) ? req.body.history : [];
  if (!message) return res.status(400).json({ error: "message is required" });

  const messages = [
    {
      role: "system",
      content:
        "You are FitGenie AI, a concise fitness and wellness coach. " +
        "Give practical guidance and avoid medical diagnosis.",
    },
    ...history
      .filter((item) => item && item.content)
      .slice(-8)
      .map((item) => ({
        role: item.role === "assistant" ? "assistant" : "user",
        content: String(item.content),
      })),
    { role: "user", content: message },
  ];

  try {
    const result = await openRouterChat({
      apiKey,
      messages,
      temperature: 0.6,
      maxTokens: 350,
    });

    if (!result.ok) {
      if (result.status === 429) return res.status(200).json(result.error);
      return res
        .status(502)
        .json({ error: "OpenRouter request failed", detail: JSON.stringify(result.error) });
    }

    const reply = result.data || "I could not generate a response right now.";
    return res.status(200).json({ reply });
  } catch (_) {
    return res.status(500).json({ error: "Internal server error" });
  }
});

app.post("/generate-workouts", async (req, res) => {
  const apiKey = getApiKey();
  if (!apiKey) return res.status(500).json({ error: "Missing API key on server" });

  const goal = (req.body?.goal || "General fitness").toString();
  const equipment = (req.body?.equipment || "None").toString();
  const timePerSession = (req.body?.timePerSession || "30 min").toString();
  const fitnessLevel = (req.body?.fitnessLevel || "Beginner").toString();

  const messages = [
    {
      role: "system",
      content:
        "You are a workout programming assistant. Return strict JSON only, no markdown.",
    },
    {
      role: "user",
      content:
        "Generate a 7-day workout library for a fitness app. " +
        `Goal: ${goal}. Equipment: ${equipment}. Time: ${timePerSession}. Level: ${fitnessLevel}. ` +
        "Return JSON object with key workouts (array of 8 items). " +
        "Each item must have: title (string), focus (string), durationMinutes (int 10-90).",
    },
  ];

  try {
    const result = await openRouterChat({
      apiKey,
      messages,
      temperature: 0.4,
      maxTokens: 700,
    });

    if (!result.ok) {
      if (result.status === 429) {
        return res.status(200).json({ workouts: [], note: result.error.reply });
      }
      return res
        .status(502)
        .json({ error: "OpenRouter request failed", detail: JSON.stringify(result.error) });
    }

    const parsed = tryParseJsonText(result.data);
    const rawWorkouts = Array.isArray(parsed?.workouts) ? parsed.workouts : [];
    const workouts = rawWorkouts
      .map((w) => ({
        title: (w?.title || "").toString().trim(),
        focus: (w?.focus || "").toString().trim(),
        durationMinutes: Number(w?.durationMinutes) || 0,
      }))
      .filter((w) => w.title && w.focus && w.durationMinutes > 0)
      .slice(0, 12);

    return res.status(200).json({ workouts });
  } catch (_) {
    return res.status(500).json({ error: "Internal server error" });
  }
});

app.post("/generate-wellness", async (req, res) => {
  const apiKey = getApiKey();
  if (!apiKey) return res.status(500).json({ error: "Missing API key on server" });

  const goal = (req.body?.goal || "Stress relief").toString();

  const messages = [
    {
      role: "system",
      content:
        "You are a wellness programming assistant. Return strict JSON only, no markdown.",
    },
    {
      role: "user",
      content:
        `Generate 6 guided wellness sessions for goal: ${goal}. ` +
        "Return JSON object with key sessions (array). " +
        "Each item must have: title (string), duration (e.g. '5 min'), " +
        "description (string), category (Breathing|Meditation|Mobility|Sleep).",
    },
  ];

  try {
    const result = await openRouterChat({
      apiKey,
      messages,
      temperature: 0.5,
      maxTokens: 700,
    });

    if (!result.ok) {
      if (result.status === 429) {
        return res.status(200).json({ sessions: [], note: result.error.reply });
      }
      return res
        .status(502)
        .json({ error: "OpenRouter request failed", detail: JSON.stringify(result.error) });
    }

    const parsed = tryParseJsonText(result.data);
    const rawSessions = Array.isArray(parsed?.sessions) ? parsed.sessions : [];
    const sessions = rawSessions
      .map((s) => ({
        title: (s?.title || "").toString().trim(),
        duration: (s?.duration || "").toString().trim(),
        description: (s?.description || "").toString().trim(),
        category: (s?.category || "Meditation").toString().trim(),
      }))
      .filter((s) => s.title && s.duration && s.description)
      .slice(0, 10);

    return res.status(200).json({ sessions });
  } catch (_) {
    return res.status(500).json({ error: "Internal server error" });
  }
});

app.listen(port, () => {
  console.log(`FitGenie chat backend listening on ${port}`);
});
