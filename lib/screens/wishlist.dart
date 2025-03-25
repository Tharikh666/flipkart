import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flipkart/screens/product_details.dart';

import 'cart.dart';

class Wishlist extends StatefulWidget {
  final String? userId;

  const Wishlist({super.key, this.userId});

  @override
  State<Wishlist> createState() => _WishlistState();
}

class _WishlistState extends State<Wishlist> {
  final CollectionReference wishlistRef =
      FirebaseFirestore.instance.collection('wishlist');

  final CollectionReference cartRef =
      FirebaseFirestore.instance.collection('cart');

  Future<void> _removeFromWishlist(String productId) async {
    final snapshot = await wishlistRef
        .where('userId', isEqualTo: widget.userId)
        .where('productId', isEqualTo: productId)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Removed from Wishlist')),
    );
  }

// Function to show the confirmation dialog
  void _showDeleteConfirmation(BuildContext context, String productId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text(
              'Are you sure you want to remove this item from your wishlist?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Cancel
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _removeFromWishlist(productId); // Proceed with deletion
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> addToCart(
      BuildContext context, String? userId, String productId) async {
    try {
      final cartRef = FirebaseFirestore.instance.collection('cart');

      print("userId: $userId, productId: $productId");

      // Check if the product is already in the cart
      final existingCartItem = await cartRef
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .get();

      if (existingCartItem.docs.isNotEmpty) {
        // ✅ Product already in cart — increase quantity
        final cartDoc = existingCartItem.docs.first;
        final currentQuantity = cartDoc['quantity'] ?? 1;

        await cartRef.doc(cartDoc.id).update({
          'quantity': currentQuantity + 1,
        });
      } else {
        // ✅ Product not in cart — add it with quantity 1
        await cartRef.add({
          'userId': userId,
          'productId': productId,
          'quantity': 1,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product added to cart!")),
      );

      // 🚀 Navigate to Cart page after adding product
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Cart(userId: userId),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add to cart: $e")),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    // ✅ Print userId for debugging
    if (widget.userId != null && widget.userId!.isNotEmpty) {
      print("userId: ${widget.userId}");
    } else {
      print("userId is null or empty");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        title: const Text(
          'My Wishlist',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: CupertinoColors.activeBlue,
      ),
      body: StreamBuilder(
        stream:
            wishlistRef.where('userId', isEqualTo: widget.userId).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error loading wishlist"));
          }

          final wishlistItems = snapshot.data?.docs ?? [];

          // ✅ Empty Wishlist UI
          if (wishlistItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icons/empty_wishlist.png',
                    width: 150,
                    height: 150,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Your Wishlist is Empty!",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Save items to buy later",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // ✅ Wishlist Grid UI
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: wishlistItems.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: 300),
            itemBuilder: (context, index) {
              final wishlistItem = wishlistItems[index];
              final productId = wishlistItem['productId'];

              return FutureBuilder(
                future: FirebaseFirestore.instance
                    .collection('products')
                    .doc(productId)
                    .get(),
                builder:
                    (context, AsyncSnapshot<DocumentSnapshot> productSnapshot) {
                  if (productSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!productSnapshot.hasData ||
                      !productSnapshot.data!.exists) {
                    return const SizedBox();
                  }

                  final productData =
                      productSnapshot.data!.data() as Map<String, dynamic>;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetails(
                            userId: widget.userId,
                            productId: productId,
                            name: productData['name'] ?? "No Name",
                            item: productData['item'] ?? "No Description",
                            price: productData['price']?.toString() ?? "0",
                            exPrice: productData['exPrice']?.toString() ?? "0",
                            rating: productData['rating'] ?? 4.0,
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
                    child: Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Image.network(
                                  productData['img1'] ?? "",
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image,
                                          size: 80, color: Colors.grey),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  productData['name'] ?? "No Name",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                "₹${productData['price']}",
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          CupertinoColors.activeBlue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4.0, vertical: 8.0),
                                    ),
                                    onPressed: () => addToCart(
                                        context, widget.userId, productId),
                                    icon: const Icon(
                                      Icons.shopping_cart,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    label: const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text('Add to Cart'),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                _showDeleteConfirmation(context, productId),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
