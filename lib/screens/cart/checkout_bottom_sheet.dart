import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/cart/cart_bloc.dart';
import '../../bloc/cart/cart_event.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/account_storage_service.dart';
import '../account/delivery_address_screen.dart';
import '../account/orders_screen.dart';
import '../account/payment_methods_screen.dart';

class CheckoutBottomSheet extends StatefulWidget {
  final double subtotal;

  const CheckoutBottomSheet({
    super.key,
    required this.subtotal,
  });

  static Future<void> show(BuildContext context, double subtotal) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<CartBloc>(),
        child: CheckoutBottomSheet(subtotal: subtotal),
      ),
    );
  }

  @override
  State<CheckoutBottomSheet> createState() => _CheckoutBottomSheetState();
}

class _CheckoutBottomSheetState extends State<CheckoutBottomSheet> {
  List<AddressModel> _addresses = [];
  AddressModel? _selectedAddress;
  String _deliverySpeed = 'Standard'; // 'Standard', 'Express', 'Pickup'
  bool _deliveryChosen = false;
  bool _deliveryError = false;

  List<PaymentCardModel> _cards = [];
  String? _selectedPaymentMethod;
  IconData _selectedPaymentIcon = Icons.payment;
  bool _paymentChosen = false;
  bool _paymentError = false;

  PromoModel? _appliedPromo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final addresses = await AccountStorageService().getAddresses();
    final cards = await AccountStorageService().getCards();
    final savedPrefs = await AccountStorageService().getSavedCheckoutPreferences();

    AddressModel? selectedAddress;
    String deliverySpeed = (savedPrefs['deliverySpeed'] as String?) ?? 'Standard';
    bool deliveryChosen = false;

    // Check if previously saved address exists in address list
    final savedAddressId = savedPrefs['addressId'] as String?;
    if (savedAddressId != null && addresses.isNotEmpty) {
      final matches = addresses.where((a) => a.id == savedAddressId).toList();
      if (matches.isNotEmpty) {
        selectedAddress = matches.first;
        deliveryChosen = true;
      }
    }

    // If no matching saved address found, fall back to default or first address
    if (selectedAddress == null && addresses.isNotEmpty) {
      selectedAddress = addresses.firstWhere(
        (a) => a.isDefault,
        orElse: () => addresses.first,
      );
      deliveryChosen = true;
    } else if (deliverySpeed == 'Pickup') {
      deliveryChosen = true;
    }

    // Payment method
    String? selectedPaymentMethod = savedPrefs['paymentMethod'] as String?;
    bool paymentChosen = false;

    if (selectedPaymentMethod != null && selectedPaymentMethod.isNotEmpty) {
      paymentChosen = true;
    } else if (cards.isNotEmpty) {
      final defaultCard = cards.firstWhere((c) => c.isDefault, orElse: () => cards.first);
      final last4 = defaultCard.cardNumber.length >= 4
          ? defaultCard.cardNumber.substring(defaultCard.cardNumber.length - 4)
          : defaultCard.cardNumber;
      selectedPaymentMethod = '${defaultCard.cardType} ending in $last4';
      paymentChosen = true;
    } else {
      selectedPaymentMethod = 'Cash on Delivery';
      paymentChosen = true;
    }

    final selectedPaymentIcon = _getPaymentIcon(selectedPaymentMethod);

    if (mounted) {
      setState(() {
        _addresses = addresses;
        _cards = cards;
        _selectedAddress = selectedAddress;
        _deliverySpeed = deliverySpeed;
        _deliveryChosen = deliveryChosen;
        _selectedPaymentMethod = selectedPaymentMethod;
        _selectedPaymentIcon = selectedPaymentIcon;
        _paymentChosen = paymentChosen;
        _isLoading = false;
      });
    }
  }

  IconData _getPaymentIcon(String? method) {
    if (method == null) return Icons.payment;
    if (method == 'Apple Pay') return Icons.account_balance_wallet_outlined;
    if (method == 'Google Pay') return Icons.wallet;
    if (method == 'Cash on Delivery') return Icons.payments_outlined;
    return Icons.credit_card;
  }

  double get _deliveryFee {
    if (!_deliveryChosen) return 0.0;
    if (_deliverySpeed == 'Express') {
      if (_appliedPromo?.code == 'FREEDEL') {
        return 0.0;
      }
      return 3.99;
    }
    return 0.0;
  }

  double get _discountAmount {
    if (_appliedPromo == null) return 0.0;
    if (_appliedPromo!.discountPercent > 0) {
      return (widget.subtotal * (_appliedPromo!.discountPercent / 100))
          .clamp(0.0, widget.subtotal);
    }
    if (_appliedPromo!.discountAmount > 0) {
      return _appliedPromo!.discountAmount.clamp(0.0, widget.subtotal);
    }
    return 0.0;
  }

  double get _finalTotal {
    final total = widget.subtotal - _discountAmount + _deliveryFee;
    return total < 0 ? 0.0 : total;
  }

  String get _deliveryDisplayString {
    if (!_deliveryChosen) return 'Select Method';

    final speedLabel = _deliverySpeed == 'Express'
        ? 'Express (${_appliedPromo?.code == 'FREEDEL' ? 'Free' : '\$3.99'})'
        : _deliverySpeed == 'Pickup'
            ? 'Store Pickup'
            : 'Standard (Free)';

    if (_deliverySpeed == 'Pickup') {
      return 'Store Pickup (Nearest Store)';
    }

    if (_selectedAddress != null) {
      return '${_selectedAddress!.title} • $speedLabel';
    }
    return speedLabel;
  }

  // ==================== DELIVERY EDIT MODAL ====================
  void _editDelivery() {
    AddressModel? tempAddress = _selectedAddress ??
        (_addresses.isNotEmpty
            ? _addresses.firstWhere((a) => a.isDefault, orElse: () => _addresses.first)
            : null);
    String tempSpeed = _deliverySpeed;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Delivery Options',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Delivery Speed & Type',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSpeedOption(
                    title: 'Standard Delivery',
                    subtitle: 'Estimated 2-3 hours • Free',
                    value: 'Standard',
                    selectedValue: tempSpeed,
                    onSelected: (val) {
                      setModalState(() => tempSpeed = val);
                    },
                  ),
                  _buildSpeedOption(
                    title: 'Express Delivery',
                    subtitle: 'Estimated 30-45 mins • \$3.99',
                    value: 'Express',
                    selectedValue: tempSpeed,
                    onSelected: (val) {
                      setModalState(() => tempSpeed = val);
                    },
                  ),
                  _buildSpeedOption(
                    title: 'Store Pickup',
                    subtitle: 'Ready in 1 hour at Nearest Store • Free',
                    value: 'Pickup',
                    selectedValue: tempSpeed,
                    onSelected: (val) {
                      setModalState(() => tempSpeed = val);
                    },
                  ),
                  if (tempSpeed != 'Pickup') ...[
                    const Divider(color: AppColors.divider, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Delivery Address',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                _showAddNewAddressDialog(
                                  context: ctx,
                                  onAddressSaved: (newAddr) {
                                    setModalState(() {
                                      _addresses.insert(0, newAddr);
                                      tempAddress = newAddr;
                                    });
                                    setState(() {
                                      _selectedAddress = newAddr;
                                      _deliveryChosen = true;
                                      _deliveryError = false;
                                    });
                                    AccountStorageService().saveCheckoutPreferences(
                                      addressId: newAddr.id,
                                      deliverySpeed: tempSpeed,
                                    );
                                  },
                                );
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text(
                                'Add New',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const DeliveryAddressScreen(),
                                  ),
                                );
                                final addrs =
                                    await AccountStorageService().getAddresses();
                                setState(() {
                                  _addresses = addrs;
                                  if (addrs.isNotEmpty) {
                                    _selectedAddress = addrs.firstWhere(
                                      (a) => a.isDefault,
                                      orElse: () => addrs.first,
                                    );
                                    _deliveryChosen = true;
                                    _deliveryError = false;
                                  }
                                });
                                if (_selectedAddress != null) {
                                  AccountStorageService().saveCheckoutPreferences(
                                    addressId: _selectedAddress!.id,
                                    deliverySpeed: _deliverySpeed,
                                  );
                                }
                              },
                              child: const Text(
                                'Manage',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textGrey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_addresses.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _showAddNewAddressDialog(
                              context: ctx,
                              onAddressSaved: (newAddr) {
                                setModalState(() {
                                  _addresses.insert(0, newAddr);
                                  tempAddress = newAddr;
                                });
                                setState(() {
                                  _selectedAddress = newAddr;
                                  _deliveryChosen = true;
                                  _deliveryError = false;
                                });
                                AccountStorageService().saveCheckoutPreferences(
                                  addressId: newAddr.id,
                                  deliverySpeed: tempSpeed,
                                );
                              },
                            );
                          },
                          icon: const Icon(Icons.add_location_alt_outlined,
                              color: AppColors.primaryGreen),
                          label: const Text(
                            'Add New Delivery Address',
                            style: TextStyle(color: AppColors.primaryGreen),
                          ),
                        ),
                      )
                    else
                      ..._addresses.map(
                        (addr) => InkWell(
                          onTap: () {
                            setModalState(() => tempAddress = addr);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: tempAddress?.id == addr.id
                                  ? AppColors.primaryGreenLight.withValues(alpha: 0.3)
                                  : AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: tempAddress?.id == addr.id
                                    ? AppColors.primaryGreen
                                    : AppColors.border,
                                width: tempAddress?.id == addr.id ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  addr.title.toLowerCase().contains('work')
                                      ? Icons.business
                                      : Icons.home,
                                  color: tempAddress?.id == addr.id
                                      ? AppColors.primaryGreen
                                      : AppColors.textGrey,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            addr.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                          if (addr.isDefault) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color:
                                                    AppColors.primaryGreenLight,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'DEFAULT',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      AppColors.primaryGreen,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        addr.fullAddress,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textGrey,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  tempAddress?.id == addr.id
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: tempAddress?.id == addr.id
                                      ? AppColors.primaryGreen
                                      : AppColors.textGrey,
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (tempSpeed != 'Pickup' && tempAddress == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select or add a delivery address'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }
                        setState(() {
                          _selectedAddress = tempAddress;
                          _deliverySpeed = tempSpeed;
                          _deliveryChosen = true;
                          _deliveryError = false;
                        });
                        AccountStorageService().saveCheckoutPreferences(
                          addressId: tempAddress?.id,
                          deliverySpeed: tempSpeed,
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✓ Delivery details saved!'),
                            backgroundColor: AppColors.primaryGreen,
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Apply Delivery Option',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSpeedOption({
    required String title,
    required String subtitle,
    required String value,
    required String selectedValue,
    required ValueChanged<String> onSelected,
  }) {
    final isSelected = value == selectedValue;
    return InkWell(
      onTap: () => onSelected(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGreenLight.withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              value == 'Express'
                  ? Icons.electric_bolt
                  : value == 'Pickup'
                      ? Icons.storefront
                      : Icons.local_shipping_outlined,
              size: 20,
              color: isSelected ? AppColors.primaryGreen : AppColors.textGrey,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primaryGreen : AppColors.textGrey,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== PAYMENT EDIT MODAL ====================
  void _editPayment() {
    String? tempPayment = _selectedPaymentMethod ??
        (_cards.isNotEmpty
            ? '${_cards.first.cardType} ending in ${_cards.first.cardNumber.substring(_cards.first.cardNumber.length >= 4 ? _cards.first.cardNumber.length - 4 : 0)}'
            : 'Cash on Delivery');
    IconData tempIcon = _selectedPaymentIcon;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Payment Method',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Saved Cards',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              _showAddNewCardDialog(
                                context: ctx,
                                onCardAdded: (newCard) {
                                  final last4 = newCard.cardNumber.length >= 4
                                      ? newCard.cardNumber.substring(newCard.cardNumber.length - 4)
                                      : newCard.cardNumber;
                                  final cardName = '${newCard.cardType} ending in $last4';
                                  setModalState(() {
                                    _cards.insert(0, newCard);
                                    tempPayment = cardName;
                                    tempIcon = Icons.credit_card;
                                  });
                                  setState(() {
                                    _selectedPaymentMethod = cardName;
                                    _selectedPaymentIcon = Icons.credit_card;
                                    _paymentChosen = true;
                                    _paymentError = false;
                                  });
                                  AccountStorageService().saveCheckoutPreferences(
                                    paymentMethod: cardName,
                                    paymentIconCode: Icons.credit_card.codePoint,
                                  );
                                },
                              );
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text(
                              'Add Card',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PaymentMethodsScreen(),
                                ),
                              );
                              final cards =
                                  await AccountStorageService().getCards();
                              setState(() {
                                _cards = cards;
                                if (cards.isNotEmpty) {
                                  final def = cards.firstWhere((c) => c.isDefault, orElse: () => cards.first);
                                  final last4 = def.cardNumber.length >= 4
                                      ? def.cardNumber.substring(def.cardNumber.length - 4)
                                      : def.cardNumber;
                                  _selectedPaymentMethod = '${def.cardType} ending in $last4';
                                  _selectedPaymentIcon = Icons.credit_card;
                                  _paymentChosen = true;
                                  _paymentError = false;
                                  AccountStorageService().saveCheckoutPreferences(
                                    paymentMethod: _selectedPaymentMethod,
                                    paymentIconCode: Icons.credit_card.codePoint,
                                  );
                                }
                              });
                            },
                            child: const Text(
                              'Manage',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_cards.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showAddNewCardDialog(
                            context: ctx,
                            onCardAdded: (newCard) {
                              final last4 = newCard.cardNumber.length >= 4
                                  ? newCard.cardNumber.substring(newCard.cardNumber.length - 4)
                                  : newCard.cardNumber;
                              final cardName = '${newCard.cardType} ending in $last4';
                              setModalState(() {
                                _cards.insert(0, newCard);
                                tempPayment = cardName;
                                tempIcon = Icons.credit_card;
                              });
                              setState(() {
                                _selectedPaymentMethod = cardName;
                                _selectedPaymentIcon = Icons.credit_card;
                                _paymentChosen = true;
                                _paymentError = false;
                              });
                              AccountStorageService().saveCheckoutPreferences(
                                paymentMethod: cardName,
                                paymentIconCode: Icons.credit_card.codePoint,
                              );
                            },
                          );
                        },
                        icon: const Icon(Icons.add_card, color: AppColors.primaryGreen, size: 18),
                        label: const Text('Add New Card', style: TextStyle(color: AppColors.primaryGreen)),
                      ),
                    ),
                  ..._cards.map((card) {
                    final last4 = card.cardNumber.length >= 4
                        ? card.cardNumber.substring(card.cardNumber.length - 4)
                        : card.cardNumber;
                    final cardName = '${card.cardType} ending in $last4';
                    final isSelected = tempPayment == cardName;

                    return _buildPaymentTile(
                      icon: Icons.credit_card,
                      title: cardName,
                      subtitle: 'Expires ${card.expiry} • ${card.cardHolder}',
                      isSelected: isSelected,
                      onTap: () {
                        setModalState(() {
                          tempPayment = cardName;
                          tempIcon = Icons.credit_card;
                        });
                      },
                    );
                  }),
                  const Divider(color: AppColors.divider, height: 20),
                  const Text(
                    'Digital Wallets & Cash',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPaymentTile(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Apple Pay',
                    subtitle: 'Fast, secure contactless checkout',
                    isSelected: tempPayment == 'Apple Pay',
                    onTap: () {
                      setModalState(() {
                        tempPayment = 'Apple Pay';
                        tempIcon = Icons.account_balance_wallet_outlined;
                      });
                    },
                  ),
                  _buildPaymentTile(
                    icon: Icons.wallet,
                    title: 'Google Pay',
                    subtitle: 'Pay instantly with linked accounts',
                    isSelected: tempPayment == 'Google Pay',
                    onTap: () {
                      setModalState(() {
                        tempPayment = 'Google Pay';
                        tempIcon = Icons.wallet;
                      });
                    },
                  ),
                  _buildPaymentTile(
                    icon: Icons.payments_outlined,
                    title: 'Cash on Delivery',
                    subtitle: 'Pay in cash when your delivery arrives',
                    isSelected: tempPayment == 'Cash on Delivery',
                    onTap: () {
                      setModalState(() {
                        tempPayment = 'Cash on Delivery';
                        tempIcon = Icons.payments_outlined;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (tempPayment == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a payment option'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }
                        setState(() {
                          _selectedPaymentMethod = tempPayment;
                          _selectedPaymentIcon = tempIcon;
                          _paymentChosen = true;
                          _paymentError = false;
                        });
                        AccountStorageService().saveCheckoutPreferences(
                          paymentMethod: tempPayment,
                          paymentIconCode: tempIcon.codePoint,
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✓ Payment method saved!'),
                            backgroundColor: AppColors.primaryGreen,
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Apply Payment Method',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGreenLight.withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? AppColors.primaryGreen : AppColors.textGrey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primaryGreen : AppColors.textGrey,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== PROMO CODE EDIT MODAL ====================
  void _editPromoCode() {
    final promoController =
        TextEditingController(text: _appliedPromo?.code ?? '');
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final promos = AccountStorageService().getPromos();

            void tryApply(PromoModel promo) {
              if (widget.subtotal < promo.minSpend) {
                setModalState(() {
                  errorMessage =
                      'Requires minimum spend of \$${promo.minSpend.toStringAsFixed(2)} (Current: \$${widget.subtotal.toStringAsFixed(2)})';
                });
                return;
              }
              setState(() => _appliedPromo = promo);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🎉 Coupon "${promo.code}" applied!'),
                  backgroundColor: AppColors.primaryGreen,
                  duration: const Duration(seconds: 2),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Promo Coupons',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: promoController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              hintText: 'Enter coupon code',
                              hintStyle: const TextStyle(
                                  fontSize: 13, color: AppColors.textGrey),
                              filled: true,
                              fillColor: AppColors.cardBackground,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppColors.primaryGreen),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final input =
                                promoController.text.trim().toUpperCase();
                            if (input.isEmpty) return;
                            final found = promos.firstWhere(
                              (p) => p.code.toUpperCase() == input,
                              orElse: () => PromoModel(
                                code: '',
                                title: '',
                                description: '',
                                minSpend: 0,
                                expiryDate: '',
                              ),
                            );
                            if (found.code.isEmpty) {
                              setModalState(() {
                                errorMessage =
                                    'Invalid promo code. Please try another.';
                              });
                            } else {
                              tryApply(found);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Apply',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (_appliedPromo != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreenLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Active: ${_appliedPromo!.code} (${_appliedPromo!.title})',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() => _appliedPromo = null);
                                Navigator.pop(ctx);
                              },
                              child: const Icon(
                                Icons.cancel,
                                size: 18,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Divider(color: AppColors.divider, height: 24),
                    const Text(
                      'Available Coupons',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...promos.map((p) {
                      final isCurrent = _appliedPromo?.code == p.code;
                      final isEligible = widget.subtotal >= p.minSpend;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppColors.primaryGreenLight.withValues(alpha: 0.3)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrent
                                ? AppColors.primaryGreen
                                : AppColors.border,
                            width: isCurrent ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreenLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                p.code,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.title,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  Text(
                                    'Min. spend: \$${p.minSpend.toStringAsFixed(0)} • Exp: ${p.expiryDate}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isEligible
                                          ? AppColors.textGrey
                                          : Colors.orange.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: isCurrent
                                  ? () {
                                      setState(() => _appliedPromo = null);
                                      Navigator.pop(ctx);
                                    }
                                  : () => tryApply(p),
                              child: Text(
                                isCurrent
                                    ? 'Remove'
                                    : (isEligible
                                        ? 'Apply'
                                        : 'Min \$${p.minSpend.toInt()}'),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isCurrent
                                      ? Colors.redAccent
                                      : (isEligible
                                          ? AppColors.primaryGreen
                                          : AppColors.textGrey),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==================== PLACE ORDER ====================
  void _onPlaceOrder() {
    bool hasError = false;

    if (!_deliveryChosen) {
      setState(() => _deliveryError = true);
      hasError = true;
    }
    if (!_paymentChosen) {
      setState(() => _paymentError = true);
      hasError = true;
    }

    if (hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Please select both Delivery and Payment options to place your order.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent.shade700,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // Automatically open the first unselected option to guide the user seamlessly
      if (!_deliveryChosen) {
        _editDelivery();
      } else if (!_paymentChosen) {
        _editPayment();
      }
      return;
    }

    final cartState = context.read<CartBloc>().state;
    final orderItems = cartState.items
        .map((item) => OrderItemModel(
              id: item.product.id,
              name: item.product.name,
              price: item.product.price,
              quantity: item.quantity,
              image: item.product.image,
              unit: item.product.unit,
            ))
        .toList();

    final addressStr = _deliverySpeed == 'Pickup'
        ? 'Store Pickup (Nearest Branch)'
        : (_selectedAddress != null
            ? '${_selectedAddress!.title}: ${_selectedAddress!.fullAddress}'
            : 'Delivery Address');

    final newOrder = OrderModel(
      id: 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      date: 'Today, Just now',
      status: 'Processing',
      items: orderItems,
      totalAmount: _finalTotal,
      deliveryAddress: addressStr,
      paymentMethod: _selectedPaymentMethod ?? 'Cash on Delivery',
    );

    AccountStorageService().addOrder(newOrder);
    AccountStorageService().saveCheckoutPreferences(
      addressId: _selectedAddress?.id,
      deliverySpeed: _deliverySpeed,
      paymentMethod: _selectedPaymentMethod,
      paymentIconCode: _selectedPaymentIcon.codePoint,
    );

    Navigator.pop(context); // Close checkout bottom sheet
    _showOrderAcceptedDialog(context);
  }

  void _showOrderAcceptedDialog(BuildContext context) {
    context.read<CartBloc>().add(const ClearCartEvent());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryGreenLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primaryGreen,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Your Order has been\naccepted',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your items have been placed and is on it’s way to being processed',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const OrdersScreen(initialFilter: 'Active'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Track Order',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Back to home',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== MAIN BUILD ====================
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
      );
    }

    final bool isReady = _deliveryChosen && _paymentChosen;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Checkout',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(color: AppColors.divider),

          // 1. Delivery Row
          _buildInteractiveCheckoutRow(
            label: 'Delivery',
            value: _deliveryDisplayString,
            leadingIcon: Icons.local_shipping_outlined,
            isChosen: _deliveryChosen,
            hasError: _deliveryError,
            onTap: _editDelivery,
          ),
          const Divider(color: AppColors.divider),

          // 2. Payment Row
          _buildInteractiveCheckoutRow(
            label: 'Payment',
            value: _paymentChosen
                ? (_selectedPaymentMethod ?? 'Select Method')
                : 'Select Method',
            leadingIcon: _selectedPaymentIcon,
            isChosen: _paymentChosen,
            hasError: _paymentError,
            onTap: _editPayment,
          ),
          const Divider(color: AppColors.divider),

          // 3. Promo Code Row (Optional)
          _buildInteractiveCheckoutRow(
            label: 'Promo Code',
            value: _appliedPromo != null
                ? '${_appliedPromo!.code} (-${_discountAmount > 0 ? '\$${_discountAmount.toStringAsFixed(2)}' : 'applied'})'
                : 'Pick discount',
            valueColor: _appliedPromo != null
                ? AppColors.primaryGreen
                : AppColors.textGrey,
            leadingIcon: Icons.local_offer_outlined,
            isChosen: _appliedPromo != null,
            hasError: false,
            onTap: _editPromoCode,
          ),
          const Divider(color: AppColors.divider),

          // 4. Cost Breakdown (if promo or express delivery active)
          if (_appliedPromo != null || (_deliveryChosen && _deliverySpeed == 'Express')) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subtotal',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textGrey),
                      ),
                      Text(
                        '\$${widget.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Delivery Fee',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textGrey),
                      ),
                      Text(
                        _deliveryFee == 0.0
                            ? 'FREE'
                            : '\$${_deliveryFee.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _deliveryFee == 0.0
                              ? AppColors.primaryGreen
                              : AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  if (_discountAmount > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Discount (${_appliedPromo!.code})',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.primaryGreen),
                        ),
                        Text(
                          '-\$${_discountAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Divider(color: AppColors.divider),
          ],

          // Total Cost Row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Cost',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '\$${_finalTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),

          // Missing options warning notice
          if (!isReady && (_deliveryError || _paymentError)) ...[
            Container(
              margin: const EdgeInsets.only(top: 4, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, size: 16, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please choose delivery and payment method before placing order.',
                      style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),
          const Text(
            'By placing an order you agree to our Terms And Conditions',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 16),

          // Place Order Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _onPlaceOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: isReady ? AppColors.primaryGreen : AppColors.primaryGreen.withValues(alpha: 0.85),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isReady ? 'Place Order' : 'Choose Options to Order',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(\$${_finalTotal.toStringAsFixed(2)})',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.normal,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.check_circle_outline, size: 14, color: AppColors.primaryGreen),
              SizedBox(width: 6),
              Text(
                'Checkout details are automatically saved for your next order',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildInteractiveCheckoutRow({
    required String label,
    required String value,
    required IconData leadingIcon,
    required bool isChosen,
    required bool hasError,
    required VoidCallback onTap,
    Color? valueColor,
  }) {
    Color displayValueColor;
    if (hasError && !isChosen) {
      displayValueColor = Colors.redAccent;
    } else if (valueColor != null) {
      displayValueColor = valueColor;
    } else if (isChosen) {
      displayValueColor = AppColors.textDark;
    } else {
      displayValueColor = AppColors.textGrey;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: hasError && !isChosen ? Colors.red.withValues(alpha: 0.05) : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  leadingIcon,
                  size: 18,
                  color: hasError && !isChosen ? Colors.redAccent : AppColors.textGrey,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    color: hasError && !isChosen ? Colors.redAccent : AppColors.textGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hasError && !isChosen) ...[
                  const SizedBox(width: 6),
                  const Text(
                    '*Required',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isChosen ? FontWeight.w600 : FontWeight.normal,
                        color: displayValueColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: hasError && !isChosen ? Colors.redAccent : AppColors.textGrey,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddNewAddressDialog({
    required BuildContext context,
    required ValueChanged<AddressModel> onAddressSaved,
  }) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: 'Home');
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final streetController = TextEditingController();
    final cityController = TextEditingController();
    final stateController = TextEditingController();
    final zipController = TextEditingController();
    bool isDefault = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
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
                              'Add New Address',
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
                        const SizedBox(height: 12),
                        const Text(
                          'Address Label',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: ['Home', 'Work', 'Other'].map((type) {
                            final isSel = titleController.text == type;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(type),
                                selected: isSel,
                                selectedColor: AppColors.primaryGreenLight,
                                labelStyle: TextStyle(
                                  color: isSel ? AppColors.primaryGreen : AppColors.textDark,
                                  fontWeight: FontWeight.bold,
                                ),
                                onSelected: (sel) {
                                  if (sel) {
                                    setModalState(() {
                                      titleController.text = type;
                                    });
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        _buildModalInputField(
                          label: 'Full Name',
                          controller: nameController,
                          hint: 'e.g. Alex Johnson',
                          validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        _buildModalInputField(
                          label: 'Phone Number',
                          controller: phoneController,
                          hint: '+1 234 567 8900',
                          keyboardType: TextInputType.phone,
                          validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        _buildModalInputField(
                          label: 'Street Address',
                          controller: streetController,
                          hint: 'Apartment, suite, street name',
                          validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildModalInputField(
                                label: 'City',
                                controller: cityController,
                                hint: 'City',
                                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: _buildModalInputField(
                                label: 'State',
                                controller: stateController,
                                hint: 'State',
                                validator: (val) => val == null || val.trim().isEmpty ? 'Req' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: _buildModalInputField(
                                label: 'ZIP',
                                controller: zipController,
                                hint: 'ZIP',
                                keyboardType: TextInputType.number,
                                validator: (val) => val == null || val.trim().isEmpty ? 'Req' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Set as default address',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          activeThumbColor: AppColors.primaryGreen,
                          value: isDefault,
                          onChanged: (val) => setModalState(() => isDefault = val),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              final newAddr = AddressModel(
                                id: 'addr_${DateTime.now().millisecondsSinceEpoch}',
                                title: titleController.text.trim(),
                                recipientName: nameController.text.trim(),
                                phone: phoneController.text.trim(),
                                street: streetController.text.trim(),
                                city: cityController.text.trim(),
                                state: stateController.text.trim(),
                                zipCode: zipController.text.trim(),
                                isDefault: isDefault,
                              );
                              await AccountStorageService().addAddress(newAddr);
                              if (context.mounted) {
                                Navigator.pop(bottomCtx);
                                onAddressSaved(newAddr);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✓ New address saved & selected for checkout!'),
                                    backgroundColor: AppColors.primaryGreen,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Save & Use Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
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

  void _showAddNewCardDialog({
    required BuildContext context,
    required ValueChanged<PaymentCardModel> onCardAdded,
  }) {
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
                        _buildModalInputField(
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
                        _buildModalInputField(
                          label: 'Cardholder Name',
                          controller: holderController,
                          hint: 'e.g. ALEX JOHNSON',
                          validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildModalInputField(
                                label: 'Expiry (MM/YY)',
                                controller: expiryController,
                                hint: '12/28',
                                keyboardType: TextInputType.datetime,
                                validator: (val) {
                                  if (val == null || !val.contains('/')) {
                                    return 'MM/YY';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildModalInputField(
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
                        const SizedBox(height: 16),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Set as default payment method',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          activeThumbColor: AppColors.primaryGreen,
                          value: isDefault,
                          onChanged: (val) => setModalState(() => isDefault = val),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              final newCard = PaymentCardModel(
                                id: 'card_${DateTime.now().millisecondsSinceEpoch}',
                                cardNumber: numberController.text.trim(),
                                cardHolder: holderController.text.trim().toUpperCase(),
                                expiry: expiryController.text.trim(),
                                cardType: cardType,
                                isDefault: isDefault,
                              );
                              await AccountStorageService().addCard(newCard);
                              if (context.mounted) {
                                Navigator.pop(bottomCtx);
                                onCardAdded(newCard);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✓ New card saved & selected for checkout!'),
                                    backgroundColor: AppColors.primaryGreen,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Save & Use Card', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
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

  Widget _buildModalInputField({
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
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
            filled: true,
            fillColor: AppColors.cardBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5)),
          ),
        ),
      ],
    );
  }
}

