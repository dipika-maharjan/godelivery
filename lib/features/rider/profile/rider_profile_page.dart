import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/riders_repository.dart';
import '../../../models/rider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/sheet_header.dart';

class RiderProfilePage extends ConsumerStatefulWidget {
  const RiderProfilePage({super.key});

  @override
  ConsumerState<RiderProfilePage> createState() => _RiderProfilePageState();
}

class _RiderProfilePageState extends ConsumerState<RiderProfilePage> {
  Rider? _rider;
  BankAccount? _bankAccount;
  bool _loading = true;
  bool _acting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rider = await ref.read(ridersRepositoryProvider).getMe();
      BankAccount? bankAccount;
      try {
        bankAccount = await ref.read(ridersRepositoryProvider).getOwnBankAccount();
      } catch (_) {
        bankAccount = null;
      }
      if (!mounted) return;
      setState(() {
        _rider = rider;
        _bankAccount = bankAccount;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e is ApiException ? e.message : 'Something went wrong.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    if (_acting) return;
    setState(() => _acting = true);
    try {
      final updated = await ref.read(ridersRepositoryProvider).setAvailability(value);
      if (!mounted) return;
      setState(() => _rider = updated);
    } catch (e) {
      final message = e is ApiException ? e.message : 'Could not update availability.';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _editVehicle() async {
    final rider = _rider;
    if (rider == null) return;
    final result = await showModalBottomSheet<_VehicleEdit>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditVehicleSheet(rider: rider),
    );
    if (result == null) return;
    setState(() => _acting = true);
    try {
      final updated = await ref.read(ridersRepositoryProvider).updateMe(
            vehicleType: result.vehicleType,
            vehiclePlateNumber: result.plateNumber,
          );
      if (!mounted) return;
      setState(() => _rider = updated);
    } catch (e) {
      final message = e is ApiException ? e.message : 'Could not update vehicle info.';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _editBankAccount() async {
    final result = await showModalBottomSheet<_BankAccountEdit>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditBankAccountSheet(existing: _bankAccount),
    );
    if (result == null) return;
    setState(() => _acting = true);
    try {
      final updated = await ref.read(ridersRepositoryProvider).upsertOwnBankAccount(
            bankName: result.bankName,
            accountName: result.accountName,
            accountNumber: result.accountNumber,
            branch: result.branch,
          );
      if (!mounted) return;
      setState(() => _bankAccount = updated);
    } catch (e) {
      final message = e is ApiException ? e.message : 'Could not update bank details.';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          "You'll need to verify your phone number again to sign back in.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log out', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final rider = _rider;

    return SafeArea(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Text(
                    user?.name ?? 'Profile',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    user?.phoneNumber ?? '',
                    style: TextStyle(color: context.colors.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  if (rider != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: context.colors.cardAlt,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: rider.isAvailable,
                        onChanged: _acting ? null : _toggleAvailability,
                        title: const Text('Online for new deliveries', style: TextStyle(fontSize: 13.5)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoPill(icon: LucideIcons.bike, label: vehicleTypeLabel(rider.vehicleType)),
                        if (rider.vehiclePlateNumber != null)
                          _InfoPill(icon: LucideIcons.idCard, label: rider.vehiclePlateNumber!),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _acting ? null : _editVehicle,
                      child: const Text('Edit vehicle info'),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text('Bank account', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  if (_bankAccount != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.colors.card,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _bankAccount!.bankName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_bankAccount!.accountName} · ${_bankAccount!.accountNumber}',
                            style: TextStyle(fontSize: 12.5, color: context.colors.textMuted),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      'No bank account on file yet.',
                      style: TextStyle(color: context.colors.textMuted),
                    ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _acting ? null : _editBankAccount,
                    child: Text(_bankAccount == null ? 'Add bank account' : 'Edit bank account'),
                  ),
                  const SizedBox(height: 24),
                  const Text('Appearance', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  const _ThemeModeSelector(),
                  const SizedBox(height: 24),
                  _ActionTile(
                    icon: LucideIcons.logOut,
                    label: 'Log out',
                    destructive: true,
                    onTap: _confirmLogout,
                  ),
                ],
              ),
            ),
    );
  }
}

class _VehicleEdit {
  const _VehicleEdit({required this.vehicleType, this.plateNumber});

  final VehicleType vehicleType;
  final String? plateNumber;
}

class _EditVehicleSheet extends StatefulWidget {
  const _EditVehicleSheet({required this.rider});

  final Rider rider;

  @override
  State<_EditVehicleSheet> createState() => _EditVehicleSheetState();
}

class _EditVehicleSheetState extends State<_EditVehicleSheet> {
  late final _plateController =
      TextEditingController(text: widget.rider.vehiclePlateNumber);
  late VehicleType _vehicleType = widget.rider.vehicleType;

  @override
  void dispose() {
    _plateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHeader(title: 'Edit vehicle info'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: context.colors.cardAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<VehicleType>(
                  value: _vehicleType,
                  isExpanded: true,
                  items: [
                    for (final type in VehicleType.values)
                      DropdownMenuItem(value: type, child: Text(vehicleTypeLabel(type))),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _vehicleType = value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            AppTextField(controller: _plateController, label: 'Plate number'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(
                  _VehicleEdit(
                    vehicleType: _vehicleType,
                    plateNumber: _plateController.text.trim().isEmpty
                        ? null
                        : _plateController.text.trim(),
                  ),
                ),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BankAccountEdit {
  const _BankAccountEdit({
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    this.branch,
  });

  final String bankName;
  final String accountName;
  final String accountNumber;
  final String? branch;
}

class _EditBankAccountSheet extends StatefulWidget {
  const _EditBankAccountSheet({this.existing});

  final BankAccount? existing;

  @override
  State<_EditBankAccountSheet> createState() => _EditBankAccountSheetState();
}

class _EditBankAccountSheetState extends State<_EditBankAccountSheet> {
  late final _bankNameController = TextEditingController(text: widget.existing?.bankName);
  late final _accountNameController =
      TextEditingController(text: widget.existing?.accountName);
  late final _accountNumberController =
      TextEditingController(text: widget.existing?.accountNumber);
  late final _branchController = TextEditingController(text: widget.existing?.branch);

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _bankNameController.text.trim().isNotEmpty &&
      _accountNameController.text.trim().isNotEmpty &&
      _accountNumberController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHeader(title: 'Bank account'),
            const SizedBox(height: 12),
            AppTextField(controller: _bankNameController, label: 'Bank name'),
            const SizedBox(height: 12),
            AppTextField(controller: _accountNameController, label: 'Account holder name'),
            const SizedBox(height: 12),
            AppTextField(
              controller: _accountNumberController,
              label: 'Account number',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            AppTextField(controller: _branchController, label: 'Branch (optional)'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isValid
                    ? () => Navigator.of(context).pop(
                          _BankAccountEdit(
                            bankName: _bankNameController.text.trim(),
                            accountName: _accountNameController.text.trim(),
                            accountNumber: _accountNumberController.text.trim(),
                            branch: _branchController.text.trim().isEmpty
                                ? null
                                : _branchController.text.trim(),
                          ),
                        )
                    : null,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeModeSelector extends ConsumerWidget {
  const _ThemeModeSelector();

  static const _options = [
    (ThemeMode.system, 'System', LucideIcons.smartphone),
    (ThemeMode.light, 'Light', LucideIcons.sun),
    (ThemeMode.dark, 'Dark', LucideIcons.moon),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(themeModeProvider);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          for (final (mode, label, icon) in _options)
            Expanded(
              child: InkWell(
                onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(mode),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected == mode ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        icon,
                        size: 16,
                        color: selected == mode ? AppColors.onPrimary : context.colors.text,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: selected == mode ? AppColors.onPrimary : context.colors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.cardAlt,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.colors.text),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.danger : context.colors.text;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: context.colors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            ),
            Icon(LucideIcons.chevronRight, size: 16, color: context.colors.textMuted),
          ],
        ),
      ),
    );
  }
}
