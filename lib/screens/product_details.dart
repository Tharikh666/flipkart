import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flipkart/screens/cart.dart';
import 'package:flutter/material.dart';

class ProductDetails extends StatelessWidget {
  final String? userId;
  final String productId;
  final String name;
  final String item;
  final String price;
  final String exPrice;
  final double rating;
  final List<String> images;

  const ProductDetails({
    super.key,
    this.userId,
    required this.productId,
    required this.name,
    required this.item,
    required this.price,
    required this.exPrice,
    required this.rating,
    required this.images,
  });

  @override
  Widget build(BuildContext context) {
    int discount = _calculateDiscount(price, exPrice);

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: const Color(0xFFB0D4F1),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: () {
              // Implement share functionality later
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Cart(
                    userId: userId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image Carousel
            SizedBox(
              height: 300,
              child: PageView.builder(
                itemCount:
                    images.where((img) => img.isNotEmpty).toList().length,
                itemBuilder: (context, index) {
                  return Image.network(
                    images[index],
                    fit: BoxFit.contain,
                    width: double.infinity,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Product Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),

            // Rating Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Text(
                          "$rating",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(Icons.star, size: 12, color: Colors.white),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text("Free Delivery",
                      style: TextStyle(color: Colors.green, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Price & Discount
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Text(
                    "₹$price",
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "₹$exPrice",
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "$discount% off",
                    style: const TextStyle(fontSize: 18, color: Colors.red),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Description Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                item,
                style: const TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),

      // Bottom Buttons
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () => addToCart(context, userId!, productId),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepPurple,
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Add to Cart",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () => _buyNow(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.deepPurple,
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Buy Now",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // 🎯 Calculate Discount Percentage (handles commas too)
  int _calculateDiscount(String price, String exPrice) {
    double parsePrice(String value) =>
        double.tryParse(value.replaceAll(',', '')) ?? 0;
    double priceValue = parsePrice(price);
    double exPriceValue = parsePrice(exPrice);

    if (exPriceValue <= priceValue || exPriceValue == 0) return 0;
    return (((exPriceValue - priceValue) / exPriceValue) * 100).round();
  }

  Future<void> addToCart(BuildContext context, String userId, String productId) async {
    try {
      final cartRef = FirebaseFirestore.instance.collection('cart');

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



  // 🛍️ Buy Now Functionality (Navigate to Checkout)
  void _buyNow(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Redirecting to Checkout...")),
    );

    // Replace with actual checkout navigation
  }
}
