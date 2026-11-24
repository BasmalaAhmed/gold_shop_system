import 'package:gold_shop_app/modules/auth_notification/core/session/session_manager.dart';
import 'package:gold_shop_app/modules/auth_notification/core/utils/date_formatter.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/manager/auth_cubit/auth_state.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/widgets/info_card.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/widgets/mock_deep_link_button.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/widgets/status_card.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/widgets/welcome_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeView extends StatelessWidget {
  final SessionManager sessionManager;
  final bool Function(Uri uri) onDeepLink;

  const HomeView({
    super.key,
    required this.sessionManager,
    required this.onDeepLink,
  });

  static const Color primaryColor = Color(0xFF1E293B);
  static const Color accentColor = Color(0xFF0D9488);
  @override
  Widget build(BuildContext context) {
    final session = sessionManager.currentSession;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'الحساب',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              return IconButton(
                onPressed: () => context.read<AuthCubit>().logout(),
                tooltip: 'تسجيل الخروج',
                icon: const Icon(Icons.logout_rounded,),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WelcomeSection(),
              const SizedBox(height: 28),
              const Text(
                'نظرة عامة على الحساب',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              StatusCard(isSessionValid: sessionManager.hasValidSession),
              const SizedBox(height: 24),
              const Text(
                'معلومات الجلسة',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (session != null) ...[
                InfoCard(
                  title: 'تنتهي الجلسة في',
                  value: formatDate(session.expiresAt),
                  icon: Icons.access_time_rounded,
                ),
                const SizedBox(height: 12),
                InfoCard(
                  title: 'رمز الوصول',
                  value: 'متاح',
                  icon: Icons.key_rounded,
                ),
                const SizedBox(height: 12),
                InfoCard(
                  title: 'رمز التحديث',
                  value: 'مؤمَّن',
                  icon: Icons.lock_outline_rounded,
                ),
              ] else
                const Text('لم يتم العثور على جلسة نشطة.'),
              const SizedBox(height: 28),
              MockDeepLinkButton(
                onPressed: () {
                  final accepted = onDeepLink(
                    Uri.parse('myapp://approval/request_001'),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        accepted
                            ? 'تم استلام رابط الموافقة.'
                            : 'رابط الموافقة غير صالح.',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
