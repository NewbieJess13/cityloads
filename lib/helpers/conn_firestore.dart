import 'package:cloud_firestore/cloud_firestore.dart';

class DbFirestore {
  final _firestore = FirebaseFirestore.instance;

  getKeys() async {
    return await _firestore.collection('settings').doc('global_keys').get();
  }

  getAboutTerms() async {
    return await _firestore.collection('settings').doc('about_terms').get();
  }

  getPrivacyPolicy() async {
    return await _firestore.collection('settings').doc('privacy_policy').get();
  }

  getPaypalCharge() async {
    return await _firestore.collection('settings').doc('paypal_charge').get();
  }

  getAdminCredential() async {
    return await _firestore
        .collection('settings')
        .doc('admin_credential')
        .get();
  }
}
