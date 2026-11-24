import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/manager/auth_cubit/auth_state.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/presentation/manager/approval_coordinator/approval_cubit.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/presentation/manager/approval_coordinator/approval_state.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/presentation/manager/pending_approval_manager.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/presentation/widgets/approval_request_coordinator_host.dart';

class MockAppLinks extends Mock implements AppLinks {}

class MockAuthCubit extends Mock implements AuthCubit {}

class MockApprovalCubit extends Mock implements ApprovalCubit {}

void main() {
  late MockAppLinks mockAppLinks;
  late MockAuthCubit mockAuthCubit;
  late MockApprovalCubit mockApprovalCubit;
  late PendingApprovalManager pendingApprovalManager;

  setUp(() {
    mockAppLinks = MockAppLinks();
    mockAuthCubit = MockAuthCubit();
    mockApprovalCubit = MockApprovalCubit();
    pendingApprovalManager = PendingApprovalManager();

    when(() => mockAuthCubit.state).thenReturn(const AuthInitial());
    when(() => mockAuthCubit.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockApprovalCubit.state).thenReturn(const ApprovalInitial());
    when(
      () => mockApprovalCubit.stream,
    ).thenAnswer((_) => const Stream.empty());
  });

  testWidgets('handles notification on cold start when app was closed', (
    tester,
  ) async {
    final initialUri = Uri.parse('myapp://approval/request_001');

    when(
      () => mockAppLinks.getInitialLink(),
    ).thenAnswer((_) async => initialUri);
    when(
      () => mockAppLinks.uriLinkStream,
    ).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: mockAuthCubit),
            BlocProvider<ApprovalCubit>.value(value: mockApprovalCubit),
          ],
          child: ApprovalRequestCoordinatorHost(
            appLinks: mockAppLinks,
            pendingApprovalManager: pendingApprovalManager,
            builder: (context, coordinator) =>
                const Scaffold(body: Text('Home')),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(pendingApprovalManager.hasPendingRequest, isTrue);
    expect(pendingApprovalManager.pendingRequestId, 'request_001');

    verify(() => mockAppLinks.getInitialLink()).called(1);
  });
}
