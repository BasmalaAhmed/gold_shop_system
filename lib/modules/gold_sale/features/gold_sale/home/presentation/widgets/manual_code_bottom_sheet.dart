import 'package:flutter/material.dart';
import 'package:gold_shop_app/core/unified_theme.dart';

class ManualCodeBottomSheet extends StatefulWidget {
  const ManualCodeBottomSheet({
    super.key,
    required this.onCodeSubmitted,
    this.onBackToScanner,
    this.isDialog = false,
  });

  final Function(String code) onCodeSubmitted;
  final VoidCallback? onBackToScanner;
  final bool isDialog;

  static void show(
    BuildContext context, {
    required Function(String code) onCodeSubmitted,
    VoidCallback? onBackToScanner,
  }) {
    final isTablet = MediaQuery.of(context).size.width >= 720;
    if (isTablet) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: ManualCodeBottomSheet(
              onCodeSubmitted: onCodeSubmitted,
              onBackToScanner: onBackToScanner,
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
          child: ManualCodeBottomSheet(
            onCodeSubmitted: onCodeSubmitted,
            onBackToScanner: onBackToScanner,
            isDialog: false,
          ),
        ),
      );
    }
  }

  @override
  State<ManualCodeBottomSheet> createState() => _ManualCodeBottomSheetState();
}

class _ManualCodeBottomSheetState extends State<ManualCodeBottomSheet> {
  final TextEditingController _codeController = TextEditingController(
    text: 'G-2207',
  );
  final List<String> _recentCodes = ['G-1042', 'G-2207', 'G-1301'];

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
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
            'إدخال كود القطعة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'كود القطعة',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 12, color: UnifiedTheme.textSecondary),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _codeController,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              suffixIcon: IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: UnifiedTheme.textSecondary,
                ),
                onPressed: () => _codeController.clear(),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: UnifiedTheme.teal,
                  width: 1.5,
                ),
              ),
              enabledBorder:OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: UnifiedTheme.border,
                  width: 1.5,
                ),
              ), 
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: UnifiedTheme.teal,
                  width: 2,
                ),
              ), 
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'الكود مكتوب على الكارت المعلق في القطعة',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 11, color: UnifiedTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          const Text(
            'آخر الأكواد',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 12, color: UnifiedTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: _recentCodes.map((code) {
              return Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: ActionChip(
                  label: Text(
                    code,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide.none,
                  ),
                  onPressed: () {
                    setState(() {
                      _codeController.text = code;
                    });
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                final code = _codeController.text.trim();
                if (code.isNotEmpty) {
                  Navigator.pop(context);
                  widget.onCodeSubmitted(code);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: UnifiedTheme.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: const Text(
                'إضافة القطعة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onBackToScanner?.call();
              },
              child: const Text(
                'رجوع لمسح الباركود',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: UnifiedTheme.teal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
