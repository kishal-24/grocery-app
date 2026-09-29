import * as admin from "firebase-admin";
import {HttpsError} from "firebase-functions/v2/https";

const getDb = () => admin.firestore();

/**
 * Resolves a username or email to an authenticated account's email and uid.
 */
export async function resolveUserEmail(
  usernameOrEmail: string
): Promise<{ email: string; uid?: string; username?: string }> {
  const input = (usernameOrEmail || "").trim();
  if (!input) {
    throw new HttpsError(
      "invalid-argument",
      "Please provide a username or email address."
    );
  }

  // Already an email
  if (input.includes("@")) {
    return {email: input.toLowerCase()};
  }

  const lower = input.toLowerCase();
  const db = getDb();

  // 1. Direct lookup in public 'usernames' collection
  const usernameDoc = await db.collection("usernames").doc(lower).get();
  if (usernameDoc.exists) {
    const data = usernameDoc.data();
    if (data && data.email) {
      return {
        email: data.email,
        uid: data.uid,
        username: data.username || lower,
      };
    }
  }

  // 2. Fallback: Query 'users' collection by 'usernameLower'
  let userSnap = await db
    .collection("users")
    .where("usernameLower", "==", lower)
    .limit(1)
    .get();

  if (userSnap.empty) {
    // 3. Fallback: Query by 'username_lowercase'
    userSnap = await db
      .collection("users")
      .where("username_lowercase", "==", lower)
      .limit(1)
      .get();
  }

  if (!userSnap.empty) {
    const doc = userSnap.docs[0];
    const data = doc.data();
    const email = data.email;
    if (email) {
      // Self-heal: backfill usernames mapping
      await db.collection("usernames").doc(lower).set(
        {
          uid: doc.id,
          email: email,
          username: data.username || lower,
          usernameLower: lower,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        {merge: true}
      );

      return {
        email: email,
        uid: doc.id,
        username: data.username || lower,
      };
    }
  }

  throw new HttpsError(
    "not-found",
    `No account found with username "${input}".`
  );
}

/**
 * Syncs user profile changes to usernames collection and Firebase Auth claims.
 */
export async function handleUserDocumentChange(
  userId: string,
  beforeData?: FirebaseFirestore.DocumentData,
  afterData?: FirebaseFirestore.DocumentData
): Promise<void> {
  const db = getDb();

  // Document deleted
  if (!afterData) {
    const oldLower = (
      beforeData?.usernameLower ||
      beforeData?.username_lowercase ||
      beforeData?.username ||
      ""
    )
      .toLowerCase()
      .trim();

    if (oldLower) {
      try {
        await db.collection("usernames").doc(oldLower).delete();
      } catch (_err) {}
    }
    return;
  }

  const rawUsername =
    afterData.usernameLower ||
    afterData.username_lowercase ||
    afterData.username ||
    "";
  const currentLower = (rawUsername as string).toLowerCase().trim();

  const rawOldUsername =
    beforeData?.usernameLower ||
    beforeData?.username_lowercase ||
    beforeData?.username ||
    "";
  const oldLower = (rawOldUsername as string).toLowerCase().trim();

  // If username changed, delete the old mapping
  if (oldLower && oldLower !== currentLower) {
    try {
      await db.collection("usernames").doc(oldLower).delete();
    } catch (_err) {}
  }

  // Update or create new username mapping
  if (currentLower && afterData.email) {
    await db.collection("usernames").doc(currentLower).set(
      {
        uid: userId,
        email: afterData.email,
        username: afterData.username || currentLower,
        usernameLower: currentLower,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true}
    );
  }

  // Ensure usernameLower and username_lowercase consistency on the user document
  const needsConsistencyUpdate =
    currentLower &&
    (afterData.usernameLower !== currentLower ||
      afterData.username_lowercase !== currentLower);

  if (needsConsistencyUpdate) {
    await db.collection("users").doc(userId).set(
      {
        usernameLower: currentLower,
        username_lowercase: currentLower,
      },
      {merge: true}
    );
  }

  // Sync role to custom claims
  const role = afterData.role || "customer";
  const isAdmin = role === "admin";

  try {
    const userRecord = await admin.auth().getUser(userId);
    const existingClaims = userRecord.customClaims || {};

    if (existingClaims.admin !== isAdmin || existingClaims.role !== role) {
      await admin.auth().setCustomUserClaims(userId, {
        ...existingClaims,
        admin: isAdmin,
        role: role,
      });
    }
  } catch (_err) {
    // User might not exist in Auth (e.g. mock test)
  }
}

/**
 * Assigns role to a user. Can only be performed by admins or bootstrap.
 */
export async function setUserRole(
  callerUid: string,
  targetUid: string,
  newRole: "customer" | "admin"
): Promise<{ success: boolean; message: string }> {
  if (!callerUid) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  const db = getDb();

  // Verify caller is admin
  const callerDoc = await db.collection("users").doc(callerUid).get();
  const callerRole = callerDoc.data()?.role;

  const callerUser = await admin.auth().getUser(callerUid);
  const isCallerAdmin =
    callerRole === "admin" || callerUser.customClaims?.admin === true;

  if (!isCallerAdmin) {
    throw new HttpsError(
      "permission-denied",
      "Only administrators can assign user roles."
    );
  }

  // Update user document
  await db.collection("users").doc(targetUid).set(
    {
      role: newRole,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {merge: true}
  );

  // Update Auth Custom Claims
  await admin.auth().setCustomUserClaims(targetUid, {
    admin: newRole === "admin",
    role: newRole,
  });

  return {
    success: true,
    message: `User ${targetUid} role successfully updated to ${newRole}.`,
  };
}
