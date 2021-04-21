import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/models/trip.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:rider_frontend/screens/privacy.dart';
import 'package:rider_frontend/screens/profile.dart';
import 'package:rider_frontend/screens/settings.dart';
import 'package:rider_frontend/widgets/borderlessButton.dart';
import 'package:rider_frontend/widgets/yesNoDialog.dart';

import '../../lib/mocks.dart';

void main() {
  // define mockers behaviors
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    when(mockFirebaseModel.auth).thenReturn(mockFirebaseAuth);
    when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
    when(mockUser.emailVerified).thenReturn(true);
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<FirebaseModel>(
              create: (context) => mockFirebaseModel),
          ChangeNotifierProvider<UserModel>(create: (context) => mockUserModel),
          ChangeNotifierProvider<TripModel>(
            create: (context) => mockTripModel,
          )
        ],
        builder: (context, child) => MaterialApp(
          home: Settings(),
          navigatorObservers: [mockNavigatorObserver],
          routes: {
            Profile.routeName: (context) => Profile(),
            Privacy.routeName: (context) => Privacy(),
          },
        ),
      ),
    );
  }

  testWidgets("shows dialog when user taps 'sair'",
      (WidgetTester tester) async {
    // add Settings screen to the UI
    await pumpSettings(tester);
    verify(mockNavigatorObserver.didPush(any, any));

    // tap sair
    final sairFinder = find.byType(Text);
    final sairWidget = tester.widget(sairFinder.last);
    expect(sairWidget, isA<Text>().having((t) => t.data, "data", "Sair"));
    await tester.tap(sairFinder.last);
    await tester.pumpAndSettle();

    // expect dialog to appear
    verify(mockNavigatorObserver.didPush(any, any));
    expect(find.byType(YesNoDialog), findsOneWidget);
  });

  testWidgets("navigates to Profile correctly", (WidgetTester tester) async {
    // add Settings screen to the UI
    await pumpSettings(tester);
    verify(mockNavigatorObserver.didPush(any, any));

    // tap Profile
    final borderlessButtonFinders = find.byType(BorderlessButton);
    final profileFinder = borderlessButtonFinders.first;
    await tester.tap(profileFinder);
    await tester.pumpAndSettle();

    // expect Profile to be pushed
    verify(mockNavigatorObserver.didPush(any, any));
    expect(find.byType(Profile), findsOneWidget);
  });

  testWidgets("navigates to Privacy correctly", (WidgetTester tester) async {
    // add Settings screen to the UI
    await pumpSettings(tester);
    verify(mockNavigatorObserver.didPush(any, any));

    // tap Profile
    final borderlessButtonFinders = find.byType(BorderlessButton);
    final privacyFinder = borderlessButtonFinders.last;
    await tester.tap(privacyFinder);
    await tester.pumpAndSettle();

    // expect Profile to be pushed
    verify(mockNavigatorObserver.didPush(any, any));
    expect(find.byType(Privacy), findsOneWidget);
  });
}
