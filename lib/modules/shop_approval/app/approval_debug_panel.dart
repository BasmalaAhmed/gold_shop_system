import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gold_shop_app/modules/shop_approval/features/approvals/data/mock_approval_api.dart';
import 'package:gold_shop_app/modules/shop_approval/features/approvals/presentation/manager/approval_requests_cubit/approval_requests_cubit.dart';
import 'package:gold_shop_app/modules/shop_approval/features/approvals/presentation/manager/approval_requests_cubit/approval_requests_state.dart';
import 'package:gold_shop_app/modules/shop_approval/features/approvals/presentation/utils/approval_request_presentation.dart';

class ApprovalDebugPanel extends StatelessWidget {
  const ApprovalDebugPanel({super.key, required this.api});

  final MockApprovalApi api;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ApprovalRequestsCubit>();

    return Material(
      color: const Color(0xA6000000),
      borderRadius: BorderRadius.circular(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.bolt_rounded, color: Colors.white),
            onPressed: () {
              final state = cubit.state;
              if (state is! ApprovalRequestsSuccess) return;

              final id = cubit.viewingRequestId ?? 4;
              final request = state.requests
                  .where((item) => item.requestId == id)
                  .firstOrNull;

              if (request == null || !request.isPending) return;

              api.simulateExternalChange(
                id,
                amountInPiastres: request.amountInPiastres + 50000,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: cubit.refreshRequests,
          ),
        ],
      ),
    );
  }
}