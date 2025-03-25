import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flipkart/screens/navigation_bar.dart';
import 'package:flipkart/screens/product_details.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'login.dart';

class Cart extends StatefulWidget {
  const Cart({super.key, this.userId});
  final String? userId;

  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> {
  String? userName;
  int? superCoins;
  User? user;
  StreamSubscription<User?>? authSubscription;

  @override
  void initState() {
    super.initState();

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
          userName = null; // Reset user data when logged out
          superCoins = null;
        });
      }
    });
  }

  Future<void> fetchUserDetails(String uid) async {
    try {
      var userDoc = await FirebaseFirestore.instance
          .collection('userDetails')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        print("User data fetched: ${userDoc.data()}");

        if (mounted) {
          setState(() {
            userName = userDoc.data()?['name'] as String?;
            superCoins = (userDoc.data()?['supercoin'] ?? 0) as int;
          });
        }
      } else {
        print("User document not found in Firestore.");
      }
    } catch (e) {
      print("Error fetching user details: $e");
    }
  }

  @override
  void dispose() {
    authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Cart"),
        backgroundColor: const Color(0xFFB0D4F1),
      ),
      body: widget.userId == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icons/cart_icon.png',
                    width: 96,
                    height: 96,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Missing Items from your Cart?",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Login()),
                        ).then((_) {
                          if (FirebaseAuth.instance.currentUser != null) {
                            fetchUserDetails(
                                FirebaseAuth.instance.currentUser!.uid);
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CupertinoColors.systemBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Login'),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Navigate(),
                        ),
                      );
                    },
                    child: Text(
                      "Continue Shopping",
                      style: TextStyle(
                        color: CupertinoColors.activeBlue,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('cart')
                  .where('userId', isEqualTo: widget.userId)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                      child: Text("Error loading cart: ${snapshot.error}"));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Your cart is empty!"));
                }

                final cartItems = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final cartItem = cartItems[index];
                    final productId = cartItem['productId'];
                    final quantity = cartItem['quantity'] ?? 1;

                    return FutureBuilder(
                      future: FirebaseFirestore.instance
                          .collection('products')
                          .doc(productId)
                          .get(),
                      builder: (context,
                          AsyncSnapshot<DocumentSnapshot> productSnapshot) {
                        if (productSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (!productSnapshot.hasData ||
                            !productSnapshot.data!.exists) {
                          return const SizedBox();
                        }

                        final productData = productSnapshot.data!.data()
                            as Map<String, dynamic>;

                        String name = productData['name'] ?? "No Name";
                        String image = productData['img1'] ?? "";
                        String item = productData['item'] ?? "";
                        String price = productData['price']?.toString() ?? "0";
                        String exPrice =
                            productData['exPrice']?.toString() ?? "0";
                        double rating = productData['rating'] is int
                            ? (productData['rating'] as int).toDouble()
                            : (productData['rating'] ?? 4.0);
                        int discount = _calculateDiscount(price, exPrice);

                        return Card(
                          margin: const EdgeInsets.all(8.0),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                image,
                                width: 80,
                                height: 120,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image,
                                        size: 80, color: Colors.grey),
                              ),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: "₹$price ",
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        TextSpan(
                                          text: "₹$exPrice ",
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                            decoration:
                                                TextDecoration.lineThrough,
                                            decorationColor: Colors.grey,
                                          ),
                                        ),
                                        TextSpan(
                                          text: " • $discount% off",
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 135,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        width: 1.25,
                                        color: Colors.grey,
                                      ),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Expanded(
                                          child: Center(
                                            child: IconButton(
                                              icon: const Icon(Icons.remove,
                                                  color: Colors.red, size: 16),
                                              onPressed: () => _updateQuantity(
                                                  productId, quantity - 1),
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 1,
                                          color: Colors.grey,
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 4),
                                        ),
                                        Expanded(
                                          child: Center(
                                            child: Text(
                                              "Qty: $quantity",
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 1,
                                          color: Colors.grey,
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 4),
                                        ),
                                        Expanded(
                                          child: Center(
                                            child: IconButton(
                                              icon: const Icon(Icons.add,
                                                  color: Colors.green,
                                                  size: 16),
                                              onPressed: () => _updateQuantity(
                                                  productId, quantity + 1),
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_rounded,
                                  color: Colors.red),
                              onPressed: () => _showCartRemoveConfirmation(
                                  context, productId),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductDetails(
                                    userId: widget.userId,
                                    productId: productId,
                                    name: name,
                                    item: item,
                                    price: price,
                                    exPrice: exPrice,
                                    rating: rating,
                                    images: [
                                      productData['img1'] ?? "",
                                      productData['img2'] ?? "",
                                      productData['img3'] ?? "",
                                      productData['img4'] ?? "",
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
      bottomNavigationBar: widget.userId != null
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Navigate(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 8),
                    ),
                    child: const Text(
                      "Continue Shopping",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _checkout(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 8),
                    ),
                    child: const Text(
                      "Proceed to Checkout",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox(),
    );
  }

  // ➕➖ Increase or Decrease Quantity (removes item if 0)
  Future<void> _updateQuantity(String productId, int newQuantity) async {
    try {
      final cartDocs = await FirebaseFirestore.instance
          .collection('cart')
          .where('userId', isEqualTo: widget.userId)
          .where('productId', isEqualTo: productId)
          .get();

      if (cartDocs.docs.isNotEmpty) {
        if (newQuantity <= 0) {
          // ❌ If quantity is 0, remove the item
          await _removeFromCart(productId);
        } else {
          // ✅ Update quantity in Firestore
          await cartDocs.docs.first.reference.update({'quantity': newQuantity});
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update quantity: $e")),
      );
    }
  }

  // ❌ Remove Item from Cart
  Future<void> _removeFromCart(String productId) async {
    try {
      final cartDocs = await FirebaseFirestore.instance
          .collection('cart')
          .where('userId', isEqualTo: widget.userId)
          .where('productId', isEqualTo: productId)
          .get();

      for (var doc in cartDocs.docs) {
        await doc.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Item removed from cart!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to remove item: $e")),
      );
    }
  }

  // Function to show the confirmation dialog
  void _showCartRemoveConfirmation(BuildContext context, String productId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove from Cart?'),
          content: const Text(
              'Are you sure you want to remove this item from your cart?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Cancel button
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _removeFromCart(productId); // Call the removal function
              },
              child: const Text(
                'Remove',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // 🛍️ Checkout Functionality
  void _checkout(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Proceeding to Checkout...")),
    );

    // TODO: Implement checkout functionality
  }

  // 🎯 Calculate Discount Percentage
  int _calculateDiscount(String price, String exPrice) {
    double parsePrice(String value) =>
        double.tryParse(value.replaceAll(',', '')) ?? 0;
    double priceValue = parsePrice(price);
    double exPriceValue = parsePrice(exPrice);

    if (exPriceValue <= priceValue || exPriceValue == 0) return 0;
    return (((exPriceValue - priceValue) / exPriceValue) * 100).round();
  }
}
