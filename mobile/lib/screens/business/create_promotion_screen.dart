import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/business_provider.dart';
import '../../providers/promotion_provider.dart';

class CreatePromotionScreen extends ConsumerStatefulWidget {
  const CreatePromotionScreen({super.key});

  @override
  ConsumerState<CreatePromotionScreen> createState() => _CreatePromotionScreenState();
}

class _CreatePromotionScreenState extends ConsumerState<CreatePromotionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountValueController = TextEditingController();
  String _discountType = 'percentage';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _activeTimeStart = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _activeTimeEnd = const TimeOfDay(hour: 22, minute: 0);
  int? _maxRedemptions;
  final Set<String> _activeDays = {'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'};
  bool _isLoading = false;

  // Template promotions
  final _templates = [
    {'title': 'Happy Hour', 'desc': '2x1 on selected cocktails', 'type': 'bogo', 'value': '0'},
    {'title': '20% Off Total Bill', 'desc': '20% discount on your total bill', 'type': 'percentage', 'value': '20'},
    {'title': 'Free Dessert', 'desc': 'Free dessert with any main course', 'type': 'free_item', 'value': '0'},
    {'title': '\$5 Off', 'desc': '\$5 off orders over \$25', 'type': 'fixed', 'value': '5'},
  ];

  void _applyTemplate(Map<String, String> t) {
    _titleController.text = t['title']!;
    _descriptionController.text = t['desc']!;
    _discountType = t['type']!;
    _discountValueController.text = t['value']!;
    setState(() {});
  }

  Future<void> _createPromotion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final business = ref.read(myBusinessProvider).valueOrNull;
      if (business == null) throw Exception('No business found');

      final service = ref.read(promotionServiceProvider);
      await service.createPromotion({
        'business_id': business.id,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'discount_type': _discountType,
        'discount_value': double.tryParse(_discountValueController.text) ?? 0,
        'status': 'active',
        'starts_at': _startDate.toIso8601String(),
        'ends_at': _endDate.toIso8601String(),
        'active_time_start': '${_activeTimeStart.hour.toString().padLeft(2, '0')}:${_activeTimeStart.minute.toString().padLeft(2, '0')}',
        'active_time_end': '${_activeTimeEnd.hour.toString().padLeft(2, '0')}:${_activeTimeEnd.minute.toString().padLeft(2, '0')}',
        'active_days': _activeDays.toList(),
        'max_total_redemptions': _maxRedemptions,
        'max_per_user': 1,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Promotion created!'), backgroundColor: AppTheme.successColor),
        );
        ref.invalidate(businessPromotionsProvider(business.id));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _discountValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Promotion')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Templates
              const Text('Quick Templates', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _templates.map((t) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(t['title']!),
                      onPressed: () => _applyTemplate(t),
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                      labelStyle: const TextStyle(color: AppTheme.primaryColor),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(hintText: 'Promotion Title', prefixIcon: Icon(Icons.title)),
                validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Description', prefixIcon: Icon(Icons.description)),
                validator: (v) => v == null || v.isEmpty ? 'Description is required' : null,
              ),
              const SizedBox(height: 24),

              // Discount Type
              const Text('Discount Type', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _DiscountChip('percentage', '% Off', Icons.percent),
                  _DiscountChip('fixed', '\$ Off', Icons.attach_money),
                  _DiscountChip('bogo', '2x1', Icons.looks_two),
                  _DiscountChip('free_item', 'Free Item', Icons.card_giftcard),
                ],
              ),
              const SizedBox(height: 16),

              // Discount Value
              if (_discountType == 'percentage' || _discountType == 'fixed')
                TextFormField(
                  controller: _discountValueController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: _discountType == 'percentage' ? 'Discount %' : 'Discount \$',
                    prefixIcon: Icon(_discountType == 'percentage' ? Icons.percent : Icons.attach_money),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Value is required' : null,
                ),
              const SizedBox(height: 24),

              // Dates
              const Text('Schedule', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DateButton(
                      label: 'Start',
                      date: _startDate,
                      onTap: () async {
                        final d = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)), initialDate: _startDate);
                        if (d != null) setState(() => _startDate = d);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateButton(
                      label: 'End',
                      date: _endDate,
                      onTap: () async {
                        final d = await showDatePicker(context: context, firstDate: _startDate, lastDate: DateTime.now().add(const Duration(days: 365)), initialDate: _endDate);
                        if (d != null) setState(() => _endDate = d);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Active Time
              Row(
                children: [
                  Expanded(
                    child: _TimeButton(
                      label: 'From',
                      time: _activeTimeStart,
                      onTap: () async {
                        final t = await showTimePicker(context: context, initialTime: _activeTimeStart);
                        if (t != null) setState(() => _activeTimeStart = t);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeButton(
                      label: 'Until',
                      time: _activeTimeEnd,
                      onTap: () async {
                        final t = await showTimePicker(context: context, initialTime: _activeTimeEnd);
                        if (t != null) setState(() => _activeTimeEnd = t);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Active Days
              const Text('Active Days', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'].map((day) {
                  final selected = _activeDays.contains(day);
                  return FilterChip(
                    label: Text(day.substring(0, 3).toUpperCase()),
                    selected: selected,
                    onSelected: (v) => setState(() => v ? _activeDays.add(day) : _activeDays.remove(day)),
                    selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: AppTheme.primaryColor,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Max Redemptions
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Max Redemptions (empty = unlimited)',
                  prefixIcon: Icon(Icons.people),
                ),
                onChanged: (v) => _maxRedemptions = int.tryParse(v),
              ),
              const SizedBox(height: 40),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _createPromotion,
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.rocket_launch),
                  label: Text(_isLoading ? 'Publishing...' : 'Publish Promotion'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _DiscountChip(String type, String label, IconData icon) {
    final selected = _discountType == type;
    return ChoiceChip(
      label: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16), const SizedBox(width: 4), Text(label)]),
      selected: selected,
      onSelected: (_) => setState(() => _discountType = type),
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateButton({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F2F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Text(DateFormat('MMM dd, yyyy').format(date), style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;
  const _TimeButton({required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F2F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Text(time.format(context), style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
