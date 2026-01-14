import 'package:cloud_firestore/cloud_firestore.dart';

class RequestService {
  static Future<void> approveRequest(String docId) async {
    await FirebaseFirestore.instance
        .collection('requests')
        .doc(docId)
        .update({'status': 'approved'});
  }

  static Future<void> fulfillRequest(String docId) async {
    await FirebaseFirestore.instance
        .collection('requests')
        .doc(docId)
        .update({'status': 'fulfilled'});
  }
}