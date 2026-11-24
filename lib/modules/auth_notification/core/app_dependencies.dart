import 'package:gold_shop_app/modules/auth_notification/core/api/api_request_executor.dart';
import 'package:gold_shop_app/modules/auth_notification/core/security/secure_storage_service.dart';
import 'package:gold_shop_app/modules/auth_notification/core/session/repos/session_repo_impl.dart';
import 'package:gold_shop_app/modules/auth_notification/core/session/session_manager.dart';
import 'package:gold_shop_app/modules/auth_notification/core/session/data/datasources/mock_session_api.dart';
import 'package:gold_shop_app/modules/auth_notification/core/session/data/repos/session_refresh_repo_impl.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/data/datasources/mock_auth_api.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/data/repos/auth_repo_impl.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/usecases/login_usecase.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/domain/usecases/verify_device_usecase.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/data/datasources/mock_approval_api.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/data/repos/approval_request_repo_impl.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/domain/usecases/get_approval_request_usecase.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/presentation/manager/approval_coordinator/approval_cubit.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/presentation/manager/pending_approval_manager.dart';

class AppDependencies {
  final SessionManager sessionManager;

  final LoginUseCase loginUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;
  final VerifyDeviceUseCase verifyDeviceUseCase;

  final GetApprovalRequestUseCase getApprovalRequestUseCase;

  final PendingApprovalManager pendingApprovalManager;

  AppDependencies({
    required this.sessionManager,
    required this.loginUseCase,
    required this.verifyOtpUseCase,
    required this.verifyDeviceUseCase,
    required this.getApprovalRequestUseCase,
    required this.pendingApprovalManager,
  });

  static Future<AppDependencies> create() async {
    final secureStorageService = SecureStorageService();

    final sessionRepo = SessionRepoImpl(secureStorageService);

    final mockSessionApi = MockSessionApi();

    final sessionRefreshRepo = SessionRefreshRepoImpl(mockSessionApi);

    final sessionManager = SessionManager(sessionRepo, sessionRefreshRepo);

    await sessionManager.initialize();

    final mockAuthApi = MockAuthApi();

    final authRepo = AuthRepoImpl(mockAuthApi);

    final loginUseCase = LoginUseCase(authRepo);
    final verifyOtpUseCase = VerifyOtpUseCase(authRepo);
    final verifyDeviceUseCase = VerifyDeviceUseCase(authRepo);

    final apiRequestExecutor = ApiRequestExecutor(sessionManager);

    final mockApprovalApi = MockApprovalApi();

    final approvalRequestRepo = ApprovalRequestRepoImpl(
      mockApprovalApi,
      apiRequestExecutor,
    );

    final getApprovalRequestUseCase = GetApprovalRequestUseCase(
      approvalRequestRepo,
    );

    return AppDependencies(
      sessionManager: sessionManager,
      loginUseCase: loginUseCase,
      verifyOtpUseCase: verifyOtpUseCase,
      verifyDeviceUseCase: verifyDeviceUseCase,
      getApprovalRequestUseCase: getApprovalRequestUseCase,
      pendingApprovalManager: PendingApprovalManager(),
    );
  }

  AuthCubit createAuthCubit() {
    return AuthCubit(
      loginUseCase: loginUseCase,
      verifyOtpUseCase: verifyOtpUseCase,
      verifyDeviceUseCase: verifyDeviceUseCase,
      sessionManager: sessionManager,
    );
  }

  ApprovalCubit createApprovalCubit() {
    return ApprovalCubit(getApprovalRequestUseCase: getApprovalRequestUseCase);
  }
}
