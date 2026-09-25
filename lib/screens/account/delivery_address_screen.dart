import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/account_storage_service.dart';

class DeliveryAddressScreen extends StatefulWidget {
  const DeliveryAddressScreen({super.key});

  @override
  State<DeliveryAddressScreen> createState() => _DeliveryAddressScreenState();
}

class _DeliveryAddressScreenState extends State<DeliveryAddressScreen> {
  List<AddressModel> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final list = await AccountStorageService().getAddresses();
    if (mounted) {
      setState(() {
        _addresses = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _setDefault(String id) async {
    await AccountStorageService().setDefaultAddress(id);
    await _loadAddresses();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Default delivery address updated'),
          duration: Duration(milliseconds: 900),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    }
  }

  Future<void> _deleteAddress(AddressModel address) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Address?'),
        content: Text('Are you sure you want to remove "${address.title}"?'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AccountStorageService().deleteAddress(address.id);
      await _loadAddresses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address deleted successfully'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showAddressDialog({AddressModel? existing}) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: existing?.title ?? 'Home');
    final nameController = TextEditingController(text: existing?.recipientName ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final streetController = TextEditingController(text: existing?.street ?? '');
    final cityController = TextEditingController(text: existing?.city ?? '');
    final stateController = TextEditingController(text: existing?.state ?? '');
    final zipController = TextEditingController(text: existing?.zipCode ?? '');
    bool isDefault = existing?.isDefault ?? false;

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
                            Text(
                              existing == null ? 'Add New Address' : 'Edit Address',
                              style: const TextStyle(
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

                        // Address Label / Type
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

                        // Recipient Name
                        _buildInputField(
                          label: 'Full Name',
                          controller: nameController,
                          hint: 'e.g. John Doe',
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),

                        const SizedBox(height: 12),

                        // Phone Number
                        _buildInputField(
                          label: 'Phone Number',
                          controller: phoneController,
                          hint: '+1 234 567 8900',
                          keyboardType: TextInputType.phone,
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),

                        const SizedBox(height: 12),

                        // Street Address
                        _buildInputField(
                          label: 'Street Address',
                          controller: streetController,
                          hint: 'Apartment, suite, street name',
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),

                        const SizedBox(height: 12),

                        // City & State & Zip
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildInputField(
                                label: 'City',
                                controller: cityController,
                                hint: 'City',
                                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: _buildInputField(
                                label: 'State',
                                controller: stateController,
                                hint: 'State',
                                validator: (val) => val == null || val.isEmpty ? 'Req' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: _buildInputField(
                                label: 'ZIP',
                                controller: zipController,
                                hint: 'ZIP',
                                keyboardType: TextInputType.number,
                                validator: (val) => val == null || val.isEmpty ? 'Req' : null,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Default Switch
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Set as default address',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          activeThumbColor: AppColors.primaryGreen,
                          value: isDefault,
                          onChanged: (val) {
                            setModalState(() {
                              isDefault = val;
                            });
                          },
                        ),

                        const SizedBox(height: 20),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;

                              final address = AddressModel(
                                id: existing?.id ?? 'addr_${DateTime.now().millisecondsSinceEpoch}',
                                title: titleController.text.trim(),
                                recipientName: nameController.text.trim(),
                                phone: phoneController.text.trim(),
                                street: streetController.text.trim(),
                                city: cityController.text.trim(),
                                state: stateController.text.trim(),
                                zipCode: zipController.text.trim(),
                                isDefault: isDefault,
                              );

                              if (existing == null) {
                                await AccountStorageService().addAddress(address);
                              } else {
                                await AccountStorageService().updateAddress(address);
                              }

                              if (bottomCtx.mounted) {
                                Navigator.pop(bottomCtx);
                              }
                              await _loadAddresses();

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(existing == null ? 'Address added!' : 'Address updated!'),
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
                            child: Text(
                              existing == null ? 'Save Address' : 'Update Address',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
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
          'Delivery Address',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : _addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off_outlined, size: 70, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text(
                        'No addresses saved',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 8),
                      const Text('Add a delivery address to get your groceries shipped!',
                          style: TextStyle(fontSize: 14, color: AppColors.textGrey)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: _addresses.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final addr = _addresses[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: addr.isDefault ? AppColors.primaryGreen : AppColors.border,
                          width: addr.isDefault ? 1.8 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                addr.title.toLowerCase().contains('work')
                                    ? Icons.business_outlined
                                    : Icons.home_outlined,
                                color: AppColors.primaryGreen,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                addr.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (addr.isDefault)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGreenLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'DEFAULT',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textGrey),
                                onPressed: () => _showAddressDialog(existing: addr),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                onPressed: () => _deleteAddress(addr),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            addr.recipientName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            addr.fullAddress,
                            style: const TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.3),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            addr.phone,
                            style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
                          ),
                          if (!addr.isDefault) ...[
                            const SizedBox(height: 10),
                            const Divider(color: AppColors.divider),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () => _setDefault(addr.id),
                                icon: const Icon(Icons.check_circle_outline, size: 16, color: AppColors.primaryGreen),
                                label: const Text(
                                  'Set as Default',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () => _showAddressDialog(),
            icon: const Icon(Icons.add, size: 20),
            label: const Text(
              'Add New Address',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ),
    );
  }
}
