import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../../widgets/effects.dart';

class BusinessProfileScreen extends ConsumerStatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  ConsumerState<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends ConsumerState<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  String _category = 'restaurant';
  bool _isLoading = false;
  bool _isExisting = false;

  @override
  void initState() {
    super.initState();
    _loadBusiness();
  }

  void _loadBusiness() {
    final business = ref.read(myBusinessProvider).valueOrNull;
    if (business != null) {
      _isExisting = true;
      _nameController.text = business.name;
      _descriptionController.text = business.description ?? '';
      _addressController.text = business.addressLine1;
      _cityController.text = business.city;
      _phoneController.text = business.phone ?? '';
      _category = business.category;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.selectionClick();
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final service = ref.read(businessServiceProvider);
      final data = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _category,
        'address_line1': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'country': 'CO',
        'phone': _phoneController.text.trim(),
        'latitude': 4.7110, // TODO: Use actual geocoded location
        'longitude': -74.0721,
      };

      if (_isExisting) {
        final business = ref.read(myBusinessProvider).valueOrNull!;
        await service.updateBusiness(business.id, data);
      } else {
        await service.createBusiness(data);
      }

      ref.invalidate(myBusinessProvider);

      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Business saved',
                style: TextStyle(
                    fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Couldn't save. Please try again.",
                style: TextStyle(
                    fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isExisting ? 'Business Settings' : 'Set Up Business'),
        actions: [
          if (_isExisting)
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'switch') {
                  final auth = ref.read(authServiceProvider);
                  await auth.updateProfile({'role': 'consumer'});
                  if (mounted) context.go('/consumer');
                } else if (v == 'logout') {
                  await ref.read(authServiceProvider).signOut();
                  if (mounted) context.go('/auth/login');
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'switch', child: Text('Switch to Consumer')),
                const PopupMenuItem(value: 'logout', child: Text('Sign Out')),
              ],
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo placeholder
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: const Icon(Icons.store, size: 40, color: AppTheme.primaryColor),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'Business Name', prefixIcon: Icon(Icons.store)),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Description', prefixIcon: Icon(Icons.description)),
              ),
              const SizedBox(height: 16),

              // Category
              const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ('restaurant', 'Restaurant', Icons.restaurant),
                  ('bar', 'Bar', Icons.local_bar),
                  ('cafe', 'Cafe', Icons.coffee),
                  ('food_truck', 'Food Truck', Icons.delivery_dining),
                  ('bakery', 'Bakery', Icons.cake),
                ].map((c) => ChoiceChip(
                  avatar: Icon(c.$3, size: 18),
                  label: Text(c.$2),
                  selected: _category == c.$1,
                  onSelected: (_) => setState(() => _category = c.$1),
                  selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                )).toList(),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(hintText: 'Address', prefixIcon: Icon(Icons.location_on)),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(hintText: 'City', prefixIcon: Icon(Icons.location_city)),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: 'Phone', prefixIcon: Icon(Icons.phone)),
              ),
              const SizedBox(height: 32),

              if (_isExisting) ...[
                // Subscription info
                PressableScale(
                  onTap: () => context.push('/business/subscription'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.workspace_premium_rounded,
                            color: AppTheme.secondaryColor),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Subscription Plan', style: TextStyle(fontWeight: FontWeight.w600)),
                              Text('Manage your plan and billing', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppTheme.textLight),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      // Primary action pinned in the thumb zone.
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: AppTheme.navShadow,
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: _isLoading ? null : AppTheme.primaryGradient,
                color:
                    _isLoading ? AppTheme.primaryColor.withOpacity(0.4) : null,
                borderRadius: BorderRadius.circular(18),
                boxShadow: _isLoading ? [] : AppTheme.floatingShadow,
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : Text(
                        _isExisting ? 'Save changes' : 'Create business',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
