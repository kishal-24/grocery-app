import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/account_storage_service.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  List<PaymentCardModel> _cards = [];
  bool _isLoading = true;
  String _selectedWallet = 'Google Pay';

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final list = await AccountStorageService().getCards();
    if (mounted) {
      setState(() {
        _cards = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _setDefaultCard(String id) async {
    await AccountStorageService().setDefaultCard(id);
    await _loadCards();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Default payment method updated'),
          backgroundColor: AppColors.primaryGreen,
          duration: Duration(milliseconds: 900),
        ),
      );
    }
  }

  Future<void> _deleteCard(PaymentCardModel card) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Card?'),
        content: Text('Are you sure you want to delete ${card.cardType} ending in ${card.cardNumber.substring(card.cardNumber.length - 4)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AccountStorageService().deleteCard(card.id);
      await _loadCards();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Card removed successfully'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showAddCardDialog() {
    final formKey = GlobalKey<FormState>();
    final numberController = TextEditingController();
    final holderController = TextEditingController();
    final expiryController = TextEditingController();
    final cvvController = TextEditingController();
    String cardType = 'Mastercard';
    bool isDefault = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Add New Card',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: AppColors.textGrey),
                              onPressed: () => Navigator.pop(bottomCtx),
                            ),
                          ],
                        ),
                        const Divider(color: AppColors.divider),
                        const SizedBox(height: 14),

                        // Card Brand
                        const Text(
                          'Card Brand',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: ['Visa', 'Mastercard', 'Amex'].map((brand) {
                            final isSel = cardType == brand;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(brand),
                                selected: isSel,
                                selectedColor: AppColors.primaryGreenLight,
                                labelStyle: TextStyle(
                                  color: isSel ? AppColors.primaryGreen : AppColors.textDark,
                                  fontWeight: FontWeight.bold,
                                ),
                                onSelected: (sel) {
                                  if (sel) {
                                    setModalState(() => cardType = brand);
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 14),

                        // Card Number
                        _buildInputField(
                          label: 'Card Number',
                          controller: numberController,
                          hint: '4242 4242 4242 4242',
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            if (val == null || val.replaceAll(' ', '').length < 16) {
                              return 'Enter a valid 16-digit card number';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        // Cardholder Name
                        _buildInputField(
                          label: 'Cardholder Name',
                          controller: holderController,
                          hint: 'e.g. ALEX JOHNSON',
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),

                        const SizedBox(height: 14),

                        // Expiry & CVV
                        Row(
                          children: [
                            Expanded(
                              child: _buildInputField(
                                label: 'Expiry Date',
                                controller: expiryController,
                                hint: 'MM/YY',
                                keyboardType: TextInputType.datetime,
                                validator: (val) {
                                  if (val == null || !val.contains('/')) {
                                    return 'MM/YY';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _buildInputField(
                                label: 'CVV',
                                controller: cvvController,
                                hint: '123',
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                validator: (val) {
                                  if (val == null || val.length < 3) {
                                    return '3 digits';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Default Switch
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Set as default payment method',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          activeThumbColor: AppColors.primaryGreen,
                          value: isDefault,
                          onChanged: (val) {
                            setModalState(() => isDefault = val);
                          },
                        ),

                        const SizedBox(height: 20),

                        // Add Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;

                              final card = PaymentCardModel(
                                id: 'card_${DateTime.now().millisecondsSinceEpoch}',
                                cardNumber: numberController.text.trim(),
                                cardHolder: holderController.text.trim().toUpperCase(),
                                expiry: expiryController.text.trim(),
                                cardType: cardType,
                                isDefault: isDefault,
                              );

                              await AccountStorageService().addCard(card);
                              if (bottomCtx.mounted) {
                                Navigator.pop(bottomCtx);
                              }
                              await _loadCards();

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Payment card added successfully!'),
                                    backgroundColor: AppColors.primaryGreen,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Save Card', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textGrey),
            filled: true,
            fillColor: AppColors.cardBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryGreen),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payment Methods',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Saved Cards',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Cards List
                  ..._cards.map((card) => _buildCreditCardItem(card)),

                  const SizedBox(height: 12),

                  // Add Card Button
                  OutlinedButton.icon(
                    onPressed: _showAddCardDialog,
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryGreen),
                    label: const Text(
                      'Add New Card',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Other Payment Options
                  const Text(
                    'Digital Wallets & More',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 14),

                  _buildWalletTile(
                    title: 'Google Pay',
                    subtitle: 'Fast, secure checkout with your Google Account',
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: const Color(0xFF4285F4),
                    isSelected: _selectedWallet == 'Google Pay',
                    onTap: () => setState(() => _selectedWallet = 'Google Pay'),
                  ),
                  const SizedBox(height: 10),

                  _buildWalletTile(
                    title: 'Apple Pay',
                    subtitle: 'Seamless payment on iOS devices',
                    icon: Icons.phone_iphone,
                    iconColor: Colors.black87,
                    isSelected: _selectedWallet == 'Apple Pay',
                    onTap: () => setState(() => _selectedWallet = 'Apple Pay'),
                  ),
                  const SizedBox(height: 10),

                  _buildWalletTile(
                    title: 'Cash on Delivery (COD)',
                    subtitle: 'Pay with cash upon package arrival',
                    icon: Icons.payments_outlined,
                    iconColor: AppColors.primaryGreen,
                    isSelected: _selectedWallet == 'COD',
                    onTap: () => setState(() => _selectedWallet = 'COD'),
                  ),
                  const SizedBox(height: 10),

                  _buildWalletTile(
                    title: 'PayPal',
                    subtitle: 'Connected as user@freshbasket.com',
                    icon: Icons.payment,
                    iconColor: const Color(0xFF003087),
                    isSelected: _selectedWallet == 'PayPal',
                    onTap: () => setState(() => _selectedWallet = 'PayPal'),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildCreditCardItem(PaymentCardModel card) {
    final isMaster = card.cardType.toLowerCase().contains('master');
    final gradient = isMaster
        ? const LinearGradient(
            colors: [Color(0xFF232526), Color(0xFF414345)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.credit_card, color: Colors.white70, size: 26),
                        const SizedBox(width: 8),
                        Text(
                          card.cardType.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    if (card.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'DEFAULT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  card.maskedNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CARD HOLDER',
                          style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          card.cardHolder,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EXPIRES',
                          style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          card.expiry,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (!card.isDefault)
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline, color: Colors.white70, size: 20),
                            tooltip: 'Set as Default',
                            onPressed: () => _setDefaultCard(card.id),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.white70, size: 20),
                          tooltip: 'Remove Card',
                          onPressed: () => _deleteCard(card),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primaryGreen : AppColors.border,
          width: isSelected ? 1.8 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
        ),
        trailing: Icon(
          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: isSelected ? AppColors.primaryGreen : AppColors.textGrey,
        ),
      ),
    );
  }
}
