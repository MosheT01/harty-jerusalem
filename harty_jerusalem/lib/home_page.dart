import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'nidaa_page.dart';
import 'profile_page.dart';
import 'newsfeed_page.dart';
import 'events_page.dart';
import 'login_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<String> sections = [
    "أخبار حارتي",
    "نداء",
    "أحداث",
  ];

  final List<BottomNavigationBarItem> _navBarItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.newspaper),
      label: "أخبار حارتي",
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.campaign),
      label: "نداء",
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.event),
      label: "أحداث",
    ),
  ];

  final List<Widget> _pages = [
    const NewsfeedPage(),
    const NidaaPage(),
    const EventsPage(),
  ];

  void _logout() async {
    try {
      await _auth.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيل الخروج بنجاح')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في تسجيل الخروج: $e')),
      );
    }
  }

  void _openDashboard() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('ملف شخصي', textAlign: TextAlign.right),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfilePage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('تسجيل الخروج', textAlign: TextAlign.right),
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        // title: Row(
        //   mainAxisAlignment: MainAxisAlignment.spaceAround,
        //   children: sections.asMap().entries.map((entry) {
        //     int index = entry.key;
        //     String section = entry.value;
        //     return GestureDetector(
        //       onTap: () {
        //         setState(() {
        //           _currentIndex = index;
        //         });
        //         _pageController.jumpToPage(index);
        //       },
        //       child: Text(
        //         section,
        //         style: TextStyle(
        //           fontSize: 18,
        //           fontWeight: FontWeight.bold,
        //           decoration: _currentIndex == index
        //               ? TextDecoration.underline
        //               : TextDecoration.none,
        //         ),
        //       ),
        //     );
        //   }).toList(),
        // ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: _openDashboard,
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            _pageController.jumpToPage(index);
          },
          backgroundColor: theme.colorScheme.primary,
          selectedItemColor: theme.colorScheme.onPrimary,
          unselectedItemColor: theme.colorScheme.onPrimary.withOpacity(0.6),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          type: BottomNavigationBarType.fixed,
          items: _navBarItems,
        ),
      ),
    );
  }
}
