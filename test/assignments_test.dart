// Event assignments (SCHED-15): the row near the bottom of an event, and
// its list: volunteering, dropping out, and an admin adding, assigning,
// editing, and removing tasks.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/schedule/domain/assignment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/scenes.dart';

const alex = AuthUser(
  uid: 'alex',
  email: 'alex@example.com',
  displayName: 'Alex Kim',
  emailVerified: true,
);

Assignment task(
  String id,
  AssignmentKind kind, {
  String? label,
  String? holder,
  String? by,
}) => Assignment(
  id: id,
  groupId: const GroupId('a'),
  eventId: const EventId('e1'),
  kind: kind,
  label: label,
  assigneeUid: holder,
  assignedBy: by ?? holder,
  createdBy: 'coach',
  createdAt: DateTime.utc(2026, 10, int.parse(id.substring(1)) + 1),
);

/// The event page for vs. Eagles, scrolled to its Assignments row.
Future<void> openEvent(
  WidgetTester tester, {
  AuthUser user = coach,
  FakeAssignmentRepository? assignments,
}) async {
  await pumpTeam(
    tester,
    theme: ThemePreference.dark,
    user: user,
    assignments: assignments,
  );
  await tester.tap(find.text('Schedule'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('vs. Eagles').first);
  await tester.pumpAndSettle();
}

Future<void> scrollToRow(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Assignments'),
    200,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
}

Future<void> openList(WidgetTester tester) async {
  await scrollToRow(tester);
  await tester.tap(find.text('Assignments'));
  await tester.pumpAndSettle();
}

Future<void> menu(WidgetTester tester, String task, String action) async {
  await tester.tap(find.byTooltip('Options for $task'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(action).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a member sees no Assignments row when there are none', (
    tester,
  ) async {
    await openEvent(tester, user: alex);
    await tester.scrollUntilVisible(
      find.text('Not going · 1'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(find.text('Assignments'), findsNothing);
  });

  testWidgets('a member volunteers for an open task and drops out again', (
    tester,
  ) async {
    final repo = FakeAssignmentRepository([
      task('t1', AssignmentKind.snacks, label: 'Halftime oranges'),
      task('t2', AssignmentKind.scorekeeper, holder: 'sam'),
    ]);
    await openEvent(tester, user: alex, assignments: repo);
    await scrollToRow(tester);
    expect(find.text('1 of 2 taken'), findsOneWidget);
    await tester.tap(find.text('Assignments'));
    await tester.pumpAndSettle();

    expect(find.text('Snacks · Halftime oranges'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Sam Rivera volunteered'), findsOneWidget);
    // Members don't manage tasks.
    expect(find.text('Add assignment'), findsNothing);
    expect(find.byTooltip('Options for Scorekeeper'), findsNothing);
    // Volunteer only on the open one.
    expect(find.text('Volunteer'), findsOneWidget);

    await tester.tap(find.text('Volunteer'));
    await tester.pumpAndSettle();
    expect(repo.assignments.first.assigneeUid, 'alex');
    expect(repo.assignments.first.assignedBy, 'alex');
    expect(find.text('You'), findsOneWidget);
    expect(find.text('Volunteer'), findsNothing);

    await tester.tap(find.text('Drop out'));
    await tester.pumpAndSettle();
    expect(repo.assignments.first.isOpen, isTrue);
    expect(find.text('Volunteer'), findsOneWidget);
  });

  testWidgets("the row shows what's mine", (tester) async {
    final repo = FakeAssignmentRepository([
      task('t1', AssignmentKind.drinks, holder: 'alex'),
      task('t2', AssignmentKind.snacks),
    ]);
    await openEvent(tester, user: alex, assignments: repo);
    await scrollToRow(tester);
    expect(find.text('You: Drinks'), findsOneWidget);
  });

  testWidgets('a task taken in the meantime says so', (tester) async {
    final repo = FakeAssignmentRepository([task('t1', AssignmentKind.snacks)]);
    await openEvent(tester, user: alex, assignments: repo);
    await openList(tester);
    repo.refuse = true;
    await tester.tap(find.text('Volunteer'));
    await tester.pumpAndSettle();
    expect(find.text('Someone just took that one.'), findsOneWidget);
  });

  testWidgets('an admin adds, assigns, opens, edits, and removes a task', (
    tester,
  ) async {
    final repo = FakeAssignmentRepository();
    await openEvent(tester, assignments: repo);
    await scrollToRow(tester);
    expect(
      find.text('Add snacks, drinks, a scorekeeper, or anything else'),
      findsOneWidget,
    );
    await tester.tap(find.text('Assignments'));
    await tester.pumpAndSettle();

    // Add one: Drinks, with details, open.
    await tester.tap(find.text('Add assignment'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Drinks'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Water bottles');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.assignments.single.kind, AssignmentKind.drinks);
    expect(repo.assignments.single.label, 'Water bottles');
    expect(find.text('Drinks · Water bottles'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);

    // Assign Alex.
    await menu(tester, 'Drinks · Water bottles', 'Assign someone');
    await tester.tap(find.text('Alex Kim'));
    await tester.pumpAndSettle();
    expect(repo.assignments.single.assigneeUid, 'alex');
    expect(repo.assignments.single.assignedBy, 'coach');
    expect(find.text('Assigned to Alex Kim'), findsOneWidget);

    // Open it again.
    await menu(tester, 'Drinks · Water bottles', 'Make it open');
    expect(repo.assignments.single.isOpen, isTrue);

    // Edit it into a task of the coach's own.
    await menu(tester, 'Drinks · Water bottles', 'Edit');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Other'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Field setup');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.assignments.single.kind, AssignmentKind.other);
    expect(find.text('Field setup'), findsOneWidget);

    // Remove it.
    await menu(tester, 'Field setup', 'Remove');
    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await tester.pumpAndSettle();
    expect(repo.assignments, isEmpty);
  });

  testWidgets('an "other" task needs a name, and one can be assigned as it '
      'is added', (tester) async {
    final repo = FakeAssignmentRepository();
    await openEvent(tester, assignments: repo);
    await openList(tester);
    await tester.tap(find.text('Add assignment'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Other'));
    await tester.pumpAndSettle();
    final save = find.widgetWithText(FilledButton, 'Save');
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'Photos');
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(save).onPressed, isNotNull);

    await tester.tap(find.text('Nobody yet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jo Park').last);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(repo.assignments.single.label, 'Photos');
    expect(repo.assignments.single.assigneeUid, 'jo');
    expect(find.text('Assigned to Jo Park'), findsOneWidget);
  });

  testWidgets('an event takes up to 20 assignments', (tester) async {
    final repo = FakeAssignmentRepository([
      for (var i = 0; i < Limits.assignmentsPerEventMax; i++)
        task('t$i', AssignmentKind.snacks),
    ]);
    await openEvent(tester, assignments: repo);
    await openList(tester);
    await tester.scrollUntilVisible(
      find.text('Add assignment'),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    final add = find.ancestor(
      of: find.text('Add assignment'),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );
    expect(tester.widget<ButtonStyleButton>(add).onPressed, isNull);
    expect(
      find.text('An event can have up to 20 assignments.'),
      findsOneWidget,
    );
  });
}
