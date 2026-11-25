import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/domain/entities/approval_request.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/presentation/manager/approval_coordinator/approval_cubit.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/presentation/manager/approval_coordinator/approval_state.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/presentation/manager/approval_request_coordinator.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/presentation/manager/pending_approval_manager.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/presentation/views/approval_request_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ApprovalRequestCoordinatorHost extends StatefulWidget {
  final PendingApprovalManager pendingApprovalManager;
  final AppLinks appLinks;
  final Widget Function(
    BuildContext context,
    ApprovalRequestCoordinator coordinator,
  )
  builder;
  const ApprovalRequestCoordinatorHost({
    super.key,
    required this.pendingApprovalManager,
    required this.builder,
    required this.appLinks,
  });

  @override
  State<ApprovalRequestCoordinatorHost> createState() =>
      _ApprovalRequestCoordinatorHostState();
}

class _ApprovalRequestCoordinatorHostState
    extends State<ApprovalRequestCoordinatorHost> {
  late final ApprovalRequestCoordinator _coordinator;
  late final StreamSubscription<Uri> _linkSubscription;

  @override
  void initState() {
    super.initState();

    _coordinator = ApprovalRequestCoordinator(
      authCubit: context.read<AuthCubit>(),
      approvalCubit: context.read<ApprovalCubit>(),
      pendingApprovalManager: widget.pendingApprovalManager,
      onRequestReady: _openApprovalRequest,
    );

    widget.appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _coordinator.handleLink(uri);
      }
    });

    _linkSubscription = widget.appLinks.uriLinkStream.listen((uri) {
      _coordinator.handleLink(uri);
    });
  }

  Future<void> _openApprovalRequest(ApprovalRequest request) async {
    if (!mounted) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => ApprovalRequestView(request: request)),
    );
  }

  @override
  void dispose() {
    unawaited(_coordinator.dispose());
    unawaited(_linkSubscription.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ApprovalCubit, ApprovalState>(
      listenWhen: (previous, current) => current is ApprovalFailure,
      listener: (context, state) {
        if (state is! ApprovalFailure) return;

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(state.message),
              action: SnackBarAction(
                label: 'إعادة المحاولة',
                onPressed: () => unawaited(_coordinator.retryPendingRequest()),
              ),
            ),
          );
      },
      child: widget.builder(context, _coordinator),
    );
  }
}
