import 'package:flutter/material.dart';
import 'package:gold_shop_app/core/unified_theme.dart';
import 'package:gold_shop_app/modules/gold_sale/core/utils/price_formatter.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_trade_in.dart';

class ScrapGoldBottomSheet extends StatefulWidget {
  const ScrapGoldBottomSheet({
    super.key,
    required this.onApply,
    this.initialKarat = 21,
    this.buyPricePerGramPiasters = 405000,
    this.isDialog = false,
  });

  final Function(int weightMg, int karat, int deductionBasisPoints) onApply;
  final int initialKarat;
  final int buyPricePerGramPiasters;
  final bool isDialog;

  static void show(
    BuildContext context, {
    required Function(int weightMg, int karat, int deductionBasisPoints)
    onApply,
    int initialKarat = 21,
    int buyPricePerGramPiasters = 405000,
  }) {
    final isTablet = MediaQuery.of(context).size.width >= 720;
    if (isTablet) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ScrapGoldBottomSheet(
              onApply: onApply,
              initialKarat: initialKarat,
              buyPricePerGramPiasters: buyPricePerGramPiasters,
              isDialog: true,
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ScrapGoldBottomSheet(
            onApply: onApply,
            initialKarat: initialKarat,
            buyPricePerGramPiasters: buyPricePerGramPiasters,
            isDialog: false,
          ),
        ),
      );
    }
  }

  @override
  State<ScrapGoldBottomSheet> createState() => _ScrapGoldBottomSheetState();
}

class _ScrapGoldBottomSheetState extends State<ScrapGoldBottomSheet> {
  final TextEditingController _weightController = TextEditingController(
    text: '3',
  );
  final TextEditingController _deductionController = TextEditingController(
    text: '2.5',
  );
  late int _selectedKarat;

  @override
  void initState() {
    super.initState();
    _selectedKarat = widget.initialKarat;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _deductionController.dispose();
    super.dispose();
  }

  int get _weightMg {
    final clean = _weightController.text.replaceAll(',', '').trim();
    final weightInGrams = double.tryParse(clean) ?? 3.0;
    return (weightInGrams * 1000).round();
  }

  double get _deductionPercent {
    return double.tryParse(_deductionController.text.trim()) ?? 2.5;
  }

  int get _deductionBasisPoints => (_deductionPercent * 100).round();

  @override
  Widget build(BuildContext context) {
    TradeInResult? result;
    try {
      result = const TradeInCalc().calculate(
        TradeInInput(
          weightMg: _weightMg,
          karat: _selectedKarat,
          buyPricePerGramPiasters: widget.buyPricePerGramPiasters,
          deductionBasisPoints: _deductionBasisPoints,
        ),
      );
    } catch (_) {}

    final valueEgp = PriceFormatter.formatPiasters(result?.valuePiasters ?? 0);

    final goldValueEgp = PriceFormatter.formatPiasters(
      result?.goldValuePiasters ?? 0,
    );

    final deductionEgp = PriceFormatter.formatPiasters(
      result?.deductionPiasters ?? 0,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: widget.isDialog
            ? BorderRadius.circular(24)
            : const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          Text(
            'بدل (ذهب قديم)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text(
            'الوزن',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 12, color: UnifiedTheme.textSecondary),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _weightController,
            textAlign: TextAlign.right,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              suffixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text(
                  'جم',
                  style: TextStyle(
                    color: UnifiedTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: UnifiedTheme.teal,
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: UnifiedTheme.textSecondary,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: UnifiedTheme.teal,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'العيار',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 12, color: UnifiedTheme.textSecondary),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildKaratTab(18),
              const SizedBox(width: 8),
              _buildKaratTab(21),
              const SizedBox(width: 8),
              _buildKaratTab(24),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'خصم من قيمة الذهب',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 12, color: UnifiedTheme.textSecondary),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _deductionController,
            textAlign: TextAlign.right,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              suffixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Text(
                  '%',
                  style: TextStyle(
                    color: UnifiedTheme.textSecondary,
                    fontSize: 15,
                  ),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: UnifiedTheme.teal,
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: UnifiedTheme.textSecondary,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: UnifiedTheme.teal,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSummaryRow('قيمة الذهب', '$goldValueEgp ج.م'),
                const SizedBox(height: 8),
                _buildSummaryRow(
                  'قيمة الخصم (${_deductionPercent.toStringAsFixed(1)}%)',
                  '$deductionEgp ج.م',
                  valueColor: Colors.red,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1),
                ),
                _buildSummaryRow(
                  'معادلة حساب البدل',
                  'قيمة الذهب - '
                      'قيمة الخصم',
                  valueColor: UnifiedTheme.textSecondary,
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'قيمة البدل',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: UnifiedTheme.emerald,
                      ),
                    ),
                    Text(
                      '$valueEgp ج.م',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: UnifiedTheme.emerald,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                widget.onApply(
                  _weightMg,
                  _selectedKarat,
                  _deductionBasisPoints,
                );
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check, size: 18),
              label: const Text(
                'إضافة البدل',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: UnifiedTheme.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKaratTab(int karat) {
    final bool isSelected = _selectedKarat == karat;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedKarat = karat),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: isSelected ? UnifiedTheme.teal : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            '$karat',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : UnifiedTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String title,
    String value, {
    Color valueColor = UnifiedTheme.textPrimary,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            color: UnifiedTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
