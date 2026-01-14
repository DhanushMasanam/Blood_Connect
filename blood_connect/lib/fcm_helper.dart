import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> saveFcmToken() async {
  final User? user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  String? token = await FirebaseMessaging.instance.getToken();

  if (token != null) {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'fcmToken': token,
    });
  }

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'fcmToken': newToken,
    });
  });
}