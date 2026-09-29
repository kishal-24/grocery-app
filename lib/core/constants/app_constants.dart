/// Application constants for payment, merchant details, and localized configuration.
class AppConstants {
  /// Store Currency Configuration
  static const String currencyCode = 'INR';
  static const String currencySymbol = '₹';

  /// Canara Bank Merchant UPI Configuration
  /// Update this to your official Canara UPI ID (e.g. yourbusiness@cnrb or mobilenumber@cnrb)
  static const String defaultCanaraUpiId = 'freshbasket@cnrb';
  static const String merchantName = 'FreshBasket';
  static const String merchantCategoryCode = '5411'; // Grocery Stores, Supermarkets
}
