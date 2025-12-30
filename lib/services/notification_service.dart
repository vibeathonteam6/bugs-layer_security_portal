import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';

class NotificationService {
  // No longer hardcoded. Fetched dynamically.
  static const String _fcmUrl =
      'https://fcm.googleapis.com/v1/projects/vibe-a-thon-bugslayer/messages:send';
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/firebase.messaging',
  ];

  /// Retrieves the access token from the service account key
  static Future<String?> _getAccessToken() async {
    try {
      final serviceAccountString =
          await rootBundle.loadString('assets/service-account.json');
      final serviceAccountJson = jsonDecode(serviceAccountString);

      final credentials =
          ServiceAccountCredentials.fromJson(serviceAccountJson);
      final client = await clientViaServiceAccount(credentials, _scopes);
      final accessToken = client.credentials.accessToken.data;

      client.close(); // Close the client to avoid leaks
      return accessToken;
    } catch (e) {
      print('Error getting access token: $e');
      return null;
    }
  }

  /// Sends a push notification to a specific FCM token
  static Future<void> sendNotification({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (fcmToken.isEmpty) return;

    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      print('Failed to get access token. Notification not sent.');
      return;
    }

    try {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };
      final requestBody = jsonEncode({
        'message': {
          'token': fcmToken,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': data ?? {},
        }
      });

      print('--- FCM REQUEST DEBUG ---');
      print('URL: $_fcmUrl');
      print('Headers: $headers');
      print('Body: $requestBody');
      print('-------------------------');

      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: headers,
        body: requestBody,
      );

      if (response.statusCode == 200) {
        print('Notification sent successfully');
      } else {
        print('Failed to send notification: ${response.body}');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  /// Helper to send status change notification
  static Future<void> sendStatusNotification(
    String fcmToken,
    String visitorName,
    String newStatus,
    String visitId,
  ) async {
    await sendNotification(
      fcmToken: fcmToken,
      title: 'Visitor Status Updated',
      body: 'Your visitor pass for $visitorName has been $newStatus.',
      data: {
        'type': 'status_update',
        'status': newStatus,
        'visitorName': visitorName, // Also useful to have in data
        'visitId': visitId,
      },
    );
  }
}
