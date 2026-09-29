import * as admin from "firebase-admin";
import {HttpsError} from "firebase-functions/v2/https";
import {
  CreateOrderRequest,
  OrderDocument,
  ProductData,
  PromoData,
  ValidatedOrderItem,
} from "./types";

const getDb = () => admin.firestore();

/**
 * Validates and executes order creation on the server.
 * Ensures client prices, totals, discounts, stock, and order status are NOT trusted.
 */
export async function processCreateOrder(
  userId: string,
  data: CreateOrderRequest
): Promise<{ success: boolean; orderId: string; order: OrderDocument }> {
  if (!userId) {
    throw new HttpsError("unauthenticated", "User must be authenticated.");
  }

  const {items, deliveryAddress, paymentMethod, deliverySpeed, promoCode} =
    data;

  if (!items || !Array.isArray(items) || items.length === 0) {
    throw new HttpsError(
      "invalid-argument",
      "Order must contain at least one item."
    );
  }

  if (items.length > 50) {
    throw new HttpsError("invalid-argument", "Order contains too many items.");
  }

  const sanitizedAddress = (deliveryAddress || "Home Address").trim();
  const sanitizedPayment = (paymentMethod || "Cash on Delivery").trim();
  const sanitizedSpeed = (deliverySpeed || "Standard").trim();

  const db = getDb();

  return await db.runTransaction(async (transaction) => {
    // 1. Fetch and validate each product from server database
    const productRefs = items.map((item) => {
      const prodId = item.productId || item.id;
      if (!prodId || typeof prodId !== "string") {
        throw new HttpsError(
          "invalid-argument",
          "Invalid product ID in order items."
        );
      }
      return {
        ref: db.collection("products").doc(prodId),
        id: prodId,
        quantity: Math.floor(Number(item.quantity) || 0),
      };
    });

    const productDocs = await Promise.all(
      productRefs.map((p) => transaction.get(p.ref))
    );

    const validatedItems: ValidatedOrderItem[] = [];
    let subtotal = 0;

    for (let i = 0; i < productRefs.length; i++) {
      const {id, quantity, ref} = productRefs[i];
      const doc = productDocs[i];

      if (quantity <= 0 || quantity > 99) {
        throw new HttpsError(
          "invalid-argument",
          `Invalid quantity (${quantity}) for product ID ${id}.`
        );
      }

      if (!doc.exists) {
        throw new HttpsError(
          "not-found",
          `Product ${id} is no longer available in the store.`
        );
      }

      const prodData = doc.data() as ProductData;

      if (prodData.active === false) {
        throw new HttpsError(
          "failed-precondition",
          `Product "${prodData.name || id}" is currently inactive.`
        );
      }

      // Validate stock if tracked
      if (typeof prodData.stock === "number") {
        if (prodData.stock < quantity) {
          throw new HttpsError(
            "failed-precondition",
            `Insufficient stock for "${prodData.name || id}". Only ${
              prodData.stock
            } remaining.`
          );
        }
        // Decrement stock
        transaction.update(ref, {
          stock: admin.firestore.FieldValue.increment(-quantity),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      const serverPrice = Number(prodData.price) || 0.0;
      if (serverPrice < 0) {
        throw new HttpsError(
          "internal",
          `Invalid server price for product ${id}.`
        );
      }

      const itemTotal = Math.round(serverPrice * quantity * 100) / 100;
      subtotal += itemTotal;

      validatedItems.push({
        id,
        name: prodData.name || "Grocery Item",
        price: serverPrice,
        quantity,
        image: prodData.image || "",
        unit: prodData.unit || "1 unit",
      });
    }

    subtotal = Math.round(subtotal * 100) / 100;

    // 2. Validate Promo Code & Calculate discount on server
    let discount = 0;
    let verifiedPromoCode: string | null = null;

    if (promoCode && typeof promoCode === "string" && promoCode.trim() !== "") {
      const cleanCode = promoCode.trim().toUpperCase();
      const promoDoc = await transaction.get(
        db.collection("promos").doc(cleanCode)
      );

      if (promoDoc.exists) {
        const promo = promoDoc.data() as PromoData;
        const minSpend = Number(promo.minSpend) || 0;

        if (subtotal < minSpend) {
          throw new HttpsError(
            "failed-precondition",
            `Promo code "${cleanCode}" requires a minimum spend of $${minSpend.toFixed(
              2
            )}.`
          );
        }

        if (promo.expiryDate) {
          const expiryTime = Date.parse(promo.expiryDate);
          if (!isNaN(expiryTime) && Date.now() > expiryTime) {
            throw new HttpsError(
              "failed-precondition",
              `Promo code "${cleanCode}" has expired.`
            );
          }
        }

        if (promo.discountPercent && promo.discountPercent > 0) {
          discount = (subtotal * promo.discountPercent) / 100;
        } else if (promo.discountAmount && promo.discountAmount > 0) {
          discount = Math.min(subtotal, promo.discountAmount);
        }

        discount = Math.round(discount * 100) / 100;
        verifiedPromoCode = cleanCode;
      } else {
        throw new HttpsError(
          "not-found",
          `Promo code "${cleanCode}" is invalid.`
        );
      }
    }

    // 3. Server Delivery Fee rule: Free if Pickup or subtotal >= $20, else $2.99
    let deliveryFee = 2.99;
    if (sanitizedSpeed.toLowerCase() === "pickup" || subtotal >= 20.0) {
      deliveryFee = 0.0;
    }

    // 4. Calculate Final Total (client total is completely ignored)
    const totalAmount = Math.max(
      0,
      Math.round((subtotal - discount + deliveryFee) * 100) / 100
    );

    // 5. Generate Order ID
    const randomSuffix = Math.random()
      .toString(36)
      .substring(2, 6)
      .toUpperCase();
    const orderId = `ORD-${Date.now().toString().slice(-6)}-${randomSuffix}`;

    const orderDocData: OrderDocument = {
      id: orderId,
      userId,
      date: "Today, Just now",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: "Processing", // ALWAYS forced to 'Processing'
      items: validatedItems,
      subtotal,
      discount,
      deliveryFee,
      totalAmount,
      deliveryAddress: sanitizedAddress,
      paymentMethod: sanitizedPayment,
      deliverySpeed: sanitizedSpeed,
      promoCode: verifiedPromoCode,
    };

    // 6. Write to root orders collection
    const rootOrderRef = db.collection("orders").doc(orderId);
    transaction.set(rootOrderRef, orderDocData);

    // 7. Write to user's orders subcollection
    const userOrderRef = db
      .collection("users")
      .doc(userId)
      .collection("orders")
      .doc(orderId);
    transaction.set(userOrderRef, orderDocData);

    // 8. Create confirmation notification
    const notifId = `notif_${Date.now()}`;
    const notifRef = db
      .collection("users")
      .doc(userId)
      .collection("notifications")
      .doc(notifId);
    transaction.set(notifRef, {
      id: notifId,
      title: "Order Placed Successfully! 🎉",
      message: `Your order #${orderId} for $${totalAmount.toFixed(
        2
      )} has been placed and is being prepared.`,
      time: "Just now",
      isRead: false,
      type: "order",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      orderId,
      order: orderDocData,
    };
  });
}

/**
 * Validates and cancels an order on the server.
 */
export async function processCancelOrder(
  callerUid: string,
  orderId: string,
  isAdmin: boolean
): Promise<{ success: boolean; message: string }> {
  if (!callerUid) {
    throw new HttpsError("unauthenticated", "User must be authenticated.");
  }

  if (!orderId || typeof orderId !== "string") {
    throw new HttpsError("invalid-argument", "Missing or invalid order ID.");
  }

  const db = getDb();
  const rootOrderRef = db.collection("orders").doc(orderId);

  return await db.runTransaction(async (transaction) => {
    const orderDoc = await transaction.get(rootOrderRef);

    if (!orderDoc.exists) {
      throw new HttpsError("not-found", `Order ${orderId} does not exist.`);
    }

    const orderData = orderDoc.data() as OrderDocument;

    // Check authorization: must be owner or admin
    if (orderData.userId !== callerUid && !isAdmin) {
      throw new HttpsError(
        "permission-denied",
        "You do not have permission to cancel this order."
      );
    }

    if (orderData.status !== "Processing") {
      throw new HttpsError(
        "failed-precondition",
        `Order cannot be cancelled because it is already "${orderData.status}".`
      );
    }

    // Restore stock if it was tracked
    if (orderData.items && Array.isArray(orderData.items)) {
      for (const item of orderData.items) {
        if (item.id && item.quantity > 0) {
          const prodRef = db.collection("products").doc(item.id);
          const prodDoc = await transaction.get(prodRef);
          if (prodDoc.exists) {
            const prodData = prodDoc.data() as ProductData;
            if (typeof prodData.stock === "number") {
              transaction.update(prodRef, {
                stock: admin.firestore.FieldValue.increment(item.quantity),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
              });
            }
          }
        }
      }
    }

    // Update root order status
    transaction.update(rootOrderRef, {
      status: "Cancelled",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Update user subcollection order status
    const userOrderRef = db
      .collection("users")
      .doc(orderData.userId)
      .collection("orders")
      .doc(orderId);
    transaction.set(
      userOrderRef,
      {
        status: "Cancelled",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true}
    );

    // Create cancellation notification
    const notifId = `notif_${Date.now()}`;
    const notifRef = db
      .collection("users")
      .doc(orderData.userId)
      .collection("notifications")
      .doc(notifId);
    transaction.set(notifRef, {
      id: notifId,
      title: "Order Cancelled 🚫",
      message: `Order #${orderId} has been successfully cancelled.`,
      time: "Just now",
      isRead: false,
      type: "order",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      message: `Order #${orderId} has been cancelled.`,
    };
  });
}
