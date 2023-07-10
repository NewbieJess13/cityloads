import 'package:cloud_firestore/cloud_firestore.dart';

class DbFirestore {
  final _firestore = FirebaseFirestore.instance;

  Future<DocumentSnapshot<Map<String, dynamic>>> getKeys() async =>
      await _firestore.collection('settings').doc('global_keys').get();

  Future<DocumentSnapshot<Map<String, dynamic>>> getAboutTerms() async {
    return await _firestore.collection('settings').doc('about_terms').get();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getPrivacyPolicy() async {
    return await _firestore.collection('settings').doc('privacy_policy').get();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getPaypalCharge() async {
    return await _firestore.collection('settings').doc('paypal_charge').get();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getAdminCredential() async {
    return await _firestore
        .collection('settings')
        .doc('admin_credential')
        .get();
  }
}
