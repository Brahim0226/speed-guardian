import 'package:cloud_firestore/cloud_firestore.dart';

/// Creates an alert document. A Cloud Function (functions/index.js) picks it up
/// and sends the push notification to the partner.
class AlertService {
  AlertService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<void> sendOverspeedAlert({
    required String fromUid,
    required String toUid,
    required double speedKmh,
    required double limitKmh,
  }) {
    return _db.collection('alerts').add({
      'fromUid': fromUid,
      'toUid': toUid,
      'speedKmh': speedKmh.round(),
      'limitKmh': limitKmh.round(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
