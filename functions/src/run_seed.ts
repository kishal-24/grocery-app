import {DEFAULT_CATEGORIES, DEFAULT_PRODUCTS, DEFAULT_PROMOS} from "./seed";
import * as os from "os";
import * as path from "path";
import * as fs from "fs";

const PROJECT_ID = "grocery-db70e";
const DATABASE_ID = "(default)";
const BASE_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/${DATABASE_ID}/documents:commit`;

function getGlobalAuthModule() {
  const possiblePaths = [
    path.join(process.env.APPDATA || "", "npm/node_modules/firebase-tools/lib/auth"),
    path.join(os.homedir(), "AppData/Roaming/npm/node_modules/firebase-tools/lib/auth"),
  ];

  for (const p of possiblePaths) {
    if (fs.existsSync(p + ".js")) {
      return require(p);
    }
  }

  // Fallback to resolving from require
  return require("firebase-tools/lib/auth");
}

async function getValidAccessToken(): Promise<string> {
  const configPath = path.join(os.homedir(), ".config/configstore/firebase-tools.json");
  if (!fs.existsSync(configPath)) {
    throw new Error(`Firebase login config not found at ${configPath}. Please run 'firebase login'.`);
  }

  const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
  const refreshToken = config.tokens?.refresh_token;
  const scopes = config.tokens?.scopes || [
    "openid",
    "https://www.googleapis.com/auth/userinfo.email",
    "https://www.googleapis.com/auth/firebase",
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/datastore",
  ];

  if (!refreshToken) {
    throw new Error("No refresh_token found in firebase-tools.json. Please run 'firebase login'.");
  }

  const auth = getGlobalAuthModule();
  const tokenResult = await auth.getAccessToken(refreshToken, scopes);
  if (!tokenResult?.access_token) {
    throw new Error("Failed to retrieve valid access token from refresh token.");
  }

  return tokenResult.access_token;
}

function toFirestoreValue(val: any): any {
  if (val === null || val === undefined) {
    return {nullValue: null};
  }
  if (typeof val === "boolean") {
    return {booleanValue: val};
  }
  if (typeof val === "number") {
    if (Number.isInteger(val)) {
      return {integerValue: val.toString()};
    }
    return {doubleValue: val};
  }
  if (typeof val === "string") {
    return {stringValue: val};
  }
  if (Array.isArray(val)) {
    return {
      arrayValue: {
        values: val.map((item) => toFirestoreValue(item)),
      },
    };
  }
  if (typeof val === "object") {
    const fields: Record<string, any> = {};
    for (const [k, v] of Object.entries(val)) {
      fields[k] = toFirestoreValue(v);
    }
    return {mapValue: {fields}};
  }
  return {stringValue: String(val)};
}

function createUpdateWrite(collection: string, docId: string, data: Record<string, any>) {
  const fields: Record<string, any> = {};
  for (const [key, val] of Object.entries(data)) {
    fields[key] = toFirestoreValue(val);
  }

  // Include server timestamp as ISO string or timestampValue
  fields["updatedAt"] = {timestampValue: new Date().toISOString()};

  return {
    update: {
      name: `projects/${PROJECT_ID}/databases/${DATABASE_ID}/documents/${collection}/${docId}`,
      fields,
    },
  };
}

async function sendBatch(writes: any[], token: string) {
  const res = await fetch(BASE_URL, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({writes}),
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Firestore commit failed (${res.status} ${res.statusText}): ${text}`);
  }

  return await res.json();
}

async function run() {
  console.log("=========================================");
  console.log(" Starting Firebase Firestore Seeding...");
  console.log(` Project: ${PROJECT_ID}`);
  console.log("=========================================");

  const token = await getValidAccessToken();
  console.log(" Authenticated successfully via Firebase CLI.");

  const allWrites: any[] = [];

  // 1. Categories
  for (const cat of DEFAULT_CATEGORIES) {
    allWrites.push(createUpdateWrite("categories", cat.id, cat));
  }
  console.log(` Prepared ${DEFAULT_CATEGORIES.length} categories.`);

  // 2. Products (100 items)
  for (const prod of DEFAULT_PRODUCTS) {
    allWrites.push(createUpdateWrite("products", prod.id, prod));
  }
  console.log(` Prepared ${DEFAULT_PRODUCTS.length} products.`);

  // 3. Promos
  for (const promo of DEFAULT_PROMOS) {
    allWrites.push(createUpdateWrite("promos", promo.code, promo));
  }
  console.log(` Prepared ${DEFAULT_PROMOS.length} promos.`);

  // Send in batches of 100
  const BATCH_SIZE = 100;
  for (let i = 0; i < allWrites.length; i += BATCH_SIZE) {
    const chunk = allWrites.slice(i, i + BATCH_SIZE);
    const chunkNum = Math.floor(i / BATCH_SIZE) + 1;
    const totalChunks = Math.ceil(allWrites.length / BATCH_SIZE);
    console.log(` Writing batch ${chunkNum}/${totalChunks} (${chunk.length} documents)...`);
    await sendBatch(chunk, token);
  }

  console.log("=========================================");
  console.log(" SUCCESS! Database seeded with:");
  console.log(`  - Categories: ${DEFAULT_CATEGORIES.length}`);
  console.log(`  - Products:   ${DEFAULT_PRODUCTS.length}`);
  console.log(`  - Promos:     ${DEFAULT_PROMOS.length}`);
  console.log("=========================================");
  process.exit(0);
}

run().catch((err) => {
  console.error(" Seed Error:", err);
  process.exit(1);
});
