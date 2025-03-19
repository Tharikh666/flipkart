import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flipkart/screens/home.dart';
import 'package:flipkart/screens/categories.dart';
import 'package:flipkart/screens/account.dart';

class Navigate extends StatefulWidget {
  const Navigate({super.key});

  @override
  State<Navigate> createState() => _NavigateState();
}

class _NavigateState extends State<Navigate> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    Home(),
    Categories(),
    Account(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              offset: Offset(2, 2),
              spreadRadius: 1
            )
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          selectedItemColor: CupertinoColors.activeBlue,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          items: [
            BottomNavigationBarItem(
              icon: Icon(_currentIndex == 0
                  ? CupertinoIcons.house_fill
                  : CupertinoIcons.house),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(_currentIndex == 1
                  ? CupertinoIcons.square_grid_2x2_fill
                  : CupertinoIcons.square_grid_2x2),
              label: "Categories",
            ),
            BottomNavigationBarItem(
              icon: Icon(_currentIndex == 2
                  ? CupertinoIcons.person_fill
                  : CupertinoIcons.person),
              label: "Account",
            ),
            // BottomNavigationBarItem(
            //   icon: Icon(Icons.call),
            //   label: "Calls",
            // ),
          ],
        ),
      ),
    );
  }
}
