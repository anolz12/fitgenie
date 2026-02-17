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
  const apiKey = process.env.GOOGLE_AI_API_KEY || process.env.API_KEY;
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
      role: item.role === "assistant" ? "model" : "user",
      parts: [{ text: String(item.content) }],
    }));

  const body = {
    systemInstruction: {
      role: "user",
      parts: [
        {
          text:
            "You are FitGenie AI, a concise fitness and wellness coach. " +
            "Give practical guidance and avoid medical diagnosis.",
        },
      ],
    },
    contents: [
      ...normalizedHistory,
      { role: "user", parts: [{ text: message }] },
    ],
    generationConfig: {
      temperature: 0.6,
      topP: 0.9,
      maxOutputTokens: 350,
    },
  };

  try {
    const candidateModels = [
      "gemini-2.0-flash",
      "gemini-1.5-flash-002",
      "gemini-1.5-pro-002",
    ];

    let data = null;
    let lastErrorText = "";

    for (const model of candidateModels) {
      const response = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(body),
        }
      );

      if (response.ok) {
        data = await response.json();
        break;
      }

      lastErrorText = await response.text();
      if (response.status !== 404) {
        return res
          .status(502)
          .json({ error: "Gemini request failed", detail: lastErrorText });
      }
    }

    if (!data) {
      return res
        .status(502)
        .json({ error: "No supported Gemini model found", detail: lastErrorText });
    }

    const reply =
      data?.candidates?.[0]?.content?.parts
        ?.map((p) => p.text || "")
        .join("")
        .trim() || "I could not generate a response right now.";

    return res.status(200).json({ reply });
  } catch (e) {
    return res.status(500).json({ error: "Internal server error" });
  }
});

app.listen(port, () => {
  console.log(`FitGenie chat backend listening on ${port}`);
});
