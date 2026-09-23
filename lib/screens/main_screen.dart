import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'search/search_screen.dart';
import 'profile/profile_screen.dart';
import '../widgets/floating_navbar.dart';
import '../widgets/dynamic_global_background.dart';

final GlobalKey<MainScreenState> mainScreenKey = GlobalKey<MainScreenState>();

class MainScreen extends StatefulWidget {
  MainScreen() : super(key: mainScreenKey);

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  int get currentTab => _currentIndex;

  void switchToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  final List<Widget> _pages = [
    const HomeScreen(),
    const SearchScreen(),
    const ProfileScreen(),
  ];

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by DynamicGlobalBackground
      resizeToAvoidBottomInset: false, // Prevents keyboard from pushing the floating navbar up
      extendBody: true, // Crucial for floating navbar to sit over content
      body: Stack(
        children: [
          // The dynamic liquid glass ambient background
          const Positioned.fill(
            child: DynamicGlobalBackground(),
          ),
          
          // The underlying pages
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          
          // Floating Navigation Bar overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: FloatingNavbar(
              currentIndex: _currentIndex,
              onTabSelected: _onTabSelected,
            ),
          ),
        ],
      ),
    );
  }
}
