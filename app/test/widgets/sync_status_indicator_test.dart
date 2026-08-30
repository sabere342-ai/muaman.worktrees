import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:muaman_store/widgets/sync_status_indicator.dart';

/// Phase P Group A — A6 observability: SyncStatusIndicator truthfulness.
///
/// Proves the indicator surface never presents success when authoritative
/// evidence (pending/failed/conflict counts, reconciliation capability, sync
/// history) contradicts it, and that it may present genuine success only when
/// the converged precondition is fully met. Also proves the retry/reconnect
/// affordance is surfaced when reconciliation cannot be confirmed.
void main() {
  /// Green "fully synced" requires: cloud linked, online, drainActive, zero
  /// queue, and a recorded successful sync.
  bool isGreen(SyncStatusIndicator w) =>
      w.isCloudLinked &&
      w.isOnline &&
      w.drainActive &&
      w.pendingCount == 0 &&
      w.failedCount == 0 &&
      w.conflictCount == 0 &&
      w.lastSyncedAt != null;

  final LastTime = DateTime.now().subtract(const Duration(minutes: 5));

  Future<void> pump(
    WidgetTester tester,
    SyncStatusIndicator indicator) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(child: indicator)),
    ));
    await tester.pumpAndSettle();
  }

  Finder refreshButton() => find.byIcon(Icons.refresh);

  testWidgets('T4 — true convergence renders green fully-synced', (tester) async {
    final indicator = SyncStatusIndicator(
      isCloudLinked: true,
      isOnline: true,
      drainActive: true,
      pendingCount: 0,
      failedCount: 0,
      conflictCount: 0,
      lastSyncedAt: LastTime,
    );
    expect(isGreen(indicator), isTrue);

    await pump(tester, indicator);
    final container =
        tester.widget<Container>(find.descendant(
          of: find.byType(SyncStatusIndicator),
          matching: find.byType(Container),
        ).first);
    expect((container.decoration! as BoxDecoration).color, Colors.green);
  });

  testWidgets('T1 — pending renders orange, never green/synced', (tester) async {
    final indicator = SyncStatusIndicator(
      isCloudLinked: true,
      isOnline: true,
      drainActive: true,
      pendingCount: 3,
      failedCount: 0,
      conflictCount: 0,
      lastSyncedAt: LastTime,
    );
    expect(isGreen(indicator), isFalse);

    await pump(tester, indicator);
    final container =
        tester.widget<Container>(find
            .descendant(
              of: find.byType(SyncStatusIndicator),
              matching: find.byType(Container),
            )
            .first);
    expect((container.decoration! as BoxDecoration).color, Colors.orange);
    expect(find.text('3'), findsOneWidget,
        reason: 'pending count badge must remain visible');
  });

  testWidgets('T2 — failed renders red, never synced', (tester) async {
    final indicator = SyncStatusIndicator(
      isCloudLinked: true,
      isOnline: true,
      drainActive: true,
      pendingCount: 0,
      failedCount: 1,
      conflictCount: 0,
      lastSyncedAt: LastTime,
    );
    expect(isGreen(indicator), isFalse);

    await pump(tester, indicator);
    final container =
        tester.widget<Container>(find
            .descendant(
              of: find.byType(SyncStatusIndicator),
              matching: find.byType(Container),
            )
            .first);
    expect((container.decoration! as BoxDecoration).color, Colors.red);
  });

  testWidgets('T3 — conflict renders red, never synced', (tester) async {
    final indicator = SyncStatusIndicator(
      isCloudLinked: true,
      isOnline: true,
      drainActive: true,
      pendingCount: 0,
      failedCount: 0,
      conflictCount: 1,
      lastSyncedAt: LastTime,
    );
    expect(isGreen(indicator), isFalse);

    await pump(tester, indicator);
    final container =
        tester.widget<Container>(find
            .descendant(
              of: find.byType(SyncStatusIndicator),
              matching: find.byType(Container),
            )
            .first);
    expect((container.decoration! as BoxDecoration).color, Colors.red);
  });

  testWidgets(
      'T2b — failed still marks failure even without active reconciliation',
      (tester) async {
    // failed > 0 must override even when drainActive is false (action
    // required is the strongest signal).
    final indicator = SyncStatusIndicator(
      isCloudLinked: true,
      isOnline: true,
      drainActive: false,
      pendingCount: 0,
      failedCount: 2,
      conflictCount: 0,
      lastSyncedAt: LastTime,
    );
    expect(isGreen(indicator), isFalse);

    await pump(tester, indicator);
    final container =
        tester.widget<Container>(find
            .descendant(
              of: find.byType(SyncStatusIndicator),
              matching: find.byType(Container),
            )
            .first);
    expect((container.decoration! as BoxDecoration).color, Colors.red);
  });

  testWidgets(
      'T6 — cloud-valid but drain inactive must NOT render green/fully-synced',
      (tester) async {
    // The production posture: cloud session valid but the drain seam is OFF
    // (drainActive false). Even with an empty queue the indicator must not
    // claim "fully synced".
    final indicator = SyncStatusIndicator(
      isCloudLinked: true,
      isOnline: true,
      drainActive: false,
      pendingCount: 0,
      failedCount: 0,
      conflictCount: 0,
      lastSyncedAt: LastTime,
    );
    expect(isGreen(indicator), isFalse);

    await pump(tester, indicator);
    final container =
        tester.widget<Container>(find
            .descendant(
              of: find.byType(SyncStatusIndicator),
              matching: find.byType(Container),
            )
            .first);
    expect((container.decoration! as BoxDecoration).color, Colors.amber,
        reason: 'no reconciliation ⇒ amber "sync inactive", not green');
  });

  testWidgets('T6c — offline (membership inactive) is not fully synced',
      (tester) async {
    final indicator = SyncStatusIndicator(
      isCloudLinked: true,
      isOnline: false,
      drainActive: true,
      pendingCount: 0,
      failedCount: 0,
      conflictCount: 0,
      lastSyncedAt: LastTime,
    );
    expect(isGreen(indicator), isFalse);

    await pump(tester, indicator);
    final container =
        tester.widget<Container>(find
            .descendant(
              of: find.byType(SyncStatusIndicator),
              matching: find.byType(Container),
            )
            .first);
    expect((container.decoration! as BoxDecoration).color, Colors.amber);
  });

  testWidgets('armed but no success yet renders blue, not green',
      (tester) async {
    final indicator = SyncStatusIndicator(
      isCloudLinked: true,
      isOnline: true,
      drainActive: true,
      pendingCount: 0,
      failedCount: 0,
      conflictCount: 0,
      lastSyncedAt: null,
    );
    expect(isGreen(indicator), isFalse);

    await pump(tester, indicator);
    final container =
        tester.widget<Container>(find
            .descendant(
              of: find.byType(SyncStatusIndicator),
              matching: find.byType(Container),
            )
            .first);
    expect((container.decoration! as BoxDecoration).color, Colors.blue);
  });

  testWidgets('not cloud linked renders grey', (tester) async {
    final indicator = SyncStatusIndicator(
      isCloudLinked: false,
      isOnline: false,
      drainActive: false,
      pendingCount: 0,
      failedCount: 0,
      conflictCount: 0,
      lastSyncedAt: null,
    );
    expect(isGreen(indicator), isFalse);

    await pump(tester, indicator);
    final container =
        tester.widget<Container>(find
            .descendant(
              of: find.byType(SyncStatusIndicator),
              matching: find.byType(Container),
            )
            .first);
    expect((container.decoration! as BoxDecoration).color, Colors.grey);
  });

  testWidgets('T7 — retry affordance appears when not confirmed converged and '
      'is suppressed when fully synced', (tester) async {
    // Not converged: pending + onRetry ⇒ refresh affordance present.
    final pending = SyncStatusIndicator(
      isCloudLinked: true,
      isOnline: true,
      drainActive: true,
      pendingCount: 2,
      failedCount: 0,
      conflictCount: 0,
      onRetry: () {},
    );
    await pump(tester, pending);
    expect(refreshButton(), findsOneWidget,
        reason: 'retry/reconnect affordance surfaced for non-converged state');

    // Fully synced: onRetry present but suppressed (nothing to retry).
    final converged = SyncStatusIndicator(
      isCloudLinked: true,
      isOnline: true,
      drainActive: true,
      pendingCount: 0,
      failedCount: 0,
      conflictCount: 0,
      lastSyncedAt: LastTime,
      onRetry: () {},
    );
    await pump(tester, converged);
    expect(refreshButton(), findsNothing,
        reason: 'no retry affordance when genuinely fully synced');
  });
}
