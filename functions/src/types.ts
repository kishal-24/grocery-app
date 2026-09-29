export interface ProductData {
  id?: string;
  name: string;
  price: number;
  image?: string;
  unit?: string;
  category?: string;
  stock?: number;
  active?: boolean;
}

export interface PromoData {
  code: string;
  title?: string;
  description?: string;
  discountAmount?: number;
  discountPercent?: number;
  minSpend?: number;
  expiryDate?: string;
  active?: boolean;
}

export interface CreateOrderItemInput {
  productId?: string;
  id?: string;
  quantity: number;
}

export interface CreateOrderRequest {
  items: CreateOrderItemInput[];
  deliveryAddress: string;
  paymentMethod: string;
  deliverySpeed?: string;
  promoCode?: string;
}

export interface ValidatedOrderItem {
  id: string;
  name: string;
  price: number;
  quantity: number;
  image: string;
  unit: string;
}

export interface OrderDocument {
  id: string;
  userId: string;
  date: string;
  createdAt: FirebaseFirestore.FieldValue;
  status: "Processing" | "In Transit" | "Delivered" | "Cancelled";
  items: ValidatedOrderItem[];
  subtotal: number;
  discount: number;
  deliveryFee: number;
  totalAmount: number;
  deliveryAddress: string;
  paymentMethod: string;
  deliverySpeed: string;
  promoCode?: string | null;
}
