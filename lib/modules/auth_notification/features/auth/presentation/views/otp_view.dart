import 'package:gold_shop_app/core/unified_theme.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/widgets/code_text_field.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/widgets/error_message.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/widgets/icon_widget.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/widgets/verify_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/entities/otp_challenge.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/manager/auth_cubit/auth_state.dart';

class OtpView extends StatefulWidget {
  final OtpChallenge challenge;

  const OtpView({super.key, required this.challenge});

  @override
  State<OtpView> createState() => _OtpViewState();
}

class _OtpViewState extends State<OtpView> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();


  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _verifyOtp() {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    context.read<AuthCubit>().verifyOtp(_codeController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;
                  final errorMessage = state is AuthOtpRequired
                      ? state.errorMessage
                      : null;
                  return Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: UnifiedTheme.primary.withValues(alpha: 0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          IconWidget(icon: Icons.mark_email_read_outlined),
                          const SizedBox(height: 28),
                          const Text(
                            'قم بتأكيد بريدك الالكتروني',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'رمز التأكيد تم ارساله للبريد الالكتروني',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.challenge.maskedDestination,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: UnifiedTheme.teal,
                            ),
                          ),
                          const SizedBox(height: 36),
                          CodeTextField(
                            codeController: _codeController,
                            isLoading: isLoading,
                          ),
                          if (errorMessage != null) ...[
                            const SizedBox(height: 16),
                            ErrorMessage(message: errorMessage),
                          ],
                          const SizedBox(height: 28),
                          VerifyButton(
                            isLoading: isLoading,
                            onPressed: _verifyOtp,
                            title: 'تأكيد الرمز',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
