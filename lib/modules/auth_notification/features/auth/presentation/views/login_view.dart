import 'package:gold_shop_app/core/unified_theme.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/widgets/custom_text_form_field.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/widgets/error_message.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/widgets/header.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/widgets/login_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/entities/login_credentials.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/manager/auth_cubit/auth_state.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    context.read<AuthCubit>().login(
      LoginCredentials(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Header(),

                      const SizedBox(height: 36),

                      _buildLoginCard(isLoading: isLoading, state: state),

                      const SizedBox(height: 28),

                      const Text(
                        'مصادقة آمنة لحسابك',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard({required bool isLoading, required AuthState state}) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 30,
            offset: const Offset(0, 12),
            color: UnifiedTheme.primary.withValues(alpha: 0.1)
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'تسجيل الدخول',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'أدخل بياناتك',
              style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
            ),

            const SizedBox(height: 28),
            Text(
              'البريد الالكتروني',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),

            CustomTextFormField(
              controller: _emailController,
              isLoading: isLoading,
              onSubmitted: () {},
            ),

            const SizedBox(height: 22),

            Text(
              'كلمة المرور',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),

            CustomTextFormField(
              controller: _passwordController,
              isLoading: isLoading,
              isPassword: true,
              onSubmitted: _login,
            ),

            if (state is AuthFailure) ...[
              const SizedBox(height: 16),

              ErrorMessage(message: state.message),
            ],

            const SizedBox(height: 28),

            LoginButton(isLoading: isLoading, onPressed: _login),
          ],
        ),
      ),
    );
  }
}
