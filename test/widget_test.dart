import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reyes_navigation_app/demo_auth.dart';
import 'package:reyes_navigation_app/main.dart';
import 'package:reyes_navigation_app/social_media/post_card.dart';
import 'package:reyes_navigation_app/social_media/social_media.dart';

void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(500, 980);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _loginWith(
  WidgetTester tester,
  String username,
  String password,
) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Username'),
    username,
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Password'),
    password,
  );
  await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
  await tester.pumpAndSettle();
}

Future<void> _tapNavTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(label),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _submitNewPost(
  WidgetTester tester, {
  required String caption,
  required String imageUrl,
}) async {
  await tester.tap(find.byTooltip('Create Post'));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.widgetWithText(TextField, 'Caption'),
    caption,
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Image URL'),
    imageUrl,
  );
  await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Post'));
  await tester.pumpAndSettle();
}

Finder _feedScrollable() {
  return find
      .descendant(
        of: find.byType(SocialMediaPage),
        matching: find.byType(Scrollable),
      )
      .first;
}

void main() {
  setUp(() {
    DemoAuth.registeredUsername = null;
    DemoAuth.registeredPassword = null;
    DemoAuth.currentUsername = null;
  });

  testWidgets(
    '1, 2, 3, 4 & 5. App starts on Login, validates empty & invalid credentials, logs in admin to Dashboard',
    (WidgetTester tester) async {
      _usePhoneViewport(tester);
      await tester.pumpWidget(const StudentApp());

      // 1. Open application -> Login appears first
      expect(find.text('Welcome Back!'), findsOneWidget);

      // 2. Submit empty login fields -> Validation messages appear
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();
      expect(find.text('Enter your username.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);

      // 3. Enter incorrect credentials -> Login rejected
      await _loginWith(tester, 'wrong', 'wrongpass');
      expect(find.text('Invalid username or password.'), findsOneWidget);
      expect(DemoAuth.currentUsername, isNull);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // 4 & 5. Enter admin / admin123 -> Dashboard opens and greets admin
      await _loginWith(tester, 'admin', 'admin123');
      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('Welcome, admin!'), findsOneWidget);
      expect(DemoAuth.currentUsername, 'admin');
    },
  );

  testWidgets(
    '6 & 7. Calculator computes 10+5=15.0, 20 & 5 operations, and keeps state across tab switches',
    (WidgetTester tester) async {
      _usePhoneViewport(tester);
      await tester.pumpWidget(const StudentApp());
      await _loginWith(tester, 'admin', 'admin123');

      await _tapNavTab(tester, 'Calculator');

      final firstField = find.widgetWithText(TextField, 'First Number');
      final secondField = find.widgetWithText(TextField, 'Second Number');

      // Step 7 checkpoint: 20 and 5 across all four operations
      await tester.enterText(firstField, '20');
      await tester.enterText(secondField, '5');

      await tester.tap(find.widgetWithText(ElevatedButton, '+'));
      await tester.pump();
      expect(find.text('25.0'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, '−'));
      await tester.pump();
      expect(find.text('15.0'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, '×'));
      await tester.pump();
      expect(find.text('100.0'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, '÷'));
      await tester.pump();
      expect(find.text('4.0'), findsOneWidget);

      // 6. Test 10 + 5 = 15.0
      await tester.enterText(firstField, '10');
      await tester.enterText(secondField, '5');
      await tester.tap(find.widgetWithText(ElevatedButton, '+'));
      await tester.pump();
      expect(find.text('15.0'), findsOneWidget);

      // 7. Switch tabs and return to Calculator -> inputs and result remain
      await _tapNavTab(tester, 'Dashboard');
      expect(find.text('Welcome, admin!'), findsOneWidget);

      await _tapNavTab(tester, 'Calculator');
      expect(find.text('15.0'), findsOneWidget);
      expect(find.text('10.0 + 5.0'), findsOneWidget);
    },
  );

  testWidgets(
    '8, 9 & 10. Social creates post with logged-in user, likes/comments, preserves state across tabs',
    (WidgetTester tester) async {
      _usePhoneViewport(tester);
      await tester.pumpWidget(const StudentApp());
      await _loginWith(tester, 'admin', 'admin123');

      await _tapNavTab(tester, 'Social');
      expect(find.text('JohnDoe'), findsOneWidget);

      // 8. Create a social post -> displays logged-in username
      await _submitNewPost(
        tester,
        caption: 'Integrated app test post!',
        imageUrl: 'https://picsum.photos/id/20/600/400',
      );

      final firstCard = find.byType(PostCard).first;
      expect(
        find.descendant(of: firstCard, matching: find.text('admin')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: firstCard,
          matching: find.text('Integrated app test post!'),
        ),
        findsOneWidget,
      );

      // 9. Like a post and add a comment
      await tester.tap(
        find.descendant(of: firstCard, matching: find.text('Like')),
      );
      await tester.pump();
      expect(
        find.descendant(of: firstCard, matching: find.text('Liked')),
        findsOneWidget,
      );

      await tester.enterText(
        find.descendant(of: firstCard, matching: find.byType(TextField)),
        'Great integration!',
      );
      await tester.tap(
        find.descendant(of: firstCard, matching: find.byIcon(Icons.send)),
      );
      await tester.pump();

      expect(
        find.descendant(of: firstCard, matching: find.text('1 Comments')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: firstCard,
          matching: find.text('Great integration!'),
        ),
        findsOneWidget,
      );

      // Verify ObjectKey + findChildIndexCallback preserves liked state after another post
      await _submitNewPost(
        tester,
        caption: 'Top post',
        imageUrl: 'https://picsum.photos/id/21/600/400',
      );
      final adminPost = find.widgetWithText(PostCard, 'Integrated app test post!');
      await tester.scrollUntilVisible(
        find.descendant(of: adminPost, matching: find.text('Liked')),
        100,
        scrollable: _feedScrollable(),
      );
      expect(
        find.descendant(of: adminPost, matching: find.text('Liked')),
        findsOneWidget,
      );

      // 10. Switch tabs and return to Social -> posts, likes, and comments remain
      await _tapNavTab(tester, 'Dashboard');
      await _tapNavTab(tester, 'Social');
      expect(
        find.descendant(of: adminPost, matching: find.text('Liked')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: adminPost,
          matching: find.text('Great integration!'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    '11, 12, 13 & 14. Profile displays info & username, Logout prevents back, Register + Login updates Dashboard & Social',
    (WidgetTester tester) async {
      _usePhoneViewport(tester);
      await tester.pumpWidget(const StudentApp());
      await _loginWith(tester, 'admin', 'admin123');

      // 11. Open Profile -> Student info and username appear
      await _tapNavTab(tester, 'Profile');
      expect(find.text('Student Profile'), findsOneWidget);
      expect(find.text('Jules Henri A. Reyes'), findsOneWidget);
      expect(find.text('Logged in as: admin'), findsOneWidget);
      expect(find.text('553299'), findsOneWidget);
      expect(find.text('BSIT — 3450'), findsOneWidget);
      expect(find.text('j.reyes.553299@umindanao.edu'), findsOneWidget);

      // 12. Tap Logout -> Login appears, cannot pop back
      await tester.tap(find.widgetWithText(ElevatedButton, 'Logout'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(DemoAuth.currentUsername, isNull);
      expect(Navigator.of(tester.element(find.text('Welcome Back!'))).canPop(), isFalse);

      // 13. Register a valid account and log in -> Dashboard displays registered username
      await tester.tap(find.text("Don't have an account? Register"));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'jules_reyes',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'secret123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'secret123',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      await _loginWith(tester, 'jules_reyes', 'secret123');
      expect(find.text('Welcome, jules_reyes!'), findsOneWidget);

      // Verify Profile also shows registered username
      await _tapNavTab(tester, 'Profile');
      expect(find.text('Logged in as: jules_reyes'), findsOneWidget);

      // 14. Create a post using the registered account -> post displays registered username
      await _tapNavTab(tester, 'Social');
      await _submitNewPost(
        tester,
        caption: 'Post from registered user',
        imageUrl: 'https://picsum.photos/id/22/600/400',
      );
      final firstCard = find.byType(PostCard).first;
      expect(
        find.descendant(of: firstCard, matching: find.text('jules_reyes')),
        findsOneWidget,
      );
    },
  );
}
