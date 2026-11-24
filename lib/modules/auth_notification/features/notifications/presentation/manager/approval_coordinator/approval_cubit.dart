import 'package:gold_shop_app/modules/auth_notification/features/notifications/domain/entities/approval_request.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/domain/usecases/get_approval_request_usecase.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/presentation/manager/approval_coordinator/approval_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ApprovalCubit extends Cubit<ApprovalState> {
  final GetApprovalRequestUseCase getApprovalRequestUseCase;

  bool _isProcessing = false;
  int _requestVersion = 0;

  ApprovalCubit({required this.getApprovalRequestUseCase})
    : super(const ApprovalInitial());

  Future<ApprovalRequest?> fetchRequest({required String requestId}) async {
    if (isClosed || _isProcessing) return null;
    if (_isProcessing) return null;

    _isProcessing = true;
    final requestVersion = ++_requestVersion;

    emit(const ApprovalLoading());

    try {
      final request = await getApprovalRequestUseCase(requestId: requestId);

      if (isClosed || requestVersion != _requestVersion) {
        return null;
      }

      emit(ApprovalLoaded(request));

      return request;
    } catch (_) {
      if (!isClosed && requestVersion == _requestVersion) {
        emit(const ApprovalFailure('تعذر تحميل طلب الموافقة.'));
      }

      return null;
    } finally {
      if (requestVersion == _requestVersion) {
        _isProcessing = false;
      }
    }
  }

  void reset() {
    if (isClosed) return;

    _requestVersion++;
    _isProcessing = false;

    emit(const ApprovalInitial());
  }
}
