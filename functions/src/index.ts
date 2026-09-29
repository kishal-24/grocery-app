import * as admin from "firebase-admin";
import {setGlobalOptions} from "firebase-functions";
import {onDocumentWritten} from "firebase-functions/v2/firestore";
import {HttpsError, onCall, onRequest, Request} from "firebase-functions/v2/https";
import {Response} from "express";
import {processCancelOrder, processCreateOrder} from "./orders";
import {seedInitialDatabase} from "./seed";
import {CreateOrderRequest} from "./types";
import {
  handleUserDocumentChange,
  resolveUserEmail,
  setUserRole as assignUserRole,
} from "./users";

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp();
}

setGlobalOptions({maxInstances: 10});

/**
 * Helper to authenticate Bearer token for HTTP endpoints
 */
async function authenticateBearer(req: Request): Promise<{
  uid: string;
  isAdmin: boolean;
  email?: string;
}> {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    throw new HttpsError(
      "unauthenticated",
      "Missing or invalid Authorization header."
    );
  }
  const idToken = authHeader.split("Bearer ")[1];
  const decoded = await admin.auth().verifyIdToken(idToken);
  return {
    uid: decoded.uid,
    isAdmin: decoded.admin === true || decoded.role === "admin",
    email: decoded.email,
  };
}

/**
 * Helper to handle CORS
 */
function handleCors(req: Request, res: Response): boolean {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
  res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return true;
  }
  return false;
}

// ============================================================
// 1. SECURE ORDERS (CALLABLE & HTTP)
// ============================================================

/**
 * Secure order creation callable for client app
 */
export const createOrder = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Authentication required to place an order."
    );
  }
  return await processCreateOrder(
    request.auth.uid,
    request.data as CreateOrderRequest
  );
});

/**
 * HTTP REST endpoint for creating orders
 */
export const createOrderApi = onRequest(async (req, res) => {
  if (handleCors(req, res)) return;
  try {
    const authUser = await authenticateBearer(req);
    const result = await processCreateOrder(authUser.uid, req.body);
    res.status(200).json(result);
  } catch (error: any) {
    const status =
      error.code === "unauthenticated"
        ? 401
        : error.code === "permission-denied"
        ? 403
        : error.code === "not-found"
        ? 404
        : error.code === "failed-precondition" ||
          error.code === "invalid-argument"
        ? 400
        : 500;
    res.status(status).json({error: error.message || "Failed to create order"});
  }
});

/**
 * Secure order cancellation callable
 */
export const cancelOrder = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Authentication required to cancel an order."
    );
  }
  const orderId = request.data?.orderId;
  const isAdmin = request.auth.token.admin === true;
  return await processCancelOrder(request.auth.uid, orderId, isAdmin);
});

/**
 * HTTP REST endpoint for cancelling orders
 */
export const cancelOrderApi = onRequest(async (req, res) => {
  if (handleCors(req, res)) return;
  try {
    const authUser = await authenticateBearer(req);
    const orderId = req.body?.orderId || req.query?.orderId;
    const result = await processCancelOrder(
      authUser.uid,
      orderId as string,
      authUser.isAdmin
    );
    res.status(200).json(result);
  } catch (error: any) {
    const status =
      error.code === "unauthenticated"
        ? 401
        : error.code === "permission-denied"
        ? 403
        : error.code === "not-found"
        ? 404
        : error.code === "failed-precondition"
        ? 400
        : 500;
    res.status(status).json({error: error.message || "Failed to cancel order"});
  }
});

// ============================================================
// 2. USERNAME LOGIN & CONSISTENCY (CALLABLE & HTTP)
// ============================================================

/**
 * Resolve username to email for login
 */
export const resolveUsername = onCall(async (request) => {
  const username = request.data?.username;
  return await resolveUserEmail(username);
});

/**
 * HTTP REST endpoint for resolving username
 */
export const resolveUsernameApi = onRequest(async (req, res) => {
  if (handleCors(req, res)) return;
  try {
    const username = (req.body?.username || req.query?.username) as string;
    const result = await resolveUserEmail(username);
    res.status(200).json(result);
  } catch (error: any) {
    res.status(404).json({error: error.message || "Username not found"});
  }
});

/**
 * Assign role to a user (admin only)
 */
export const setUserRole = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }
  const {targetUid, role} = request.data;
  return await assignUserRole(request.auth.uid, targetUid, role);
});

/**
 * HTTP REST endpoint for setting user role
 */
export const setUserRoleApi = onRequest(async (req, res) => {
  if (handleCors(req, res)) return;
  try {
    const authUser = await authenticateBearer(req);
    const {targetUid, role} = req.body;
    const result = await assignUserRole(authUser.uid, targetUid, role);
    res.status(200).json(result);
  } catch (error: any) {
    res.status(error.code === "permission-denied" ? 403 : 400).json({
      error: error.message || "Failed to set role",
    });
  }
});

// ============================================================
// 3. FIRESTORE USER PROFILE TRIGGER
// ============================================================

/**
 * Automatically sync username mapping and enforce usernameLower / username_lowercase consistency
 */
export const onUserDocumentWritten = onDocumentWritten(
  "users/{userId}",
  async (event) => {
    const userId = event.params.userId;
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();

    await handleUserDocumentChange(userId, beforeData, afterData);
  }
);

// ============================================================
// 4. DATABASE SEED UTILITY
// ============================================================

export const seedDatabase = onRequest(async (req, res) => {
  if (handleCors(req, res)) return;
  try {
    // Only allow seed in emulator or when authorized
    const isEmulator =
      process.env.FUNCTIONS_EMULATOR === "true" ||
      process.env.FIREBASE_EMULATOR_HUB !== undefined;

    if (!isEmulator) {
      const authUser = await authenticateBearer(req);
      if (!authUser.isAdmin) {
        res.status(403).json({error: "Admin privileges required."});
        return;
      }
    }

    const counts = await seedInitialDatabase();
    res.status(200).json({
      success: true,
      message: "Database seeded successfully.",
      counts,
    });
  } catch (error: any) {
    res.status(500).json({error: error.message || "Failed to seed database"});
  }
});
