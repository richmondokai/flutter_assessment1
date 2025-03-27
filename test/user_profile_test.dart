import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_assessment/user_profile.dart';

// Override HTTP requests in tests
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() {
  // Apply HTTP override
  setUpAll(() {
    HttpOverrides.global = MyHttpOverrides();
    print('✅ Setup completed: HTTP override applied.');
  });

  // Test data
  final mockUsers = [
    User(
      id: 1,
      firstName: "John",
      lastName: "Doe",
      email: "john@test.com",
      isActive: true,
    ),
    User(
      id: 2,
      firstName: "Jane",
      lastName: "Smith",
      email: "jane@test.com",
      isActive: false,
    ),
  ];

  print("🔹 Processed Users: ${processUserData(mockUsers)}");

  fetchUserPosts(1)
      .then((titles) {
        print("🔹 User Posts: $titles");
      })
      .catchError((error) {
        print("❌ Error fetching posts: $error");
      });

  // ======================
  // PART 1 TESTS - Data Processing
  // ======================
  group('🟢 Data Transformation Tests', () {
    test('Filters and transforms users correctly', () {
      print('🔹 Running test: Filters and transforms users correctly...');
      final result = processUserData(mockUsers);

      expect(result.length, 1);
      expect(result[0].id, 1);
      expect(result[0].fullName, 'John Doe');
      expect(result[0].email, 'john@test.com');

      print('✅ Test passed: Users filtered and transformed correctly.');
    });
  });

  // ======================
  // PART 2 TESTS - API Fetching
  // ======================
  group('🟢 API Fetching Tests', () {
    test('Returns post titles on success', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {"userId": 1, "id": 1, "title": "Test Post"},
          ]),
          200,
        );
      });

      final titles = await fetchUserPosts(1, client: mockClient);
      print("🔹 Fetched User Posts: $titles");
      expect(titles, ['Test Post']);
    });
  });

  // ======================
  // PART 3 TESTS - Widget Testing
  // ======================
  testWidgets('🟢 UserProfileWidget renders correctly', (tester) async {
    final sampleUser = User(
      id: 1,
      firstName: "John",
      lastName: "Doe",
      email: "john@example.com",
      avatarUrl: "https://randomuser.me/api/portraits/men/1.jpg",
      isActive: true,
      role: "Admin",
    );

    print("🔹 User Profile Widget: ${createUserProfileWidget(sampleUser)}");

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: createUserProfileWidget(sampleUser))),
    );

    await tester.pumpAndSettle(); // Ensure the widget fully loads

    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('john@example.com'), findsOneWidget);
    expect(find.text('Role: Admin'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.byType(CircleAvatar), findsOneWidget);
  });

  // ======================
  // PART 4 TESTS - State Management
  // ======================
  group('🟢 State Management Tests', () {
    test('Initial state is correct', () {
      final userState = StateManager({'name': 'John', 'online': false});
      print("🔹 Initial State: ${userState.getState()}");
      expect(userState.getState(), {'name': 'John', 'online': false});
    });

    test('Notifies subscribers', () async {
      final userState = StateManager({'name': 'John', 'online': false});
      userState.subscribe((state) => print("🔔 State changed: $state"));

      userState.setState({'online': true});
      userState.setState({'lastActive': '2023-05-01'});

      await Future.delayed(Duration(milliseconds: 10));
      expect(userState.getState(), {
        'name': 'John',
        'online': true,
        'lastActive': '2023-05-01',
      });
    });
  });
}
