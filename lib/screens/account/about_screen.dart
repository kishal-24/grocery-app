import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Terms of Service', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1. Acceptance of Terms\n'
                'By accessing or using the Fresh Basket Grocery application, you agree to comply with and be bound by these Terms of Service.\n\n'
                '2. Service & Product Availability\n'
                'Fresh Basket provides on-demand grocery ordering and delivery. All items are subject to harvest and stock availability.\n\n'
                '3. Pricing and Payments\n'
                'All prices are listed in USD. Taxes and delivery fees are clearly displayed before you submit your order.\n\n'
                '4. Cancellation and Refund Policy\n'
                'Orders may be cancelled before they enter the packed stage. If any fresh product fails to meet high standards, submit a claim within 24 hours for a full replacement or refund.',
                style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textDark),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1. Data Collection\n'
                'We only collect information necessary to process your grocery orders, manage delivery addresses, and personalize your recommendations.\n\n'
                '2. Payment Security\n'
                'Payment card details are processed through encrypted, PCI-compliant gateways. Fresh Basket never stores sensitive CVV or raw card credentials on our servers.\n\n'
                '3. Location Services\n'
                'Location permissions are used solely to estimate delivery times and calculate nearby inventory.\n\n'
                '4. Third-Party Sharing\n'
                'We do not sell your personal information to third parties.',
                style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textDark),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showRateAppDialog(BuildContext context) {
    int rating = 5;
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Center(
              child: Text(
                'Rate Fresh Basket',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'How was your experience shopping with us?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starNum = index + 1;
                    return IconButton(
                      icon: Icon(
                        starNum <= rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          rating = starNum;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: feedbackController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Leave a comment (optional)...',
                    hintStyle: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Later', style: TextStyle(color: AppColors.textGrey)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⭐ Thank you for your rating and feedback!'),
                      backgroundColor: AppColors.primaryGreen,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Submit Rating'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _shareApp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing "Fresh Basket - Daily Groceries & Fresh Produce" with friends!'),
        backgroundColor: AppColors.primaryGreen,
        duration: Duration(seconds: 2),
      ),
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
          'About',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // App Brand Logo & Name
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.primaryGreenLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryGreen, width: 2),
              ),
              child: const Icon(
                Icons.local_grocery_store_rounded,
                size: 46,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Fresh Basket',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Version 1.0.0 (Build 100)',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Your trusted everyday grocery companion. Delivering farm-fresh fruits, organic vegetables, dairy, and household essentials directly to your kitchen counter.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 28),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 10),

            // Menu Options
            _buildAboutOption(
              icon: Icons.star_rate_rounded,
              title: 'Rate App',
              onTap: () => _showRateAppDialog(context),
            ),
            const Divider(color: AppColors.divider),

            _buildAboutOption(
              icon: Icons.share_outlined,
              title: 'Share with Friends',
              onTap: () => _shareApp(context),
            ),
            const Divider(color: AppColors.divider),

            _buildAboutOption(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              onTap: () => _showTermsDialog(context),
            ),
            const Divider(color: AppColors.divider),

            _buildAboutOption(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () => _showPrivacyDialog(context),
            ),
            const Divider(color: AppColors.divider),

            _buildAboutOption(
              icon: Icons.code,
              title: 'Open Source Licenses',
              onTap: () {
                showLicensePage(
                  context: context,
                  applicationName: 'Fresh Basket Grocery',
                  applicationVersion: 'v1.0.0',
                  applicationLegalese: '© 2026 Fresh Basket Inc. All rights reserved.',
                );
              },
            ),
            const Divider(color: AppColors.divider),

            const SizedBox(height: 30),
            const Text(
              '© 2026 Fresh Basket Technologies Inc.\nMade with ❤️ for fresh living',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textGrey,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryGreenLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primaryGreen, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: AppColors.textDark,
      ),
      onTap: onTap,
    );
  }
}
