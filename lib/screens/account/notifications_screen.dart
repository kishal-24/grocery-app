import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/account_storage_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<NotificationItemModel> _notifications = [];
  Map<String, bool> _settings = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final notifs = await AccountStorageService().getNotifications();
    final settings = await AccountStorageService().getNotificationSettings();
    if (mounted) {
      setState(() {
        _notifications = notifs;
        _settings = settings;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    await AccountStorageService().markAllNotificationsAsRead();
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: AppColors.primaryGreen,
          duration: Duration(milliseconds: 900),
        ),
      );
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear all notifications?'),
        content: const Text('This will remove all notification history.'),
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
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AccountStorageService().clearAllNotifications();
      await _loadData();
    }
  }

  void _showNotificationDetail(NotificationItemModel item) async {
    if (!item.isRead) {
      await AccountStorageService().markNotificationAsRead(item.id);
      _loadData();
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            _buildTypeIcon(item.type),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.message, style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.textDark)),
            const SizedBox(height: 16),
            Text(item.time, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'delivery':
        icon = Icons.local_shipping_outlined;
        color = const Color(0xFF5383EC);
        break;
      case 'promo':
        icon = Icons.local_offer_outlined;
        color = const Color(0xFFF3603F);
        break;
      case 'order':
        icon = Icons.check_circle_outline;
        color = AppColors.primaryGreen;
        break;
      case 'system':
      default:
        icon = Icons.notifications_outlined;
        color = const Color(0xFFF8A44C);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

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
          'Notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        actions: [
          if (_notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textDark),
              onSelected: (value) {
                if (value == 'read') _markAllRead();
                if (value == 'clear') _clearAll();
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'read',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, size: 18, color: AppColors.primaryGreen),
                      SizedBox(width: 8),
                      Text('Mark all as read'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_outlined, size: 18, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Text('Clear all'),
                    ],
                  ),
                ),
              ],
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: AppColors.textGrey,
          indicatorColor: AppColors.primaryGreen,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Inbox'),
                  if (unreadCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Preferences'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildInboxTab(),
                _buildPreferencesTab(),
              ],
            ),
    );
  }

  Widget _buildInboxTab() {
    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 70, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Stay tuned for order updates and discounts!',
              style: TextStyle(fontSize: 14, color: AppColors.textGrey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _notifications.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _notifications[index];
        return Container(
          decoration: BoxDecoration(
            color: item.isRead ? Colors.white : AppColors.primaryGreenLight.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isRead ? AppColors.border : AppColors.primaryGreen.withValues(alpha: 0.4),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            onTap: () => _showNotificationDetail(item),
            leading: _buildTypeIcon(item.type),
            title: Text(
              item.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  item.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textGrey, height: 1.3),
                ),
                const SizedBox(height: 4),
                Text(
                  item.time,
                  style: const TextStyle(fontSize: 10, color: AppColors.textGrey),
                ),
              ],
            ),
            trailing: item.isRead
                ? null
                : Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildPreferencesTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        const Text(
          'Push Notification Settings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose what notifications you would like to receive from Fresh Basket.',
          style: TextStyle(fontSize: 13, color: AppColors.textGrey),
        ),
        const SizedBox(height: 20),

        _buildSwitchTile(
          keyName: 'orders',
          title: 'Order Status Updates',
          subtitle: 'Real-time alerts when your grocery order is confirmed, packed, and out for delivery.',
        ),
        const Divider(color: AppColors.divider),

        _buildSwitchTile(
          keyName: 'delivery',
          title: 'Delivery & Driver Alerts',
          subtitle: 'Live ETA updates and delivery driver location messages.',
        ),
        const Divider(color: AppColors.divider),

        _buildSwitchTile(
          keyName: 'promos',
          title: 'Discounts & Special Offers',
          subtitle: 'Get notified about flash weekend deals, vouchers, and member rewards.',
        ),
        const Divider(color: AppColors.divider),

        _buildSwitchTile(
          keyName: 'newsletter',
          title: 'Weekly Fresh Produce Guide',
          subtitle: 'Curated recipes, seasonal fruit highlights, and health tips.',
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String keyName,
    required String title,
    required String subtitle,
  }) {
    final isVal = _settings[keyName] ?? true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        activeThumbColor: AppColors.primaryGreen,
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.textGrey, height: 1.3),
          ),
        ),
        value: isVal,
        onChanged: (newVal) async {
          setState(() {
            _settings[keyName] = newVal;
          });
          await AccountStorageService().setNotificationSetting(keyName, newVal);
        },
      ),
    );
  }
}
