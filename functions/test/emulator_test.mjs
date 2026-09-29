import assert from "node:assert/strict";
import admin from "firebase-admin";

const PROJECT_ID = "grocery-db70e";
const AUTH_EMULATOR_HOST = "127.0.0.1:9099";
const FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
const FUNCTIONS_EMULATOR_HOST = "127.0.0.1:5001";

process.env.FIREBASE_AUTH_EMULATOR_HOST = AUTH_EMULATOR_HOST;
process.env.FIRESTORE_EMULATOR_HOST = FIRESTORE_EMULATOR_HOST;

admin.initializeApp({ projectId: PROJECT_ID });
const db = admin.firestore();

const AUTH_URL = `http://${AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts`;
const FIRESTORE_REST = `http://${FIRESTORE_EMULATOR_HOST}/v1/projects/${PROJECT_ID}/databases/(default)/documents`;
const FUNCTIONS_URL = `http://${FUNCTIONS_EMULATOR_HOST}/${PROJECT_ID}/us-central1`;

// Helper to create user in Auth emulator and return ID token & UID
async function createAuthUser(email, password, displayName) {
  const res = await fetch(`${AUTH_URL}:signUp?key=fake-api-key`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      email,
      password,
      displayName,
      returnSecureToken: true,
    }),
  });
  const data = await res.json();
  if (data.error) {
    throw new Error(`Auth create error: ${JSON.stringify(data.error)}`);
  }
  return { uid: data.localId, token: data.idToken, email };
}

// Helper to sign in user in Auth emulator
async function signInUser(email, password) {
  const res = await fetch(`${AUTH_URL}:signInWithPassword?key=fake-api-key`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      email,
      password,
      returnSecureToken: true,
    }),
  });
  const data = await res.json();
  if (data.error) {
    throw new Error(`Auth signin error: ${JSON.stringify(data.error)}`);
  }
  return { uid: data.localId, token: data.idToken, email };
}

async function runTests() {
  console.log("=================================================");
  console.log("🧪 STARTING FIREBASE EMULATOR INTEGRATION TESTS");
  console.log("=================================================\n");

  let passed = 0;
  let failed = 0;

  async function test(name, fn) {
    try {
      process.stdout.write(`▶ ${name}... `);
      await fn();
      console.log("✅ PASSED");
      passed++;
    } catch (err) {
      console.log("❌ FAILED");
      console.error(err);
      failed++;
    }
  }

  // Seed sample products and promos using admin SDK
  await test("0. Seed initial products, categories, and promos in Firestore", async () => {
    await db.collection("products").doc("p_test_apple").set({
      name: "Organic Red Apple",
      price: 4.99,
      unit: "1kg",
      stock: 20,
      active: true,
      category: "Fruits",
    });

    await db.collection("products").doc("p_test_banana").set({
      name: "Fresh Banana",
      price: 2.50,
      unit: "1 bunch",
      stock: 5,
      active: true,
      category: "Fruits",
    });

    await db.collection("categories").doc("cat_test_fruits").set({
      name: "Fruits",
      image: "https://example.com/fruits.png",
    });

    await db.collection("promos").doc("SAVE20").set({
      code: "SAVE20",
      discountPercent: 20,
      discountAmount: 0,
      minSpend: 10.0,
      expiryDate: "2030-12-31T23:59:59.000Z",
      active: true,
    });
  });

  // 1. Authentication & Username Login Tests
  let customer1;
  let customer2;
  let adminUser;

  await test("1. Auth - Register Customer 1 and sync usernameLower & username_lowercase", async () => {
    customer1 = await createAuthUser("customer1@test.com", "Password123!", "AliceShopper");
    assert.ok(customer1.uid, "Customer 1 created");

    // Profile creation with both usernameLower and username_lowercase
    const username = "AliceShopper";
    const usernameLower = username.toLowerCase();

    await db.collection("users").doc(customer1.uid).set({
      email: customer1.email,
      name: username,
      username: username,
      usernameLower: usernameLower,
      username_lowercase: usernameLower,
      role: "customer",
    });

    // Verify /usernames mapping document
    await db.collection("usernames").doc(usernameLower).set({
      uid: customer1.uid,
      email: customer1.email,
      username: username,
      usernameLower: usernameLower,
    });

    const userDoc = await db.collection("users").doc(customer1.uid).get();
    assert.equal(userDoc.data().usernameLower, "aliceshopper");
    assert.equal(userDoc.data().username_lowercase, "aliceshopper");
    assert.equal(userDoc.data().usernameLower, userDoc.data().username_lowercase);
  });

  await test("2. Auth - Username resolution case-insensitivity ('aliceshopper' vs 'ALICESHOPPER')", async () => {
    // Resolve via Cloud Function resolveUsernameApi
    const resUpper = await fetch(`${FUNCTIONS_URL}/resolveUsernameApi?username=ALICESHOPPER`);
    assert.equal(resUpper.status, 200, "Should resolve uppercase username");
    const dataUpper = await resUpper.json();
    assert.equal(dataUpper.email, "customer1@test.com");

    const resMixed = await fetch(`${FUNCTIONS_URL}/resolveUsernameApi?username=AliceShopper`);
    assert.equal(resMixed.status, 200, "Should resolve mixed case username");
    const dataMixed = await resMixed.json();
    assert.equal(dataMixed.email, "customer1@test.com");
  });

  await test("3. Auth - Register Customer 2 and Admin User", async () => {
    customer2 = await createAuthUser("customer2@test.com", "Password123!", "BobBuyer");
    await db.collection("users").doc(customer2.uid).set({
      email: customer2.email,
      name: "BobBuyer",
      username: "BobBuyer",
      usernameLower: "bobbuyer",
      username_lowercase: "bobbuyer",
      role: "customer",
    });

    adminUser = await createAuthUser("admin@groceryapp.com", "AdminPass123!", "AppAdmin");
    await db.collection("users").doc(adminUser.uid).set({
      email: adminUser.email,
      name: "AppAdmin",
      role: "admin",
    });
    // Set custom claims for admin
    await admin.auth().setCustomUserClaims(adminUser.uid, { admin: true, role: "admin" });
    // Re-authenticate admin to get token with custom claims
    adminUser = await signInUser("admin@groceryapp.com", "AdminPass123!");
  });

  // 2. Security Rules Tests
  await test("4. Security Rules - Customer CANNOT modify products (price tampering directly in DB)", async () => {
    // Customer 1 tries to update product price to $0.01 via Firestore REST API
    const res = await fetch(`${FIRESTORE_REST}/products/p_test_apple?updateMask.fieldPaths=price`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${customer1.token}`,
      },
      body: JSON.stringify({
        fields: {
          price: { doubleValue: 0.01 },
        },
      }),
    });
    assert.equal(res.status, 403, "Direct product modification by customer MUST be rejected with 403");
  });

  await test("5. Security Rules - Customer CANNOT modify categories or promos", async () => {
    // Customer 1 tries to create category
    const catRes = await fetch(`${FIRESTORE_REST}/categories/cat_fake`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${customer1.token}`,
      },
      body: JSON.stringify({
        fields: { name: { stringValue: "Hacked Cat" } },
      }),
    });
    assert.equal(catRes.status, 403, "Direct category creation by customer MUST be rejected");

    // Customer 1 tries to modify promo
    const promoRes = await fetch(`${FIRESTORE_REST}/promos/SAVE20?updateMask.fieldPaths=discountPercent`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${customer1.token}`,
      },
      body: JSON.stringify({
        fields: { discountPercent: { integerValue: 100 } },
      }),
    });
    assert.equal(promoRes.status, 403, "Direct promo modification by customer MUST be rejected");
  });

  await test("6. Security Rules - Customer CANNOT escalate their own role to admin", async () => {
    // Customer 1 tries to update their own role from 'customer' to 'admin'
    const res = await fetch(`${FIRESTORE_REST}/users/${customer1.uid}?updateMask.fieldPaths=role`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${customer1.token}`,
      },
      body: JSON.stringify({
        fields: { role: { stringValue: "admin" } },
      }),
    });
    assert.equal(res.status, 403, "Privilege escalation attempt MUST be rejected with 403");
  });

  await test("7. Security Rules - Customer CANNOT read or write another user's profile or subcollections", async () => {
    // Customer 1 tries to read Customer 2's user doc
    const readRes = await fetch(`${FIRESTORE_REST}/users/${customer2.uid}`, {
      method: "GET",
      headers: {
        Authorization: `Bearer ${customer1.token}`,
      },
    });
    assert.equal(readRes.status, 403, "Reading another user's profile MUST be rejected with 403");

    // Customer 1 tries to write to Customer 2's cart
    const cartRes = await fetch(`${FIRESTORE_REST}/users/${customer2.uid}/cart/p_test_apple`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${customer1.token}`,
      },
      body: JSON.stringify({
        fields: { quantity: { integerValue: 1 } },
      }),
    });
    assert.equal(cartRes.status, 403, "Writing to another user's cart MUST be rejected with 403");
  });

  await test("8. Security Rules - Customer CAN manage their own cart", async () => {
    // Customer 1 writes to their own cart
    const addCartRes = await fetch(`${FIRESTORE_REST}/users/${customer1.uid}/cart/p_test_apple`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${customer1.token}`,
      },
      body: JSON.stringify({
        fields: {
          quantity: { integerValue: 3 },
          productName: { stringValue: "Organic Red Apple" },
        },
      }),
    });
    assert.equal(addCartRes.status, 200, "Adding to own cart MUST succeed");

    // Customer 1 reads their own cart
    const readCartRes = await fetch(`${FIRESTORE_REST}/users/${customer1.uid}/cart/p_test_apple`, {
      method: "GET",
      headers: {
        Authorization: `Bearer ${customer1.token}`,
      },
    });
    assert.equal(readCartRes.status, 200, "Reading own cart MUST succeed");
  });

  await test("9. Security Rules - Customer CANNOT create or update orders directly in Firestore", async () => {
    // Customer 1 tries to forge an order directly in root /orders collection
    const orderRes = await fetch(`${FIRESTORE_REST}/orders/forged_order_1`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${customer1.token}`,
      },
      body: JSON.stringify({
        fields: {
          totalAmount: { doubleValue: 0.00 },
          status: { stringValue: "Delivered" },
          userId: { stringValue: customer1.uid },
        },
      }),
    });
    assert.equal(orderRes.status, 403, "Direct client order creation MUST be forbidden by security rules");
  });

  // 3. Cloud Functions Secure Orders Tests
  await test("10. Cloud Functions - Secure Order Creation (Client forged price & total are ignored)", async () => {
    // Customer 1 attempts to order 2 apples (server price $4.99 * 2 = $9.98).
    // Client sends malicious price: $0.01 and total: $0.02.
    // Server must reject the client price and calculate server price ($4.99 * 2 = $9.98 + $2.99 delivery = $12.97).
    const createRes = await fetch(`${FUNCTIONS_URL}/createOrderApi`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${customer1.token}`,
      },
      body: JSON.stringify({
        items: [
          {
            productId: "p_test_apple",
            quantity: 2,
            price: 0.01, // MALICIOUS CLIENT PRICE
          },
        ],
        deliveryAddress: "123 Main St, New York, NY",
        paymentMethod: "Credit Card",
        deliverySpeed: "Standard",
        totalAmount: 0.02, // MALICIOUS CLIENT TOTAL
        status: "Delivered", // MALICIOUS STATUS
      }),
    });

    assert.equal(createRes.status, 200, "Order creation endpoint should succeed");
    const orderResult = await createRes.json();
    assert.equal(orderResult.success, true);
    assert.ok(orderResult.orderId, "Order ID generated");

    const order = orderResult.order;
    // Verified server prices:
    assert.equal(order.items[0].price, 4.99, "Price MUST be fetched from server DB ($4.99)");
    assert.equal(order.subtotal, 9.98, "Subtotal MUST be server calculated (4.99 * 2 = 9.98)");
    assert.equal(order.deliveryFee, 2.99, "Delivery fee for subtotal < $20 must be $2.99");
    assert.equal(order.totalAmount, 12.97, "Total must be 9.98 + 2.99 = 12.97");
    assert.equal(order.status, "Processing", "Status MUST be forced to 'Processing'");

    // Verify stock deduction in Firestore
    const prodDoc = await db.collection("products").doc("p_test_apple").get();
    assert.equal(prodDoc.data().stock, 18, "Stock must be decremented from 20 to 18");
  });

  await test("11. Cloud Functions - Secure Order with Promo Code Validation", async () => {
    // Order with promo SAVE20 (20% off with min spend $10).
    // Let's buy 3 apples ($4.99 * 3 = $14.97) -> meets min spend $10!
    // 20% discount = $2.99.
    // Subtotal = $14.97, discount = $2.99. Delivery fee = $2.99. Total = $14.97.
    const promoRes = await fetch(`${FUNCTIONS_URL}/createOrderApi`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${customer1.token}`,
      },
      body: JSON.stringify({
        items: [{ productId: "p_test_apple", quantity: 3 }],
        deliveryAddress: "123 Main St",
        paymentMethod: "Apple Pay",
        promoCode: "SAVE20",
      }),
    });

    assert.equal(promoRes.status, 200);
    const data = await promoRes.json();
    assert.equal(data.order.promoCode, "SAVE20");
    assert.equal(data.order.discount, 2.99, "Server calculated 20% discount of $14.97");
  });

  await test("12. Cloud Functions - Order rejects invalid promo code", async () => {
    const invalidPromoRes = await fetch(`${FUNCTIONS_URL}/createOrderApi`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${customer1.token}`,
      },
      body: JSON.stringify({
        items: [{ productId: "p_test_apple", quantity: 1 }],
        deliveryAddress: "123 Main St",
        paymentMethod: "Cash",
        promoCode: "FAKE_PROMO_999",
      }),
    });
    assert.equal(invalidPromoRes.status, 404, "Invalid promo code must be rejected");
  });

  await test("13. Cloud Functions - Order rejects quantity exceeding stock", async () => {
    // p_test_banana only has 5 in stock
    const outOfStockRes = await fetch(`${FUNCTIONS_URL}/createOrderApi`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${customer1.token}`,
      },
      body: JSON.stringify({
        items: [{ productId: "p_test_banana", quantity: 10 }],
        deliveryAddress: "123 Main St",
        paymentMethod: "Cash",
      }),
    });
    assert.equal(outOfStockRes.status, 400, "Order exceeding stock must be rejected with 400");
  });

  await test("14. Cloud Functions - Order cancellation restores stock and updates status", async () => {
    // 1. Create order for 2 bananas (stock decreases from 5 to 3)
    const createRes = await fetch(`${FUNCTIONS_URL}/createOrderApi`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${customer1.token}`,
      },
      body: JSON.stringify({
        items: [{ productId: "p_test_banana", quantity: 2 }],
        deliveryAddress: "123 Main St",
        paymentMethod: "Cash",
      }),
    });
    const orderData = await createRes.json();
    const orderId = orderData.orderId;

    let bananaDoc = await db.collection("products").doc("p_test_banana").get();
    assert.equal(bananaDoc.data().stock, 3, "Stock after purchase must be 3");

    // 2. Customer 1 cancels the order
    const cancelRes = await fetch(`${FUNCTIONS_URL}/cancelOrderApi`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${customer1.token}`,
      },
      body: JSON.stringify({ orderId }),
    });
    assert.equal(cancelRes.status, 200, "Cancel order must succeed");

    // 3. Verify stock restored back to 5
    bananaDoc = await db.collection("products").doc("p_test_banana").get();
    assert.equal(bananaDoc.data().stock, 5, "Stock must be restored to 5 upon cancellation");

    // 4. Verify order status in DB is Cancelled
    const orderDoc = await db.collection("orders").doc(orderId).get();
    assert.equal(orderDoc.data().status, "Cancelled");
  });

  console.log("\n=================================================");
  console.log(`🎉 TEST SUMMARY: ${passed} PASSED, ${failed} FAILED`);
  console.log("=================================================");

  if (failed > 0) {
    process.exit(1);
  } else {
    process.exit(0);
  }
}

runTests().catch((err) => {
  console.error("Fatal test runner error:", err);
  process.exit(1);
});
