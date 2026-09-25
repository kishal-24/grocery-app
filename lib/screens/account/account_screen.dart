import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/account_storage_service.dart';
import '../login/mobile_login_screen.dart';
import 'about_screen.dart';
import 'delivery_address_screen.dart';
import 'help_screen.dart';
import 'my_details_screen.dart';
import 'notifications_screen.dart';
import 'orders_screen.dart';
import 'payment_methods_screen.dart';
import 'promo_card_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String _displayName = 'User';
  String _userEmail = 'Not logged in';
  int _avatarIndex = 0;

  final List<Color> _avatarColors = [
    AppColors.primaryGreen,
    const Color(0xFF53B175),
    const Color(0xFFF3603F),
    const Color(0xFF5383EC),
    const Color(0xFFD470FF),
    const Color(0xFFF8A44C),
  ];

  final List<IconData> _avatarIcons = [
    Icons.person,
    Icons.face,
    Icons.sentiment_very_satisfied,
    Icons.emoji_emotions,
    Icons.nature_people,
    Icons.account_circle,
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    AccountStorageService().profileUpdateNotifier.addListener(_loadProfile);
  }

  @override
  void dispose() {
    AccountStorageService().profileUpdateNotifier.removeListener(_loadProfile);
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    final savedData = await AccountStorageService().getUserProfile();

    String name = savedData['name'] ?? '';
    if (name.isEmpty && user?.displayName != null && user!.displayName!.isNotEmpty) {
      name = user.displayName!;
    }
    if (name.isEmpty && user?.email != null && user!.email!.isNotEmpty) {
      name = user.email!.split('@').first;
    }
    if (name.isEmpty) {
      name = 'User';
    }

    final email = user?.email ?? 'user@freshbasket.com';
    int avatarIdx = int.tryParse(savedData['avatar'] ?? '0') ?? 0;
    if (avatarIdx >= _avatarColors.length) avatarIdx = 0;

    if (mounted) {
      setState(() {
        _displayName = name;
        _userEmail = email;
        _avatarIndex = avatarIdx;
      });
    }
  }

  void _navigateToOption(String title) {
    Widget targetScreen;

    switch (title) {
      case 'Orders':
        targetScreen = const OrdersScreen();
        break;
      case 'My Details':
        targetScreen = const MyDetailsScreen();
        break;
      case 'Delivery Address':
        targetScreen = const DeliveryAddressScreen();
        break;
      case 'Payment Methods':
        targetScreen = const PaymentMethodsScreen();
        break;
      case 'Promo Card':
        targetScreen = const PromoCardScreen();
        break;
      case 'Notifications':
        targetScreen = const NotificationsScreen();
        break;
      case 'Help':
        targetScreen = const HelpScreen();
        break;
      case 'About':
        targetScreen = const AboutScreen();
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => targetScreen),
    ).then((_) => _loadProfile());
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppColors.primaryGreen),
            SizedBox(width: 10),
            Text('Log Out'),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of your account?',
          style: TextStyle(fontSize: 15, color: AppColors.textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const LogoutEvent());
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const MobileLoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {'icon': Icons.shopping_bag_outlined, 'title': 'Orders', 'color': AppColors.primaryGreen},
      {'icon': Icons.badge_outlined, 'title': 'My Details', 'color': const Color(0xFF5383EC)},
      {'icon': Icons.location_on_outlined, 'title': 'Delivery Address', 'color': const Color(0xFFF3603F)},
      {'icon': Icons.credit_card_outlined, 'title': 'Payment Methods', 'color': const Color(0xFFF8A44C)},
      {'icon': Icons.confirmation_number_outlined, 'title': 'Promo Card', 'color': const Color(0xFF9C27B0)},
      {'icon': Icons.notifications_none_outlined, 'title': 'Notifications', 'color': const Color(0xFF00ACC1)},
      {'icon': Icons.help_outline, 'title': 'Help', 'color': const Color(0xFF43A047)},
      {'icon': Icons.info_outline, 'title': 'About', 'color': const Color(0xFF5E35B1)},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Profile Header Card (Tappable to Edit)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: InkWell(
                  onTap: () => _navigateToOption('My Details'),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: _avatarColors[_avatarIndex].withValues(alpha: 0.15),
                          child: Icon(
                            _avatarIcons[_avatarIndex],
                            size: 40,
                            color: _avatarColors[_avatarIndex],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      _displayName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.edit_outlined,
                                    size: 16,
                                    color: AppColors.primaryGreen,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _userEmail,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textGrey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppColors.textGrey,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Divider(color: AppColors.divider, height: 1),

              // Menu List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: menuItems.length,
                separatorBuilder: (context, index) =>
                    const Divider(color: AppColors.divider, height: 1),
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  final itemColor = item['color'] as Color;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: itemColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: itemColor,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item['title'] as String,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.textGrey,
                    ),
                    onTap: () => _navigateToOption(item['title'] as String),
                  );
                },
              ),

              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 28),

              // Log Out Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _confirmLogout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF2F3F2),
                      foregroundColor: AppColors.primaryGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.logout,
                          color: AppColors.primaryGreen,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Log Out',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
