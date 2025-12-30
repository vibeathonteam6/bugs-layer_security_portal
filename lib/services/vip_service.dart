import 'package:cloud_firestore/cloud_firestore.dart';

class VipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates a new VIP ticket with auto-approval and unrestricted access.
  /// This bypasses standard registration/approval flows.
  Future<String> createVipTicket({
    required String vipName,
    required String designation,
    required String organization,
    required String escortOperatorId,
    required String escortName,
    String? vehicleNumber,
  }) async {
    final docRef = _firestore.collection('vip_tickets').doc();

    final Map<String, dynamic> vipData = {
      'ticketId': docRef.id,
      'vipName': vipName,
      'designation': designation,
      'organization': organization,
      'vehicleNumber': vehicleNumber,
      'escortOperatorId': escortOperatorId,
      'escortName': escortName,
      'status': 'AUTO_APPROVED',
      'unrestrictedAccess': true,
      'createdAt': FieldValue.serverTimestamp(),
      'lastCheckpoint': 'Creation',
      'lastScanAt': FieldValue.serverTimestamp(),
    };

    await docRef.set(vipData);

    // Log the creation activity
    await logVipActivity(
      operatorId: escortOperatorId,
      targetVipId: docRef.id,
      actionType: 'CREATION',
      locationId: 'Operator Module',
    );

    return docRef.id;
  }

  /// Returns a stream of all active VIP tickets ordered by creation time.
  Stream<QuerySnapshot> getActiveVipTickets() {
    return _firestore
        .collection('vip_tickets')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Logs a VIP movement or action for audit purposes.
  Future<void> logVipActivity({
    required String operatorId,
    required String targetVipId,
    required String actionType, // CREATION | BYPASS | DEPARTURE
    required String locationId,
  }) async {
    final logRef = _firestore.collection('operator_activity_logs').doc();

    final Map<String, dynamic> logData = {
      'logId': logRef.id,
      'operatorId': operatorId,
      'targetVipId': targetVipId,
      'actionType': actionType,
      'locationId': locationId,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await logRef.set(logData);

    // Update the VIP ticket's heartbeat if it's a bypass action
    if (actionType == 'BYPASS') {
      await _firestore.collection('vip_tickets').doc(targetVipId).update({
        'lastCheckpoint': locationId,
        'lastScanAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Fetches a specific VIP ticket by ID
  Future<DocumentSnapshot?> getVipTicketById(String ticketId) async {
    try {
      final doc =
          await _firestore.collection('vip_tickets').doc(ticketId).get();
      return doc.exists ? doc : null;
    } catch (e) {
      print('Error fetching VIP ticket: $e');
      return null;
    }
  }
}
