import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Handles the anonymous account and the link between two partners.
///
/// Firestore layout:
///   users/{uid} -> { pairCode, partnerUid?, fcmToken }
class PairingService {
  PairingService({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
    FirebaseMessaging? messaging,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance,
        _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseMessaging _messaging;

  String get uid => _auth.currentUser!.uid;

  /// Signs in anonymously, creates the user doc if needed and stores the push token.
  Future<void> init() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
    await _messaging.requestPermission();

    final ref = _db.collection('users').doc(uid);
    final snap = await ref.get();
    final token = await _messaging.getToken();

    if (!snap.exists) {
      await ref.set({
        'pairCode': _generateCode(),
        'fcmToken': token,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else if (token != null) {
      await ref.update({'fcmToken': token});
    }

    _messaging.onTokenRefresh.listen((t) => ref.update({'fcmToken': t}));
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> myDoc() =>
      _db.collection('users').doc(uid).snapshots();

  /// Links this user with the owner of [code]. Returns false if the code is unknown
  /// or is our own.
  Future<bool> pairWith(String code) async {
    final cleaned = code.trim().toUpperCase();
    final query = await _db
        .collection('users')
        .where('pairCode', isEqualTo: cleaned)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return false;

    final partner = query.docs.first;
    if (partner.id == uid) return false;

    final batch = _db.batch();
    batch.update(_db.collection('users').doc(uid), {'partnerUid': partner.id});
    batch.update(partner.reference, {'partnerUid': uid});
    await batch.commit();
    return true;
  }

  /// Either side can unlink at any time.
  Future<void> unpair(String partnerUid) async {
    final batch = _db.batch();
    batch.update(
      _db.collection('users').doc(uid),
      {'partnerUid': FieldValue.delete()},
    );
    batch.update(
      _db.collection('users').doc(partnerUid),
      {'partnerUid': FieldValue.delete()},
    );
    await batch.commit();
  }

  static String _generateCode() {
    // No 0/O/1/I to avoid confusion when typing.
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    return List.generate(6, (_) => chars[rnd.nextInt(chars.length)]).join();
  }
}
