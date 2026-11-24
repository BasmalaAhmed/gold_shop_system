import 'package:flutter/material.dart';
import 'package:gold_shop_app/modules/gold_sale/core/theme/app_theme.dart';
import 'package:gold_shop_app/modules/gold_sale/core/utils/piaster_parser.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_calc.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/widgets/option_tab.dart';

class LaborPricingSelection {
  const LaborPricingSelection({required this.type, required this.value});

  final LaborPricingType type;
  final int value;
}

Future<LaborPricingSelection?> showLaborPricingDialog(
  BuildContext context, {
  LaborPricingType initialType = LaborPricingType.perGram,
  int? initialValue,
}) {
  final isTablet = MediaQuery.of(context).size.width >= 720;

  if (isTablet) {
    return showDialog<LaborPricingSelection>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: LaborPricingDialog(
            initialType: initialType,
            initialValue: initialValue,
            isDialog: true,
          ),
        ),
      ),
    );
  }

  return showModalBottomSheet<LaborPricingSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => LaborPricingDialog(
      initialType: initialType,
      initialValue: initialValue,
    ),
  );
}

class LaborPricingDialog extends StatefulWidget {
  const LaborPricingDialog({
    super.key,
    required this.initialType,
    this.initialValue,
    this.isDialog = false,
  });

  final LaborPricingType initialType;
  final int? initialValue;
  final bool isDialog;

  @override
  State<LaborPricingDialog> createState() => _LaborPricingDialogState();
}

class _LaborPricingDialogState extends State<LaborPricingDialog> {
  final _valueController = TextEditingController();

  late LaborPricingType _type;
  String? _error;

  @override
  void initState() {
    super.initState();

    _type = widget.initialType;

    if (widget.initialValue != null && widget.initialValue! > 0) {
      _valueController.text = _type == LaborPricingType.percentageOfGoldValue
          ? widget.initialValue.toString()
          : (widget.initialValue! / 100).toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  String get _label {
    switch (_type) {
      case LaborPricingType.perGram:
        return 'مصنعية لكل جرام';
      case LaborPricingType.percentageOfGoldValue:
        return 'نسبة من قيمة الذهب';
      case LaborPricingType.fixed:
        return 'مصنعية ثابتة للقطعة';
    }
  }

  String get _suffix {
    switch (_type) {
      case LaborPricingType.perGram:
        return 'ج.م / جرام';
      case LaborPricingType.percentageOfGoldValue:
        return '%';
      case LaborPricingType.fixed:
        return 'ج.م';
    }
  }

  void _submit() {
    final rawValue = _valueController.text.trim();

    final value = _type == LaborPricingType.percentageOfGoldValue
        ? int.tryParse(rawValue)
        : parsePiasters(rawValue);

    if (value == null || value < 0) {
      setState(() {
        _error = _type == LaborPricingType.percentageOfGoldValue
            ? 'أدخل نسبة صحيحة كعدد صحيح.'
            : 'أدخل مبلغًا صحيحًا بحد أقصى خانتين عشريتين.';
      });
      return;
    }

    Navigator.of(context).pop(LaborPricingSelection(type: _type, value: value));
  }

  void _changeType(LaborPricingType type) {
    if (_type == type) return;

    setState(() {
      _type = type;
      _valueController.clear();
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: widget.isDialog
            ? BorderRadius.circular(24)
            : const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isDialog) ...[
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
          ],
          const Text(
            'تحديد المصنعية',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              OptionTab(
                label: 'للجرام',
                isSelected: _type == LaborPricingType.perGram,
                onTap: () => _changeType(LaborPricingType.perGram),
              ),
              const SizedBox(width: 8),
              OptionTab(
                label: 'نسبة %',
                isSelected: _type == LaborPricingType.percentageOfGoldValue,
                onTap: () =>
                    _changeType(LaborPricingType.percentageOfGoldValue),
              ),
              const SizedBox(width: 8),
              OptionTab(
                label: 'ثابت',
                isSelected: _type == LaborPricingType.fixed,
                onTap: () => _changeType(LaborPricingType.fixed),
              ),
            ],
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _valueController,
            keyboardType: TextInputType.numberWithOptions(
              decimal: _type != LaborPricingType.percentageOfGoldValue,
            ),
            decoration: InputDecoration(labelText: _label, suffixText: _suffix),
            onChanged: (_) {
              if (_error != null) {
                setState(() => _error = null);
              }
            },
          ),

          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ],

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              'إضافة القطعة',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
