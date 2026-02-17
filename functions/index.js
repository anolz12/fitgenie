const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

exports.fitgenieChat = onRequest({ region: "us-central1" }, async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
    res.set("Access-Control-Allow-Methods", "POST, OPTIONS");

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    if (req.method !== "POST") {
      res.status(405).json({ error: "Method not allowed" });
      return;
    }

    const authHeader = req.get("Authorization") || "";
    const idToken = authHeader.startsWith("Bearer ")
      ? authHeader.slice(7)
      : "";

    if (!idToken) {
      res.status(401).json({ error: "Missing auth token" });
      return;
    }

    try {
      await admin.auth().verifyIdToken(idToken);
    } catch (e) {
      logger.warn("Invalid Firebase ID token", e);
      res.status(401).json({ error: "Invalid auth token" });
      return;
    }

    const message = (req.body?.message || "").toString().trim();
    const history = Array.isArray(req.body?.history) ? req.body.history : [];

    if (!message) {
      res.status(400).json({ error: "message is required" });
      return;
    }

    const apiKey = process.env.GOOGLE_AI_API_KEY || process.env.API_KEY;
    if (!apiKey) {
      logger.error("GOOGLE_AI_API_KEY not configured");
      res.status(500).json({ error: "Server not configured" });
      return;
    }

    const toGeminiRole = (role) => (role === "assistant" ? "model" : "user");
    const normalizedHistory = history
      .filter((item) => item && item.content)
      .slice(-8)
      .map((item) => ({
        role: toGeminiRole(item.role),
        parts: [{ text: String(item.content) }],
      }));

    const systemPrompt =
      "You are FitGenie AI, a concise fitness and wellness coach. " +
      "Give safe, practical guidance and avoid medical diagnosis.";

    const body = {
      systemInstruction: {
        role: "user",
        parts: [{ text: systemPrompt }],
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
      const response = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(body),
        }
      );

      if (!response.ok) {
        const text = await response.text();
        logger.error("Gemini API error", { status: response.status, text });
        res.status(502).json({ error: "Model request failed" });
        return;
      }

      const data = await response.json();
      const reply =
        data?.candidates?.[0]?.content?.parts
          ?.map((p) => p.text || "")
          .join("")
          .trim() || "I could not generate a response right now.";

      res.status(200).json({ reply });
    } catch (e) {
      logger.error("fitgenieChat failed", e);
      res.status(500).json({ error: "Internal server error" });
    }
  }
);
