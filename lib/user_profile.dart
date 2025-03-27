import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ======================
// MODELS
// ======================
class User {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final bool isActive;
  final String? avatarUrl;
  final String? role;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.isActive,
    this.avatarUrl,
    this.role,
  });
}

class UserProfile {
  final int id;
  final String fullName;
  final String email;

  UserProfile({required this.id, required this.fullName, required this.email});

  @override
  String toString() {
    return 'UserProfile(id: $id, fullName: "$fullName", email: "$email")';
  }
}

// ======================
// PART 1: DATA TRANSFORMATION
// ======================
List<UserProfile> processUserData(List<User> users) {
  return users
      .where((user) => user.isActive)
      .map(
        (user) => UserProfile(
          id: user.id,
          fullName: '${user.firstName} ${user.lastName}',
          email: user.email,
        ),
      )
      .toList()
    ..sort((a, b) => a.fullName.compareTo(b.fullName));
}

// ======================
// PART 2: ASYNC DATA FETCHING
// ======================
Future<List<String>> fetchUserPosts(int userId, {http.Client? client}) async {
  final http.Client httpClient = client ?? http.Client();
  try {
    final response = await httpClient.get(
      Uri.parse('https://jsonplaceholder.typicode.com/posts?userId=$userId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> posts = jsonDecode(response.body);
      return posts.map((post) => post['title'].toString()).toList();
    } else {
      throw Exception('API Error: Status code ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Failed to fetch posts: $e');
  } finally {
    if (client == null) httpClient.close();
  }
}

// ======================
// PART 3: USER PROFILE WIDGET
// ======================
Widget createUserProfileWidget(User user) {
  return Card(
    elevation: 4,
    margin: const EdgeInsets.all(16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage(
              user.avatarUrl ?? 'https://via.placeholder.com/150',
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.firstName} ${user.lastName}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(user.email, style: TextStyle(color: Colors.grey[600])),
                if (user.role != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Role: ${user.role!}',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
          if (user.isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Active',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    ),
  );
}

// ======================
// PART 4: STATE MANAGEMENT
// ======================
class StateManager {
  Map<String, dynamic> _state;
  final List<Function(Map<String, dynamic>)> _subscribers = [];

  StateManager(this._state);

  Map<String, dynamic> getState() => Map.unmodifiable(_state);

  void setState(Map<String, dynamic> newState) {
    _state = {..._state, ...newState};
    _notifySubscribers();
  }

  void subscribe(Function(Map<String, dynamic>) callback) {
    _subscribers.add(callback);
  }

  void _notifySubscribers() {
    for (final callback in _subscribers) {
      callback(_state);
    }
  }
}
