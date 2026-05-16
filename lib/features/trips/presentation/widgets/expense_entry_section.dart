import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/trip_entry_model.dart';

/// Expense input form with live auto-calculation.
///
/// Shows: Distance, Fuel Rate, Mileage → auto-calculates Fuel Expense.
/// Optional: Toll, Parking, Other.
/// At the bottom: a read-only summary row (Total & Per Person).
class ExpenseEntrySection extends StatefulWidget {
  const ExpenseEntrySection({
    super.key,
    required this.formState,
    required this.onDistanceChanged,
    required this.onFuelRateChanged,
    required this.onMileageChanged,
    required this.onTollChanged,
    required this.onParkingChanged,
    required this.onOtherChanged,
  });

  final TripFormState formState;
  final ValueChanged<double> onDistanceChanged;
  final ValueChanged<double> onFuelRateChanged;
  final ValueChanged<double> onMileageChanged;
  final ValueChanged<double> onTollChanged;
  final ValueChanged<double> onParkingChanged;
  final ValueChanged<double> onOtherChanged;

  @override
  State<ExpenseEntrySection> createState() => _ExpenseEntrySectionState();
}

class _ExpenseEntrySectionState extends State<ExpenseEntrySection> {
  late final TextEditingController _distCtrl;
  late final TextEditingController _rateCtrl;
  late final TextEditingController _mileageCtrl;
  late final TextEditingController _tollCtrl;
  late final TextEditingController _parkCtrl;
  late final TextEditingController _otherCtrl;

  bool _showOptional = false;

  @override
  void initState() {
    super.initState();
    final f = widget.formState;
    _distCtrl = TextEditingController(
        text: _fmt(f.distanceKm));
    _rateCtrl = TextEditingController(
        text: _fmt(f.fuelRatePerLitre));
    _mileageCtrl = TextEditingController(
        text: _fmt(f.mileageKmpl));
    _tollCtrl = TextEditingController(
        text: f.tollExpense > 0 ? _fmt(f.tollExpense) : '');
    _parkCtrl = TextEditingController(
        text: f.parkingExpense > 0 ? _fmt(f.parkingExpense) : '');
    _otherCtrl = TextEditingController(
        text: f.otherExpense > 0 ? _fmt(f.otherExpense) : '');
  }

  @override
  void dispose() {
    for (final c in [
      _distCtrl, _rateCtrl, _mileageCtrl,
      _tollCtrl, _parkCtrl, _otherCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  double _parse(String text) => double.tryParse(text) ?? 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final f = widget.formState;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Text(
          'Expenses',
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.md),

        // Core inputs
        Row(
          children: [
            Expanded(
              child: _NumField(
                controller: _distCtrl,
                label: 'Distance (km)',
                suffix: 'km',
                onChanged: (v) => widget.onDistanceChanged(_parse(v)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _NumField(
                controller: _rateCtrl,
                label: 'Fuel rate',
                prefix: '₹',
                suffix: '/L',
                onChanged: (v) => widget.onFuelRateChanged(_parse(v)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _NumField(
                controller: _mileageCtrl,
                label: 'Mileage',
                suffix: 'km/L',
                onChanged: (v) => widget.onMileageChanged(_parse(v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Auto-calculated fuel
        _CalcRow(
          icon: Icons.local_gas_station_rounded,
          label: 'Fuel expense',
          value: f.fuelExpense,
          color: colorScheme.primary,
        ),
        const Divider(height: AppSpacing.xl),

        // Optional extras toggle
        GestureDetector(
          onTap: () => setState(() => _showOptional = !_showOptional),
          child: Row(
            children: [
              Icon(
                _showOptional
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                _showOptional
                    ? 'Hide extras'
                    : 'Add toll / parking / other',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Optional inputs (animated)
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: _showOptional
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: _NumField(
                          controller: _tollCtrl,
                          label: 'Toll',
                          prefix: '₹',
                          onChanged: (v) =>
                              widget.onTollChanged(_parse(v)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _NumField(
                          controller: _parkCtrl,
                          label: 'Parking',
                          prefix: '₹',
                          onChanged: (v) =>
                              widget.onParkingChanged(_parse(v)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _NumField(
                          controller: _otherCtrl,
                          label: 'Other',
                          prefix: '₹',
                          onChanged: (v) =>
                              widget.onOtherChanged(_parse(v)),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Summary card
        _SummaryCard(formState: f),
      ],
    );
  }
}

// ── Numeric input field ────────────────────────────────────────────────────────

class _NumField extends StatelessWidget {
  const _NumField({
    required this.controller,
    required this.label,
    this.prefix,
    this.suffix,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? prefix;
  final String? suffix;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
      ],
      onChanged: onChanged,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        suffixText: suffix,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

// ── Calculated row ─────────────────────────────────────────────────────────────

class _CalcRow extends StatelessWidget {
  const _CalcRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Text(
          '₹${value.toStringAsFixed(0)}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

// ── Summary card ───────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.formState});

  final TripFormState formState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final count = formState.attendees.length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withAlpha(80),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: colorScheme.primary.withAlpha(50),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total expense',
                    style: theme.textTheme.labelSmall),
                Text(
                  '₹${formState.totalExpense.toStringAsFixed(0)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Container(
              width: 1,
              height: 36,
              color: colorScheme.outline.withAlpha(80)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Per person ($count)',
                  style: theme.textTheme.labelSmall,
                ),
                Text(
                  count == 0
                      ? '—'
                      : '₹${formState.perPersonShare.toStringAsFixed(0)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
