import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../screens/login.dart';

class CustomAppBar extends StatelessWidget {
  final String? userId; // User ID to fetch details

  const CustomAppBar({super.key, this.userId});

  Future<String?> _getUserName() async {
    if (userId == null) return null; // User not logged in

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('userDetails')
          .doc(userId)
          .get();
      return userDoc.exists ? userDoc['name'] as String? : null;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getUserName(),
      builder: (context, snapshot) {
        String? userName = snapshot.data;

        return AppBar(
          backgroundColor: Colors.white,
          toolbarHeight: userName != null ? 140 : 56,
          leadingWidth: double.maxFinite,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: userName != null
                ? _buildLoggedInUser(context, userName)
                : _buildLoggedOutUser(context),
          ),
        );
      },
    );
  }

  Widget _buildLoggedInUser(BuildContext context, String userName) {
    return Container(
      width: double.maxFinite,
      height: 175,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue, width: 1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0, bottom: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User name
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const Login()));
                },
                child: Text(
                  userName,
                  style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            // Plus logo and arrow
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                children: [
                  Container(
                    width: 110,
                    height: 15,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/icons/plus_logo.png'),
                        fit: BoxFit.fitHeight,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                ],
              ),
            ),
            // Divider line
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: double.infinity,
                height: 0.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey, Colors.transparent],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
            // Supercoins balance
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 4.0, top: 4.0),
              child: Row(
                children: [
                  Text('Supercoins Balance', style: TextStyle(color: Colors.black, fontSize: 12)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Container(
                      width: 30,
                      height: 18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.yellow),
                        image: DecorationImage(
                          image: AssetImage('assets/icons/supercoin_icon_min.png'),
                          alignment: Alignment.centerLeft,
                          fit: BoxFit.fitHeight,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Text('0', textAlign: TextAlign.right),
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedOutUser(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Text('Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const Login()));
            },
            child: const Text('Log In', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }
}
