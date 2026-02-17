const express = require("express");
const cors = require("cors");

const app = express();
const port = process.env.PORT || 8080;

app.use(cors());
app.use(express.json({ limit: "1mb" }));

app.get("/health", (_req, res) => {
  res.status(200).json({ ok: true });
});

app.post("/chat", async (req, res) => {
  const apiKey = process.env.OPENROUTER_API_KEY || process.env.API_KEY;
  if (!apiKey) {
    return res.status(500).json({ error: "Missing API key on server" });
  }

  const message = (req.body?.message || "").toString().trim();
  const history = Array.isArray(req.body?.history) ? req.body.history : [];
  if (!message) {
    return res.status(400).json({ error: "message is required" });
  }

  const normalizedHistory = history
    .filter((item) => item && item.content)
    .slice(-8)
    .map((item) => ({
      role: item.role === "assistant" ? "assistant" : "user",
      content: String(item.content),
    }));

  try {
    const model = process.env.OPENROUTER_MODEL || "openai/gpt-4o-mini";
    const body = {
      model,
      messages: [
        {
          role: "system",
          content:
            "You are FitGenie AI, a concise fitness and wellness coach. " +
            "Give practical guidance and avoid medical diagnosis.",
        },
        ...normalizedHistory,
        { role: "user", content: message },
      ],
      temperature: 0.6,
      max_tokens: 350,
    };

    const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
        "HTTP-Referer":
          process.env.OPENROUTER_REFERER || "https://fitgenie-g82z.onrender.com",
        "X-Title": process.env.OPENROUTER_APP_NAME || "FitGenie",
      },
      body: JSON.stringify(body),
    });

    if (response.status === 429) {
      return res.status(200).json({
        reply:
          "I am temporarily rate-limited right now. Please try again in about a minute.",
      });
    }

    const data = await response.json();

    if (!response.ok) {
      return res
        .status(502)
        .json({ error: "OpenRouter request failed", detail: JSON.stringify(data) });
    }

    const reply =
      data?.choices?.[0]?.message?.content?.trim() ||
      "I could not generate a response right now.";

    return res.status(200).json({ reply });
  } catch (e) {
    return res.status(500).json({ error: "Internal server error" });
  }
});

app.listen(port, () => {
  console.log(`FitGenie chat backend listening on ${port}`);
});
