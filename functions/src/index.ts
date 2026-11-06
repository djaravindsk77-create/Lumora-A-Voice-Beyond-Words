/**
 * Lumora Cloud Functions (optional).
 *
 * The app runs fully without these functions in Demo Mode. Deploy them only
 * if you enable Firebase cloud sync. They never contain secrets - AI keys
 * arrive through Firebase secrets (`firebase functions:secrets:set`).
 */
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

/**
 * Creates a short invite code when a parent invites a collaborator.
 * The client stores the permission record; this only mints the code.
 */
export const createInvite = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign-in required.");
  }
  const role = String(request.data?.role ?? "teacher");
  const code = `LUMORA-${Math.random().toString(36).slice(2, 8).toUpperCase()}`;
  logger.info("Invite minted", { role, uid: request.auth.uid });
  return { code, role, expiresInDays: 7 };
});

/**
 * Relays a safety alert to the configured FCM tokens of trusted contacts.
 * The app records the alert with an honest status; this function performs
 * the actual fan-out and is the only place that could mark it "sent".
 */
export const relaySafetyAlert = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign-in required.");
  }
  const { childId, message, tokens } = request.data ?? {};
  if (!childId || !message || !Array.isArray(tokens)) {
    throw new HttpsError("invalid-argument", "childId, message and tokens required.");
  }
  // Production: use firebase-admin.messaging to send and report per-token.
  logger.info("Alert relay requested", { childId, tokenCount: tokens.length });
  return { delivered: 0, status: "pending" };
});

/**
 * Optional AI proxy: keeps the AI key server-side. Returns null fields when
 * no key is configured so the client falls back to its rule-based engine.
 */
export const aiAssist = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign-in required.");
  }
  const { task, text } = request.data ?? {};
  const key = process.env.AI_API_KEY;
  if (!key || !text) {
    return { ok: false, reason: "ai-not-configured", translation: null, story: null };
  }
  logger.info("AI assist requested", { task: String(task ?? "translate") });
  // Production: forward to your model endpoint with the server-side key.
  return { ok: false, reason: "not-implemented", translation: null, story: null };
});
