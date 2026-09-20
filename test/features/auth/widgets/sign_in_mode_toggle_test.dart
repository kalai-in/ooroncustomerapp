import 'package:flutter_test/flutter_test.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/features/auth/widgets/sign_in_mode_toggle.dart';

import '../../../helpers/pump_test_widget.dart';
import '../../../helpers/test_logging.dart';

void main() {
  tearDownAll(() => printTestDivider('=== All tests run! ==='));

  testWidgets('renders both Email and Mobile options', (tester) async {
    printTestDivider('SignInModeToggle renders both Email and Mobile options');
    await tester.pumpWidget(
      pumpTestWidget(
        SignInModeToggle(mode: SignInMode.email, onChanged: (_) {}),
      ),
    );

    printTestLog(
      'Email label → expected: present, actual: ${find.text(LanguageLabelKeys.email).evaluate().isNotEmpty}',
    );
    expect(find.text(LanguageLabelKeys.email), findsOneWidget);
    printTestLog(
      'Mobile label → expected: present, actual: ${find.text(LanguageLabelKeys.mobile).evaluate().isNotEmpty}',
    );
    expect(find.text(LanguageLabelKeys.mobile), findsOneWidget);
  });

  testWidgets('tapping the phone option calls onChanged with SignInMode.phone', (
    tester,
  ) async {
    printTestDivider(
      'SignInModeToggle tapping the phone option calls onChanged with SignInMode.phone',
    );
    SignInMode? changedTo;

    await tester.pumpWidget(
      pumpTestWidget(
        SignInModeToggle(
          mode: SignInMode.email,
          onChanged: (mode) => changedTo = mode,
        ),
      ),
    );

    await tester.tap(find.text(LanguageLabelKeys.mobile));
    await tester.pump();

    printTestLog('changedTo → expected: SignInMode.phone, actual: $changedTo');
    expect(changedTo, SignInMode.phone);
  });

  testWidgets('tapping the currently-active option still calls onChanged (parent decides no-op)', (
    tester,
  ) async {
    printTestDivider(
      'SignInModeToggle tapping the currently-active option still calls onChanged',
    );
    var callCount = 0;

    await tester.pumpWidget(
      pumpTestWidget(
        SignInModeToggle(
          mode: SignInMode.email,
          onChanged: (_) => callCount++,
        ),
      ),
    );

    await tester.tap(find.text(LanguageLabelKeys.email));
    await tester.pump();

    printTestLog('callCount → expected: 1, actual: $callCount');
    expect(callCount, 1);
  });
}
