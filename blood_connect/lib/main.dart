import 'package:blood_connect/screens/donor_history_screen.dart';
import 'package:blood_connect/screens/request_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:blood_connect/screens/login_screen.dart';
import 'package:blood_connect/screens/signup_screen.dart';
import 'package:blood_connect/screens/donor_dashboard.dart';
import 'package:blood_connect/screens/recipient_dashboard.dart';
import 'package:blood_connect/screens/admin_dashboard.dart';
import 'package:blood_connect/screens/notification_screen.dart';
import 'package:blood_connect/screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBV3liZdOGpQYbAA296HKVcPpbfNQqlmH0",
      authDomain: "bloodconnect-4md03.firebaseapp.com",
      projectId: "bloodconnect-4md03",
      storageBucket: "bloodconnect-4md03.appspot.com",
      messagingSenderId: "494957733922",
      appId: "1:494957733922:web:a6927fcc3b1811f618427b",
      measurementId: "G-ZSD6X2T435",
    ),
  );

  runApp(BloodConnectApp());
}

class BloodConnectApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BloodConnect',
      theme: ThemeData(primarySwatch: Colors.red),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/recipientDashboard': (context) => RecipientDashboard(),
        '/donorDashboard': (context) => DonorDashboard(),
        '/adminDashboard': (context) => AdminDashboard(),
        '/requestHistory': (context) => RequestHistoryScreen(),
        '/donorHistory': (context) => DonorHistoryScreen(),
        '/notifications': (context) => NotificationsScreen(),
        '/profile': (context) => ProfileScreen(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  List<Widget> _screens = [];
  List<BottomNavigationBarItem> _navItems = [];

  @override
  void initState() {
    super.initState();
    _setupNavigation();
  }

  Future<void> _setupNavigation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();
      final role = (doc.data()?['role'] as String?) ?? 'Recipient';

      setState(() {
        if (role == "Admin") {
          _screens = [AdminDashboard(), NotificationsScreen(), ProfileScreen()];
          _navItems = const [
            BottomNavigationBarItem(
                icon: Icon(Icons.admin_panel_settings), label: "Admin"),
            BottomNavigationBarItem(
                icon: Icon(Icons.notifications), label: "Notifications"),
            BottomNavigationBarItem(
                icon: Icon(Icons.person), label: "Profile"),
          ];
        } else if (role == "Donor") {
          _screens = [
            DonorDashboard(),
            DonorHistoryScreen(),
            NotificationsScreen(),
            ProfileScreen(),
          ];
          _navItems = const [
            BottomNavigationBarItem(
                icon: Icon(Icons.volunteer_activism), label: "Donor"),
            BottomNavigationBarItem(
                icon: Icon(Icons.history), label: "History"),
            BottomNavigationBarItem(
                icon: Icon(Icons.notifications), label: "Notifications"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ];
        } else {
          _screens = [
            RecipientDashboard(),
            RequestHistoryScreen(),
            NotificationsScreen(),
            ProfileScreen(),
          ];
          _navItems = const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Recipient"),
            BottomNavigationBarItem(
                icon: Icon(Icons.history), label: "History"),
            BottomNavigationBarItem(
                icon: Icon(Icons.notifications), label: "Notifications"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ];
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading navigation: $e")),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_screens.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.red,
        items: _navItems,
      ),
    );
  }
}