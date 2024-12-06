import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'nidaa_page.dart';
import 'newsfeed_page.dart';
import 'events_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'حارتي',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Color(0xFFF5F5DC), // لون بني فاتح
        appBarTheme: const AppBarTheme(
          color: Colors.white,
          iconTheme: IconThemeData(color: Colors.green),
          titleTextStyle: TextStyle(
            color: Colors.green,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.green,
        ),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> sections = [
    "أخبار حارتي",
    "نداء",
    "أحداث",
  ];
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: sections.asMap().entries.map((entry) {
            int index = entry.key;
            String section = entry.value;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _currentIndex = index;
                });
                _pageController.jumpToPage(index);
              },
              child: Text(
                section,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  decoration: _currentIndex == index ? TextDecoration.underline : TextDecoration.none,
                ),
              ),
            );
          }).toList(),
        ),
        centerTitle: true,
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          NewsfeedPage(),
          NidaaPage(),
          EventsPage(),
        ],
      ),
    );
  }
}
