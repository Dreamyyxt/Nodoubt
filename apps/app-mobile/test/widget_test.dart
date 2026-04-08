import 'package:flutter_test/flutter_test.dart';

import 'package:app_mobile/app/app.dart';

void main() {
  testWidgets('development login page renders', (WidgetTester tester) async {
    await tester.pumpWidget(const NoDoubtApp());

    expect(find.text('TASK BOUNTY + SKILL SWAP'), findsOneWidget);
    expect(find.text('开发登录'), findsOneWidget);
    expect(find.text('进入确任'), findsOneWidget);
  });
}
