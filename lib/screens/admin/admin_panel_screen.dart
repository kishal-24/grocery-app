import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/product_model.dart';
import '../../data/services/account_storage_service.dart';
import '../../data/services/admin_service.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminService _adminService = AdminService();

  // Search & Filter controllers
  final TextEditingController _orderSearchController = TextEditingController();
  String _selectedOrderStatus = 'All';

  final TextEditingController _productSearchController = TextEditingController();
  String _selectedProductCategory = 'All';

  // UPI Settings controller
  final TextEditingController _upiIdController = TextEditingController();
  bool _savingUpi = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadUpiSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _orderSearchController.dispose();
    _productSearchController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  Future<void> _loadUpiSettings() async {
    final upi = await _adminService.getCanaraUpiId();
    if (mounted) {
      _upiIdController.text = upi;
    }
  }

  Future<void> _saveUpiSettings() async {
    final newUpi = _upiIdController.text.trim();
    if (newUpi.isEmpty || !newUpi.contains('@')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid UPI ID (e.g. freshbasket@cnrb)'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _savingUpi = true);
    await _adminService.saveCanaraUpiId(newUpi);
    if (!mounted) return;
    setState(() => _savingUpi = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Merchant UPI ID updated to $newUpi'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Sign Out Admin'),
          ],
        ),
        content: const Text('Are you sure you want to sign out of the Admin Portal?'),
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
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textDark, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : const Padding(
                padding: EdgeInsets.all(12.0),
                child: Icon(Icons.admin_panel_settings, color: AppColors.primaryGreen),
              ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FreshBasket Admin',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'Store & Payment Control Center',
              style: TextStyle(
                color: AppColors.textGrey,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, color: AppColors.primaryGreen, size: 14),
                SizedBox(width: 4),
                Text(
                  'Live Admin',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Sign Out Admin',
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => _confirmSignOut(context),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: AppColors.textGrey,
          indicatorColor: AppColors.primaryGreen,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Overview'),
            Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Orders'),
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Products'),
            Tab(icon: Icon(Icons.tune_outlined), text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildOrdersTab(),
          _buildProductsTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  // =========================================================================
  // 1. OVERVIEW DASHBOARD TAB
  // =========================================================================
  Widget _buildOverviewTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _adminService.getDashboardMetrics(),
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
        }

        final data = snapshot.data ?? {};
        final double revenue = (data['totalRevenue'] as num?)?.toDouble() ?? 0.0;
        final int totalOrders = (data['totalOrders'] as num?)?.toInt() ?? 0;
        final int pendingUpi = (data['pendingUpiCount'] as num?)?.toInt() ?? 0;
        final int activeOrders = (data['activeOrdersCount'] as num?)?.toInt() ?? 0;
        final int totalProducts = (data['totalProducts'] as num?)?.toInt() ?? 0;
        final int lowStock = (data['lowStockCount'] as num?)?.toInt() ?? 0;

        return RefreshIndicator(
          color: AppColors.primaryGreen,
          onRefresh: () async {
            setState(() {});
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top UPI Alert Banner if pending orders exist
                if (pendingUpi > 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFEEBA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Color(0xFF856404), size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$pendingUpi Pending UPI Payment${pendingUpi > 1 ? 's' : ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF856404),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Customers completed Canara UPI transfer. Tap to verify and confirm orders.',
                                style: TextStyle(
                                  color: Color(0xFF856404),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedOrderStatus = 'Pending UPI';
                              _tabController.animateTo(1);
                            });
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFF856404),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Review', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),

                // Metrics Grid
                const Text(
                  'Store Performance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Total Revenue',
                        value: '₹${revenue.toStringAsFixed(2)}',
                        icon: Icons.currency_rupee,
                        color: AppColors.primaryGreen,
                        subtext: 'Completed & Delivered',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Total Orders',
                        value: '$totalOrders',
                        icon: Icons.shopping_bag,
                        color: const Color(0xFF5383EC),
                        subtext: 'Lifetime orders',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Pending UPI',
                        value: '$pendingUpi',
                        icon: Icons.qr_code_scanner,
                        color: const Color(0xFFF3603F),
                        subtext: 'Awaiting Admin check',
                        badge: pendingUpi > 0 ? 'Action Needed' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Active Orders',
                        value: '$activeOrders',
                        icon: Icons.local_shipping,
                        color: const Color(0xFFF8A44C),
                        subtext: 'Processing / In transit',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Catalog Size',
                        value: '$totalProducts',
                        icon: Icons.inventory,
                        color: const Color(0xFF9C27B0),
                        subtext: 'Listed products',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Low Stock Alert',
                        value: '$lowStock',
                        icon: Icons.production_quantity_limits,
                        color: lowStock > 0 ? Colors.redAccent : Colors.teal,
                        subtext: 'Stock <= 5 units',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Quick Management Actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _buildQuickActionTile(
                        icon: Icons.add_circle_outline,
                        color: AppColors.primaryGreen,
                        title: 'Add New Product',
                        subtitle: 'Upload product image, price in ₹, unit, category',
                        onTap: () => _showAddProductDialog(),
                      ),
                      const Divider(height: 1),
                      _buildQuickActionTile(
                        icon: Icons.verified_user_outlined,
                        color: const Color(0xFF5383EC),
                        title: 'Review Pending UPI Orders',
                        subtitle: 'Verify Canara Bank UPI transactions',
                        onTap: () {
                          setState(() {
                            _selectedOrderStatus = 'Pending UPI';
                            _tabController.animateTo(1);
                          });
                        },
                      ),
                      const Divider(height: 1),
                      _buildQuickActionTile(
                        icon: Icons.discount_outlined,
                        color: const Color(0xFF9C27B0),
                        title: 'Create Promo Code',
                        subtitle: 'Offer discount vouchers to boost purchases',
                        onTap: () => _showAddPromoDialog(),
                      ),
                      const Divider(height: 1),
                      _buildQuickActionTile(
                        icon: Icons.account_balance_outlined,
                        color: const Color(0xFFF3603F),
                        title: 'Configure Canara UPI Merchant ID',
                        subtitle: 'Currently set to: ${_upiIdController.text}',
                        onTap: () => _tabController.animateTo(3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtext,
    String? badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textGrey,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textGrey),
    );
  }

  // =========================================================================
  // 2. ORDERS MANAGEMENT TAB (WITH UPI VERIFICATION)
  // =========================================================================
  Widget _buildOrdersTab() {
    final statusFilters = [
      'All',
      'Pending UPI',
      'Pending',
      'Confirmed',
      'Processing',
      'In Transit',
      'Delivered',
      'Cancelled',
    ];

    return Column(
      children: [
        // Search & Filter header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              // Search input
              TextField(
                controller: _orderSearchController,
                decoration: InputDecoration(
                  hintText: 'Search by Order ID or UPI Txn Ref...',
                  hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textGrey, size: 20),
                  suffixIcon: _orderSearchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            setState(() {
                              _orderSearchController.clear();
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF4F5F7),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: statusFilters.map((status) {
                    final isSelected = _selectedOrderStatus == status;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(status),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : AppColors.textDark,
                        ),
                        backgroundColor: const Color(0xFFF0F1F2),
                        selectedColor: status == 'Pending UPI' ? const Color(0xFFF3603F) : AppColors.primaryGreen,
                        checkmarkColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        side: BorderSide.none,
                        onSelected: (selected) {
                          setState(() {
                            _selectedOrderStatus = status;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Live Orders Stream
        Expanded(
          child: StreamBuilder<List<OrderModel>>(
            stream: _adminService.streamAllOrders(),
            builder: (_, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
              }

              final allOrders = snapshot.data ?? [];

              // Filter by status & search
              final query = _orderSearchController.text.trim().toLowerCase();
              final filteredOrders = allOrders.where((order) {
                // Status filter
                if (_selectedOrderStatus == 'Pending UPI') {
                  if ((order.paymentStatus?.toLowerCase() ?? '') != 'pending') {
                    return false;
                  }
                } else if (_selectedOrderStatus != 'All') {
                  if (order.status.toLowerCase() != _selectedOrderStatus.toLowerCase()) {
                    return false;
                  }
                }

                // Search query
                if (query.isNotEmpty) {
                  final matchesId = order.id.toLowerCase().contains(query);
                  final matchesTxn = (order.transactionRef ?? '').toLowerCase().contains(query);
                  final matchesPaymentId = (order.paymentId ?? '').toLowerCase().contains(query);
                  if (!matchesId && !matchesTxn && !matchesPaymentId) {
                    return false;
                  }
                }

                return true;
              }).toList();

              if (filteredOrders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        _selectedOrderStatus == 'Pending UPI'
                            ? 'No Pending UPI Orders'
                            : 'No Orders Found',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _selectedOrderStatus == 'Pending UPI'
                            ? 'All UPI payments are verified and clear!'
                            : 'Try adjusting filters or search query',
                        style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filteredOrders.length,
                separatorBuilder: (context, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final order = filteredOrders[index];
                  return _buildOrderAdminCard(order);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrderAdminCard(OrderModel order) {
    final isUpi = order.paymentMethod.toLowerCase().contains('upi') ||
        order.paymentMethod.toLowerCase().contains('google') ||
        (order.transactionRef?.startsWith('UPI-') ?? false);
    final isPaymentPending = (order.paymentStatus?.toLowerCase() ?? '') == 'pending';

    Color statusColor;
    switch (order.status.toLowerCase()) {
      case 'confirmed':
        statusColor = const Color(0xFF5383EC);
        break;
      case 'processing':
      case 'in transit':
        statusColor = const Color(0xFFF8A44C);
        break;
      case 'delivered':
        statusColor = AppColors.primaryGreen;
        break;
      case 'cancelled':
        statusColor = Colors.redAccent;
        break;
      default:
        statusColor = const Color(0xFFF3603F);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPaymentPending ? const Color(0xFFF3603F).withValues(alpha: 0.4) : AppColors.border,
          width: isPaymentPending ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.receipt, size: 16, color: AppColors.primaryGreen),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '#${order.id.length > 12 ? order.id.substring(0, 12) : order.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Order Meta
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textGrey),
              const SizedBox(width: 4),
              Text(
                order.date,
                style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
              ),
              const Spacer(),
              Text(
                '₹${order.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Delivery info & Items
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textGrey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  order.deliveryAddress,
                  style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w500),
              ),
            ],
          ),

          const Divider(height: 20),

          // Payment & UPI Details
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isUpi ? Icons.account_balance_wallet_outlined : Icons.payment,
                          size: 15,
                          color: AppColors.textDark,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          order.paymentMethod,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPaymentPending
                            ? Colors.orange.withValues(alpha: 0.15)
                            : Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        order.paymentStatus ?? (isPaymentPending ? 'Pending' : 'Paid'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isPaymentPending ? Colors.orange.shade800 : Colors.green.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                if (order.transactionRef != null && order.transactionRef!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text(
                        'UPI Txn Ref: ',
                        style: TextStyle(fontSize: 11, color: AppColors.textGrey),
                      ),
                      Expanded(
                        child: Text(
                          order.transactionRef!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: order.transactionRef!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('UPI Reference copied to clipboard'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.copy, size: 14, color: AppColors.primaryGreen),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Admin Action Controls
          Row(
            children: [
              // Verify UPI Payment Button (if pending)
              if (isPaymentPending)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _verifyUpiPayment(order),
                    icon: const Icon(Icons.verified, size: 16),
                    label: const Text('Verify UPI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              if (isPaymentPending) const SizedBox(width: 8),

              // Status Change Dropdown
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showChangeStatusDialog(order),
                  icon: const Icon(Icons.edit_note, size: 16),
                  label: const Text('Update Status', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textDark,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // View Order Details
              IconButton(
                icon: const Icon(Icons.info_outline, color: AppColors.textGrey, size: 20),
                onPressed: () => _showOrderDetailsDialog(order),
                tooltip: 'Order Items & Details',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _verifyUpiPayment(OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('Verify UPI Payment', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Amount: ₹${order.totalAmount.toStringAsFixed(2)}'),
            if (order.transactionRef != null) ...[
              const SizedBox(height: 4),
              Text(
                'UPI Reference:\n${order.transactionRef}',
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Did you receive this amount in your Canara Bank account / UPI QR? Marking verified will confirm the order and notify the customer.',
              style: TextStyle(fontSize: 12, color: AppColors.textGrey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Confirm Received'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _adminService.verifyUpiPayment(order.id, order.transactionRef);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order #${order.id} payment verified and marked Confirmed!'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update payment status. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showChangeStatusDialog(OrderModel order) {
    final statuses = ['Confirmed', 'Processing', 'In Transit', 'Delivered', 'Cancelled'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Update Status for #${order.id.length > 10 ? order.id.substring(0, 10) : order.id}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(),
                ...statuses.map((status) {
                  final isCurrent = order.status.toLowerCase() == status.toLowerCase();
                  return ListTile(
                    leading: Icon(
                      isCurrent ? Icons.check_circle : Icons.circle_outlined,
                      color: isCurrent ? AppColors.primaryGreen : AppColors.textGrey,
                    ),
                    title: Text(
                      status,
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent ? AppColors.primaryGreen : AppColors.textDark,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final ok = await _adminService.updateOrderStatus(order.id, status);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok
                              ? 'Order #${order.id} updated to $status'
                              : 'Failed to update order status'),
                          backgroundColor: ok ? AppColors.primaryGreen : Colors.redAccent,
                        ),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOrderDetailsDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Order #${order.id}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Placed: ${order.date}', style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                Text('Address: ${order.deliveryAddress}', style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                const Divider(height: 20),
                const Text('Items Ordered:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                ...order.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.name} (${item.unit}) x ${item.quantity}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(
                      '₹${order.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryGreen),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 3. PRODUCTS CATALOG CRUD TAB
  // =========================================================================
  Widget _buildProductsTab() {
    final categories = [
      'All',
      'Fresh Fruits & Vegetable',
      'Cooking Oil & Ghee',
      'Meat & Fish',
      'Bakery & Snacks',
      'Dairy & Eggs',
      'Beverages',
    ];

    return Column(
      children: [
        // Product Search & Add Row
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _productSearchController,
                      decoration: InputDecoration(
                        hintText: 'Search products by name...',
                        hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: AppColors.textGrey, size: 20),
                        suffixIcon: _productSearchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _productSearchController.clear();
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFFF4F5F7),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => _showAddProductDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Category Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((cat) {
                    final isSelected = _selectedProductCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(cat),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : AppColors.textDark,
                        ),
                        backgroundColor: const Color(0xFFF0F1F2),
                        selectedColor: AppColors.primaryGreen,
                        checkmarkColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        side: BorderSide.none,
                        onSelected: (selected) {
                          setState(() {
                            _selectedProductCategory = cat;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Live Products Stream
        Expanded(
          child: StreamBuilder<List<ProductModel>>(
            stream: _adminService.streamProducts(),
            builder: (_, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
              }

              final products = snapshot.data ?? [];
              final query = _productSearchController.text.trim().toLowerCase();

              final filtered = products.where((p) {
                // Category filter
                if (_selectedProductCategory != 'All') {
                  if (p.category.toLowerCase() != _selectedProductCategory.toLowerCase()) {
                    return false;
                  }
                }

                // Query filter
                if (query.isNotEmpty) {
                  return p.name.toLowerCase().contains(query) ||
                      p.category.toLowerCase().contains(query);
                }
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'No Products Found',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _showAddProductDialog(),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                        child: const Text('Add First Product', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                separatorBuilder: (context, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final product = filtered[index];
                  return _buildProductAdminCard(product);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductAdminCard(ProductModel product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 60,
              height: 60,
              color: const Color(0xFFF6F7F9),
              child: product.image.isNotEmpty
                  ? Image.network(
                      product.image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, _) => const Icon(Icons.image, color: Colors.grey),
                    )
                  : const Icon(Icons.image, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${product.unit} • ${product.category}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ),

          // Edit & Delete actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Color(0xFF5383EC), size: 20),
                onPressed: () => _showAddProductDialog(existingProduct: product),
                tooltip: 'Edit Product',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                onPressed: () => _confirmDeleteProduct(product),
                tooltip: 'Delete Product',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProduct(ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to remove "${product.name}" from the store catalog?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await _adminService.deleteProduct(product.id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? 'Product deleted successfully' : 'Failed to delete product'),
                  backgroundColor: ok ? AppColors.primaryGreen : Colors.redAccent,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog({ProductModel? existingProduct}) {
    final nameCtrl = TextEditingController(text: existingProduct?.name ?? '');
    final priceCtrl = TextEditingController(text: existingProduct != null ? existingProduct.price.toString() : '');
    final unitCtrl = TextEditingController(text: existingProduct?.unit ?? '1kg, Price');
    final catCtrl = TextEditingController(text: existingProduct?.category ?? 'Fresh Fruits & Vegetable');
    final imgCtrl = TextEditingController(text: existingProduct?.image ?? '');
    final descCtrl = TextEditingController(text: existingProduct?.description ?? 'Fresh and premium quality grocery item.');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      existingProduct != null ? 'Edit Product' : 'Add New Product',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Name
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Product Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Price in INR & Unit
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Price (₹) *',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: unitCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Unit (e.g. 1kg) *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Category & Image URL
                TextField(
                  controller: catCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: imgCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    hintText: 'https://...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                      final unit = unitCtrl.text.trim();
                      final category = catCtrl.text.trim();
                      final image = imgCtrl.text.trim();
                      final desc = descCtrl.text.trim();

                      if (name.isEmpty || price <= 0 || unit.isEmpty || category.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill required fields (Name, Price > 0, Unit, Category)'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      final p = ProductModel(
                        id: existingProduct?.id ?? '',
                        name: name,
                        description: desc,
                        unit: unit,
                        price: price,
                        image: image.isNotEmpty ? image : 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=500',
                        category: category,
                      );

                      Navigator.pop(ctx);
                      final ok = await _adminService.saveProduct(p);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok ? 'Product saved successfully!' : 'Error saving product'),
                          backgroundColor: ok ? AppColors.primaryGreen : Colors.redAccent,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      existingProduct != null ? 'Update Product' : 'Add to Catalog',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  // =========================================================================
  // 4. SETTINGS & CANARA UPI CONFIGURATION TAB
  // =========================================================================
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Canara Bank UPI Merchant Config Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.account_balance, color: AppColors.primaryGreen, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Canara Bank UPI Configuration',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Set the Canara Bank VPA / UPI ID where customer Google Pay transfers will be routed in India.',
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _upiIdController,
                  decoration: InputDecoration(
                    labelText: 'Merchant Canara UPI ID',
                    hintText: 'freshbasket@cnrb',
                    prefixIcon: const Icon(Icons.alternate_email, color: AppColors.textGrey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    helperText: 'Standard Canara UPI handles @cnrb',
                  ),
                ),
                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _savingUpi ? null : _saveUpiSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _savingUpi
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Save UPI Merchant ID', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Promo Codes Management Header & List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Active Promo Codes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showAddPromoDialog(),
                icon: const Icon(Icons.add, size: 16, color: AppColors.primaryGreen),
                label: const Text('Add Promo', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          FutureBuilder<List<PromoModel>>(
            future: _adminService.getAllPromos(),
            builder: (_, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: AppColors.primaryGreen),
                ));
              }

              final promos = snapshot.data ?? [];
              if (promos.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Text(
                      'No promo codes created yet.\nTap "Add Promo" to create vouchers.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                    ),
                  ),
                );
              }

              return Column(
                children: promos.map((promo) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9C27B0).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.confirmation_number_outlined, color: Color(0xFF9C27B0), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    promo.code,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGreen.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      promo.discountPercent > 0
                                          ? '${promo.discountPercent}% OFF'
                                          : '₹${promo.discountAmount.toStringAsFixed(0)} OFF',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryGreen,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${promo.title} • Min spend ₹${promo.minSpend.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          onPressed: () async {
                            final ok = await _adminService.deletePromo(promo.code);
                            if (!mounted) return;
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok ? 'Promo ${promo.code} deleted' : 'Failed to delete promo'),
                                backgroundColor: ok ? AppColors.primaryGreen : Colors.redAccent,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  void _showAddPromoDialog() {
    final codeCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final percentCtrl = TextEditingController();
    final minSpendCtrl = TextEditingController(text: '200');
    final expiryCtrl = TextEditingController(text: '31 Dec 2026');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Create Promo Code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Promo Code (e.g. CANARA10) *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title (e.g. Canara Special) *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: percentCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Discount % *', suffixText: '%', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: minSpendCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Min Spend (₹) *', prefixText: '₹ ', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: expiryCtrl,
                  decoration: const InputDecoration(labelText: 'Expiry Date', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final code = codeCtrl.text.trim().toUpperCase();
                      final title = titleCtrl.text.trim();
                      final desc = descCtrl.text.trim();
                      final percent = int.tryParse(percentCtrl.text.trim()) ?? 0;
                      final minSpend = double.tryParse(minSpendCtrl.text.trim()) ?? 0.0;
                      final expiry = expiryCtrl.text.trim();

                      if (code.isEmpty || title.isEmpty || percent <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill all required promo fields'), backgroundColor: Colors.redAccent),
                        );
                        return;
                      }

                      final promo = PromoModel(
                        code: code,
                        title: title,
                        description: desc.isNotEmpty
                            ? desc
                            : 'Get $percent% discount on orders above ₹${minSpend.toStringAsFixed(0)}',
                        discountPercent: percent,
                        minSpend: minSpend,
                        expiryDate: expiry,
                      );

                      Navigator.pop(ctx);
                      final ok = await _adminService.savePromo(promo);
                      if (!mounted) return;
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok ? 'Promo code $code created!' : 'Failed to save promo'),
                          backgroundColor: ok ? AppColors.primaryGreen : Colors.redAccent,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save Promo Voucher', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
