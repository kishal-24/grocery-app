import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUserProfile({
    required User user,
    String? username,
    String? name,
    String? phone,
    String? dob,
    String? gender,
    String? avatar,
    String? profileImage,
  }) async {
    final cleanUsername = username?.trim();
    final cleanName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : (user.displayName ?? (cleanUsername ?? ''));

    await _firestore.collection('users').doc(user.uid).set({
      'name': cleanName,
      'email': user.email ?? '',
      'username': cleanUsername ?? '',
      'usernameLower': cleanUsername?.toLowerCase() ?? '',
      'username_lowercase': cleanUsername?.toLowerCase() ?? '',
      'phone': phone ?? (user.phoneNumber ?? ''),
      'dob': dob ?? '',
      'gender': gender ?? 'Prefer not to say',
      'avatar': avatar ?? '0',
      'profileImage': profileImage ?? '',
      'customImage': profileImage ?? '',
      'role': 'customer',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists) {
      return null;
    }

    return doc.data();
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    final Map<String, dynamic> updates = Map<String, dynamic>.from(data);
    // Role field is protected by Firestore security rules
    updates.remove('role');
    updates['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore
        .collection('users')
        .doc(uid)
        .set(updates, SetOptions(merge: true));
  }

  Stream<Map<String, dynamic>?> streamUserProfile(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.data());
  }
}