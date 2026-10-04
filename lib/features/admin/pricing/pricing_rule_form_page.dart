import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/pricing_rules_repository.dart';
import '../../../models/pricing_rule.dart';
import '../../../providers/pricing_rules_provider.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/primary_button.dart';

/// Create or edit a pricing rule (`POST`/`PATCH /pricing-rules`).
class PricingRuleFormPage extends ConsumerStatefulWidget {
  const PricingRuleFormPage({super.key, this.existing});

  final PricingRule? existing;

  @override
  ConsumerState<PricingRuleFormPage> createState() => _PricingRuleFormPageState();
}

class _PricingRuleFormPageState extends ConsumerState<PricingRuleFormPage> {
  late final _nameController = TextEditingController(text: widget.existing?.name);
  late final _baseFareController =
      TextEditingController(text: widget.existing?.baseFare);
  late final _ratePerKgController =
      TextEditingController(text: widget.existing?.ratePerKg);
  late final _ratePerKmController =
      TextEditingController(text: widget.existing?.ratePerKm);
  late final _surchargeController =
      TextEditingController(text: widget.existing?.dangerousGoodsSurcharge ?? '0');
  late final _minChargeController =
      TextEditingController(text: widget.existing?.minCharge);
  late final _currencyController =
      TextEditingController(text: widget.existing?.currency ?? 'NPR');

  DateTime? _effectiveFrom;
  DateTime? _effectiveTo;
  bool _isActive = true;
  bool _submitting = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _effectiveFrom = existing.effectiveFrom;
      _effectiveTo = existing.effectiveTo;
      _isActive = existing.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseFareController.dispose();
    _ratePerKgController.dispose();
    _ratePerKmController.dispose();
    _surchargeController.dispose();
    _minChargeController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _nameController.text.trim().isNotEmpty &&
      double.tryParse(_baseFareController.text.trim()) != null &&
      double.tryParse(_ratePerKgController.text.trim()) != null &&
      double.tryParse(_ratePerKmController.text.trim()) != null &&
      double.tryParse(_minChargeController.text.trim()) != null;

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _effectiveFrom : _effectiveTo) ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _effectiveFrom = picked;
      } else {
        _effectiveTo = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_isValid || _submitting) return;
    setState(() => _submitting = true);
    try {
      final repo = ref.read(pricingRulesRepositoryProvider);
      final name = _nameController.text.trim();
      final baseFare = double.parse(_baseFareController.text.trim());
      final ratePerKg = double.parse(_ratePerKgController.text.trim());
      final ratePerKm = double.parse(_ratePerKmController.text.trim());
      final surcharge = double.tryParse(_surchargeController.text.trim()) ?? 0;
      final minCharge = double.parse(_minChargeController.text.trim());
      final currency = _currencyController.text.trim().isEmpty
          ? null
          : _currencyController.text.trim();
      final effectiveFrom = _effectiveFrom == null
          ? null
          : DateFormat('yyyy-MM-dd').format(_effectiveFrom!);
      final effectiveTo = _effectiveTo == null
          ? null
          : DateFormat('yyyy-MM-dd').format(_effectiveTo!);
      if (_isEditing) {
        await repo.update(
          widget.existing!.id,
          name: name,
          baseFare: baseFare,
          ratePerKg: ratePerKg,
          ratePerKm: ratePerKm,
          dangerousGoodsSurcharge: surcharge,
          minCharge: minCharge,
          currency: currency,
          isActive: _isActive,
          effectiveFrom: effectiveFrom,
          effectiveTo: effectiveTo,
        );
      } else {
        await repo.create(
          name: name,
          baseFare: baseFare,
          ratePerKg: ratePerKg,
          ratePerKm: ratePerKm,
          dangerousGoodsSurcharge: surcharge,
          minCharge: minCharge,
          currency: currency,
          isActive: _isActive,
          effectiveFrom: effectiveFrom,
          effectiveTo: effectiveTo,
        );
      }
      await ref.read(pricingRulesProvider.notifier).refresh();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      final message = e is ApiException
          ? e.message
          : 'Could not save the pricing rule. Please try again.';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit pricing rule' : 'New pricing rule'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              controller: _nameController,
              label: 'Name',
              hint: 'e.g. Standard rate',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _baseFareController,
                    label: 'Base fare',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppTextField(
                    controller: _minChargeController,
                    label: 'Minimum charge',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _ratePerKgController,
                    label: 'Rate per kg',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppTextField(
                    controller: _ratePerKmController,
                    label: 'Rate per km',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _surchargeController,
                    label: 'Dangerous-goods surcharge',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppTextField(
                    controller: _currencyController,
                    label: 'Currency',
                    hint: 'NPR',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Effective from',
                    date: _effectiveFrom,
                    onTap: () => _pickDate(isFrom: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateField(
                    label: 'Effective to (optional)',
                    date: _effectiveTo,
                    onTap: () => _pickDate(isFrom: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: context.colors.cardAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                title: const Text('Active', style: TextStyle(fontSize: 13.5)),
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: _isEditing ? 'Save changes' : 'Create pricing rule',
              enabled: _isValid,
              loading: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.date, required this.onTap});

  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: context.colors.cardAlt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              date == null ? 'Not set' : DateFormat('MMM d, y').format(date!),
              style: TextStyle(
                fontSize: 13.5,
                color: date != null ? context.colors.text : context.colors.textMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
