import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'account.dart';
import 'cart.dart';
import 'categories.dart';
import 'home.dart';

class Navigate extends StatefulWidget {
  const Navigate({super.key});

  @override
  State<Navigate> createState() => _NavigateState();
}

class _NavigateState extends State<Navigate> {
  int _currentIndex = 0;

  String? userId;
  String? userName;
  String? address;
  String? pinCode;
  User? user;
  StreamSubscription<User?>? authSubscription;

  late List<Widget> _pages; // Declare _pages

  @override
  void initState() {
    super.initState();

    // ✅ Ensure pages are initialized early with placeholders
    _initializePages();

    // Listen for authentication state changes
    authSubscription =
        FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          this.user = user;
        });
      }

      if (user != null) {
        fetchUserDetails(user.uid); // Fetch user details using UID
      } else {
        print("User is NOT logged in.");
        setState(() {
          userId = null; // Reset user data when logged out
          userName = null;
          address = null;
          pinCode = null;
          _initializePages(); // Reset pages to placeholder state
        });
      }
    });
  }

  // 🔥 Ensure pages are initialized early (placeholder state)
  void _initializePages() {
    _pages = [
      const Home(),
      Categories(userId: userId,),
      const Account(),
      Cart(userId: userId), // Cart still accepts userId
    ];
  }

  Future<void> fetchUserDetails(String uid) async {
    try {
      var userDoc = await FirebaseFirestore.instance
          .collection('userDetails')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        if (mounted) {
          setState(() {
            userId = userDoc.id;
            userName = userDoc.data()?['name'] as String?;
            address = (userDoc.data()?['address'] ?? '') as String;
            pinCode = (userDoc.data()?['pin'] ?? '') as String;

            // ✅ Rebuild pages now with the correct user data
            _pages = [
              Home(
                userId: userId,
                userName: userName,
                address: address,
                pinCode: pinCode,
              ),
              Categories(
                userId: userId,
              ),
              const Account(),
              Cart(
                userId: userId,
              ),
            ];
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User document not found in Firestore")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching user details: $e")),
      );
    }
  }

  @override
  void dispose() {
    authSubscription?.cancel();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex], // ✅ No more LateInitializationError
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              offset: Offset(2, 2),
              spreadRadius: 1,
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
            BottomNavigationBarItem(
              icon: Icon(_currentIndex == 3
                  ? CupertinoIcons.cart_fill
                  : CupertinoIcons.cart),
              label: "Cart",
            ),
          ],
        ),
      ),
    );
  }
}
