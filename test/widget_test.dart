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

Future<void> _openSocialMediaTab(WidgetTester tester) async {
  await _tapNavTab(tester, 'Social Media');
}

Future<void> _openCreatePostSheet(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Create Post'));
  await tester.pumpAndSettle();
}

Future<void> _submitNewPost(
  WidgetTester tester, {
  required String caption,
  required String imageUrl,
}) async {
  await _openCreatePostSheet(tester);
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

  testWidgets('1. Log in using default admin account opens MainScreen', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const StudentApp());
    expect(find.text('Welcome Back!'), findsOneWidget);

    await _loginWith(tester, 'admin', 'admin123');

    expect(find.text('Welcome, Student!'), findsOneWidget);
    expect(DemoAuth.currentUsername, 'admin');
  });

  testWidgets('2. Open Social Media shows sample posts', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const StudentApp());
    await _loginWith(tester, 'admin', 'admin123');
    await _openSocialMediaTab(tester);

    expect(find.text('JohnDoe'), findsOneWidget);
    expect(find.text('Enjoying the sunny weather!'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('JaneSmith'),
      250,
      scrollable: _feedScrollable(),
    );
    expect(find.text('JaneSmith'), findsOneWidget);
    expect(find.text('Just finished a great book!'), findsOneWidget);
  });

  testWidgets('3. Submit post with empty fields shows validation message', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const StudentApp());
    await _loginWith(tester, 'admin', 'admin123');
    await _openSocialMediaTab(tester);
    await _openCreatePostSheet(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Post'));
    await tester.pump();

    expect(
      find.text('Complete both fields before submitting!'),
      findsOneWidget,
    );
  });

  testWidgets('4. Submit post with invalid URL shows URL validation message', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const StudentApp());
    await _loginWith(tester, 'admin', 'admin123');
    await _openSocialMediaTab(tester);

    await _submitNewPost(
      tester,
      caption: 'Invalid URL test',
      imageUrl: 'not-a-valid-url',
    );

    expect(
      find.text('Enter a valid HTTP or HTTPS image URL.'),
      findsOneWidget,
    );
  });

  testWidgets(
    '5. Submit valid post adds post at top with logged-in username',
    (WidgetTester tester) async {
      _usePhoneViewport(tester);
      await tester.pumpWidget(const StudentApp());
      await _loginWith(tester, 'admin', 'admin123');
      await _openSocialMediaTab(tester);

      await _submitNewPost(
        tester,
        caption: 'My first Flutter social media post!',
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
          matching: find.text('My first Flutter social media post!'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('6. Tap Like twice toggles Liked and back to Like', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const StudentApp());
    await _loginWith(tester, 'admin', 'admin123');
    await _openSocialMediaTab(tester);

    final firstCard = find.byType(PostCard).first;
    await tester.tap(
      find.descendant(of: firstCard, matching: find.text('Like')),
    );
    await tester.pump();

    expect(
      find.descendant(of: firstCard, matching: find.text('Liked')),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(of: firstCard, matching: find.text('Liked')),
    );
    await tester.pump();

    expect(
      find.descendant(of: firstCard, matching: find.text('Like')),
      findsOneWidget,
    );
  });

  testWidgets('7 & 8. Nonempty comment adds and increments count; blank ignored', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const StudentApp());
    await _loginWith(tester, 'admin', 'admin123');
    await _openSocialMediaTab(tester);

    final firstCard = find.byType(PostCard).first;
    final commentField = find.descendant(
      of: firstCard,
      matching: find.byType(TextField),
    );
    final sendBtn = find.descendant(
      of: firstCard,
      matching: find.byIcon(Icons.send),
    );

    // 8. Blank comment should not be added
    await tester.enterText(commentField, '   ');
    await tester.tap(sendBtn);
    await tester.pump();
    expect(
      find.descendant(of: firstCard, matching: find.text('0 Comments')),
      findsOneWidget,
    );

    // 7. Nonempty comment adds and increments count
    await tester.enterText(commentField, 'Great post!');
    await tester.tap(sendBtn);
    await tester.pump();

    expect(
      find.descendant(of: firstCard, matching: find.text('Great post!')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: firstCard, matching: find.text('1 Comments')),
      findsOneWidget,
    );
  });

  testWidgets(
    '9 & 10. Like sample post, create new post, switch tabs preserves state',
    (WidgetTester tester) async {
      _usePhoneViewport(tester);
      await tester.pumpWidget(const StudentApp());
      await _loginWith(tester, 'admin', 'admin123');
      await _openSocialMediaTab(tester);

      // Like JohnDoe's sample post and add a comment
      final johnCard = find.widgetWithText(PostCard, 'JohnDoe');
      await tester.tap(
        find.descendant(of: johnCard, matching: find.text('Like')),
      );
      await tester.pump();
      expect(
        find.descendant(of: johnCard, matching: find.text('Liked')),
        findsOneWidget,
      );

      await tester.enterText(
        find.descendant(of: johnCard, matching: find.byType(TextField)),
        'Nice weather!',
      );
      await tester.tap(
        find.descendant(of: johnCard, matching: find.byIcon(Icons.send)),
      );
      await tester.pump();
      expect(
        find.descendant(of: johnCard, matching: find.text('Nice weather!')),
        findsOneWidget,
      );

      // Create another post above JohnDoe
      await _submitNewPost(
        tester,
        caption: 'Second post on top',
        imageUrl: 'https://picsum.photos/id/21/600/400',
      );

      // 9. JohnDoe keeps its liked state & comment even after shifting down
      expect(find.text('Second post on top'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.descendant(of: johnCard, matching: find.text('Liked')),
        100,
        scrollable: _feedScrollable(),
      );
      expect(
        find.descendant(of: johnCard, matching: find.text('Liked')),
        findsOneWidget,
      );

      // 10. Switch to Home and return -> posts, likes, and comments remain
      await _tapNavTab(tester, 'Home');
      expect(find.text('Welcome, Student!'), findsOneWidget);

      await _openSocialMediaTab(tester);
      expect(
        find.descendant(of: johnCard, matching: find.text('Liked')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: johnCard, matching: find.text('Nice weather!')),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.text('Second post on top'),
        -150,
        scrollable: _feedScrollable(),
      );
      expect(find.text('Second post on top'), findsOneWidget);
    },
  );

  testWidgets(
    '11. Log out, register new account, log in -> new posts use registered username',
    (WidgetTester tester) async {
      _usePhoneViewport(tester);
      await tester.pumpWidget(const StudentApp());
      await _loginWith(tester, 'admin', 'admin123');

      // Open Profile tab and tap Logout
      await _tapNavTab(tester, 'Profile');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Logout'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(DemoAuth.currentUsername, isNull);

      // Register a new account
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

      // Log in with new account
      await _loginWith(tester, 'jules_reyes', 'secret123');
      expect(DemoAuth.currentUsername, 'jules_reyes');

      await _openSocialMediaTab(tester);
      await _submitNewPost(
        tester,
        caption: 'Posted as registered user',
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
