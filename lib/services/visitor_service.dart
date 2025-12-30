import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class VisitorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Returns a stream of all visitor passes ordered by creation time.
  /// We filter by status in the UI to avoid complex index requirements.
  Stream<QuerySnapshot> getVisitorPasses() {
    return _firestore
        .collection('visit_passes')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Returns a stream of all registered visitor profiles.
  Stream<QuerySnapshot> getVisitorProfiles() {
    return _firestore.collection('visitor_register').snapshots();
  }

  /// Search visitor passes (returns raw stream, UI handles logic)
  Stream<QuerySnapshot> searchVisitors(String queryText) {
    return getVisitorPasses();
  }

  /// Fetches a single visitor by their ID (useful for QR scanning)
  Future<DocumentSnapshot?> getVisitorById(String visitorId) async {
    final query = await _firestore
        .collection('visit_passes')
        .where('visitorId', isEqualTo: visitorId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first;
    }

    try {
      final doc =
          await _firestore.collection('visit_passes').doc(visitorId).get();
      if (doc.exists) return doc;
    } catch (_) {}

    return null;
  }

  /// Fetches the master profile for a visitor from visitor_register
  Future<DocumentSnapshot?> getVisitorProfile(String visitorId) async {
    try {
      final doc =
          await _firestore.collection('visitor_register').doc(visitorId).get();
      if (doc.exists) return doc;

      final query = await _firestore
          .collection('visitor_register')
          .where('visitorId', isEqualTo: visitorId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) return query.docs.first;
    } catch (e) {
      print('Error fetching visitor profile: $e');
    }
    return null;
  }

  /// Update the status of a visitor pass
  Future<void> updateVisitorStatus(
      String docId, String newStatus, Map<String, dynamic> visitorData,
      {String? blockReason}) async {
    final Map<String, dynamic> updateData = {
      'status': newStatus,
    };

    if (blockReason != null && blockReason.isNotEmpty) {
      updateData['blockReason'] = blockReason;
    }

    await _firestore.collection('visit_passes').doc(docId).update(updateData);

    final String? visitorId = visitorData['visitorId'];

    // SYNC TO PROFILE (visitor_register)
    if (visitorId != null && visitorId.isNotEmpty) {
      print(
          'DEBUG: Syncing status to visitor_register for $visitorId (new status: $newStatus)');
      try {
        final profileUpdate = newStatus == 'Blacklisted'
            ? {
                'isBlocked': true,
                'blockReason': blockReason,
                'blockedAt': FieldValue.serverTimestamp(),
              }
            : {
                'isBlocked': false,
                'blockReason': FieldValue.delete(),
                'blockedAt': FieldValue.delete(),
              };

        print('DEBUG: Updating direct profile doc for $visitorId');
        // Try direct doc update (using visitorId as docId)
        await _firestore
            .collection('visitor_register')
            .doc(visitorId)
            .set(profileUpdate, SetOptions(merge: true));
        print(
            'Profile $visitorId sync complete: isBlocked = ${profileUpdate['isBlocked']}');

        print(
            'DEBUG: Searching for other profile docs with visitorId field: $visitorId');
        // Also try querying by visitorId field if docId is different
        final query = await _firestore
            .collection('visitor_register')
            .where('visitorId', isEqualTo: visitorId)
            .get();

        print('DEBUG: Found ${query.docs.length} profile documents to update');
        for (var doc in query.docs) {
          if (doc.id != visitorId) {
            print('DEBUG: Updating additional profile doc: ${doc.id}');
            await doc.reference.update(profileUpdate);
          }
        }
        print('DEBUG: Global block status sync for $visitorId complete');
      } catch (e) {
        print('DEBUG ERROR: Failed to sync block status for $visitorId: $e');
      }
    }

    // Try to get token from visitorData first (backward compatibility)
    String? fcmToken = visitorData['fcmToken'];
    final String visitorName = visitorData['visitorName'] ?? 'Visitor';

    // If not found, fetch from visitor_register
    if (fcmToken == null || fcmToken.isEmpty) {
      if (visitorId != null && visitorId.isNotEmpty) {
        try {
          print(
              'Fetching FCM token for visitorId: $visitorId from visitor_register');
          final userDoc = await _firestore
              .collection('visitor_register')
              .doc(visitorId)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data();
            fcmToken = userData?['fcmToken'];
            print('Found ID in visitor_register. Token: $fcmToken');
          } else {
            // Fallback: try querying by visitorId field if docId doesn't match
            final querySnapshot = await _firestore
                .collection('visitor_register')
                .where('visitorId', isEqualTo: visitorId)
                .limit(1)
                .get();
            if (querySnapshot.docs.isNotEmpty) {
              fcmToken = querySnapshot.docs.first.data()['fcmToken'];
              print('Found ID via query in visitor_register. Token: $fcmToken');
            } else {
              print('Visitor ID $visitorId not found in visitor_register');
            }
          }
        } catch (e) {
          print('Error fetching token from visitor_register: $e');
        }
      } else {
        print('No visitorId available to fetch token');
      }
    }

    if (fcmToken != null && fcmToken.isNotEmpty) {
      print(
          'Sending notification to $visitorName for status $newStatus (Token: $fcmToken)');
      await NotificationService.sendStatusNotification(
        fcmToken,
        visitorName,
        newStatus,
        docId,
      );
    } else {
      print(
          'No FCM token found for visitor $visitorName. Notification skipped.');
    }
  }

  /// Directly updates a visitor profile status in visitor_register
  Future<void> updateProfileStatus(String visitorId, bool isBlocked,
      {String? blockReason}) async {
    print(
        'DEBUG: Starting updateProfileStatus for ID: $visitorId, isBlocked: $isBlocked');
    try {
      final profileUpdate = isBlocked
          ? {
              'isBlocked': true,
              'blockReason': blockReason,
              'blockedAt': FieldValue.serverTimestamp(),
            }
          : {
              'isBlocked': false,
              'blockReason': FieldValue.delete(),
              'blockedAt': FieldValue.delete(),
            };

      print('DEBUG: Attempting direct document update for $visitorId');
      // Try direct doc update (using visitorId as docId)
      await _firestore
          .collection('visitor_register')
          .doc(visitorId)
          .set(profileUpdate, SetOptions(merge: true));
      print('DEBUG: Direct document update successful for $visitorId');

      print('DEBUG: Searching for documents with visitorId field: $visitorId');
      // Also try querying by visitorId field if docId is different
      final query = await _firestore
          .collection('visitor_register')
          .where('visitorId', isEqualTo: visitorId)
          .get();

      print(
          'DEBUG: Found ${query.docs.length} documents via query for field visitorId');
      for (var doc in query.docs) {
        print('DEBUG: Updating document via query: ${doc.id}');
        await doc.reference.update(profileUpdate);
      }
      print('DEBUG: Profile sync for $visitorId completed successfully');
    } catch (e, stack) {
      print('DEBUG ERROR: Failed to update profile status for $visitorId: $e');
      print('STACKTRACE: $stack');
      rethrow;
    }
  }
}
