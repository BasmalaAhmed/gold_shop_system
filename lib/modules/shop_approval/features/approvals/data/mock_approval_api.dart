import 'package:gold_shop_app/modules/shop_approval/features/approvals/data/approval_api.dart';
import 'package:gold_shop_app/modules/shop_approval/features/approvals/data/approval_api_exception.dart';
import 'package:gold_shop_app/modules/shop_approval/features/approvals/data/mock_api_scenario.dart';
import 'package:gold_shop_app/modules/shop_approval/models/approval_decision.dart';
import 'package:gold_shop_app/modules/shop_approval/models/approval_decision_command.dart';
import 'package:gold_shop_app/modules/shop_approval/models/approval_decision_result.dart';
import 'package:gold_shop_app/modules/shop_approval/models/approval_request.dart';

class MockApprovalApi implements ApprovalApi {
  MockApprovalApi({
    required List<ApprovalRequest> initialRequests,
    this.scenario = MockApiScenario.normal,
    this.responseDelay = const Duration(milliseconds: 300),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       _requests = {
         for (final request in initialRequests) request.requestId: request,
       };

  MockApiScenario scenario;
  final Duration responseDelay;
  final Map<int, ApprovalRequest> _requests;
  final Map<String, _ProcessedDecision> _processedDecisions = {};
  final DateTime Function() _now;

  @override
  Future<List<ApprovalRequest>> fetchRequests() async {
    await Future.delayed(responseDelay);

    return List<ApprovalRequest>.unmodifiable(_requests.values);
  }

  @override
  Future<ApprovalDecisionResult?> findDecisionById(String decisionId) async {
    await Future.delayed(responseDelay);

    return _processedDecisions[decisionId]?.result;
  }

  @override
  Future<ApprovalDecisionResult> submitDecision(
    ApprovalDecisionCommand command,
  ) async {
    await Future.delayed(responseDelay);

    final previous = _processedDecisions[command.decisionId];

    if (previous != null) {
      final sameCommand =
          previous.command.requestId == command.requestId &&
          previous.command.expectedVersion == command.expectedVersion &&
          previous.command.decision == command.decision;

      if (!sameCommand) {
        throw DecisionIdReusedException(command.decisionId);
      }

      return previous.result;
    }

    if (scenario == MockApiScenario.failBeforeExecution) {
      throw const MockApiNetworkException('Request failed before execution');
    }

    final currentRequest = _requests[command.requestId];

    if (currentRequest == null) {
      throw ApprovalRequestNotFoundException(command.requestId);
    }

    final ApprovalDecisionResult result;

    if (currentRequest.version != command.expectedVersion ||
        currentRequest.status != ApprovalStatus.pending) {
      result = ApprovalDecisionResult(
        request: currentRequest,
        outcome: ApprovalDecisionOutcome.versionConflict,
      );
    } else {
      final updatedRequest = currentRequest.copyWith(
        version: currentRequest.version + 1,
        status: command.decision == ApprovalDecision.approve
            ? ApprovalStatus.approved
            : ApprovalStatus.rejected,
        lastDecision: command.decision,
        decidedAt: _now(),
        executedAsEmployee: command.decision == ApprovalDecision.approve
            ? currentRequest.employeeName
            : null,
      );

      _requests[command.requestId] = updatedRequest;

      result = ApprovalDecisionResult(
        request: updatedRequest,
        outcome: ApprovalDecisionOutcome.applied,
      );
    }

    _processedDecisions[command.decisionId] = _ProcessedDecision(
      command: command,
      result: result,
    );

    if (scenario == MockApiScenario.loseResponseAfterExecution &&
        result.outcome == ApprovalDecisionOutcome.applied) {
      throw const MockApiNetworkException('Response was lost after execution');
    }

    return result;
  }

  @override
  Future<ApprovalRequest> createRequest({
    required String employeeName,
    required String branchName,
    required int amountInPiastres,
    required String reason,
    String? attentionMessage,
  }) async {
    await Future.delayed(responseDelay);

    if (scenario == MockApiScenario.failBeforeExecution) {
      throw const MockApiNetworkException('Request failed before execution');
    }

    final nextId = _requests.keys.isEmpty
        ? 1
        : _requests.keys.reduce((a, b) => a > b ? a : b) + 1;

    final request = ApprovalRequest(
      requestId: nextId,
      employeeName: employeeName,
      branchName: branchName,
      amountInPiastres: amountInPiastres,
      reason: reason,
      version: 1,
      status: ApprovalStatus.pending,
      attentionMessage: attentionMessage,
      requestedAt: _now(),
    );
    _requests[nextId] = request;
    return request;
  }

  void simulateExternalChange(
    int requestId, {
    int? amountInPiastres,
    String? attentionMessage,
  }) {
    final current = _requests[requestId];
    if (current == null) throw ApprovalRequestNotFoundException(requestId);

    _requests[requestId] = current.copyWith(
      version: current.version + 1,
      amountInPiastres: amountInPiastres,
      attentionMessage: attentionMessage,
    );
  }

  @override
  Future<void> cancelRequest(int requestId) async {
    await Future.delayed(responseDelay);

    final current = _requests[requestId];
    if (current != null && current.status == ApprovalStatus.pending) {
      _requests.remove(requestId);
    }
  }
}

class _ProcessedDecision {
  final ApprovalDecisionCommand command;
  final ApprovalDecisionResult result;

  const _ProcessedDecision({required this.command, required this.result});
}

class MockApiNetworkException implements Exception {
  final String message;

  const MockApiNetworkException(this.message);

  @override
  String toString() => message;
}
