import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gold_shop_app/modules/shop_approval/core/connectivity/connectivity_cubit.dart';
import 'package:gold_shop_app/modules/shop_approval/features/approvals/presentation/manager/approval_requests_cubit/approval_requests_cubit.dart';

class AutoRefresh extends StatefulWidget {
  const AutoRefresh({super.key, required this.child, this.active = true});

  final Widget child;
  final bool active;

  @override
  State<AutoRefresh> createState() => _AutoRefreshState();
}

class _AutoRefreshState extends State<AutoRefresh> with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.active) _startTimer();
  }

  @override
  void didUpdateWidget(covariant AutoRefresh oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active == oldWidget.active) return;

    if (widget.active) {
      _startTimer();
      _refresh();
    } else {
      _stopTimer();
    }
  }

  @override
  void dispose() {
    _stopTimer();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _refresh());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.active) _refresh();
  }

  void _refresh() {
    if (!mounted) return;
    context.read<ApprovalRequestsCubit>().refreshRequests();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConnectivityCubit, bool>(
      listenWhen: (previous, current) => !previous && current,
      listener: (context, _) {
        if (widget.active) _refresh();
      },
      child: widget.child,
    );
  }
}
