import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flipkart/screens/product_details.dart';
import 'package:flutter/material.dart';

import '../widgets/search_bar.dart';
import 'cart.dart';

class Products extends StatefulWidget {
  final String? userId;
  final String productLabel;
  final String productItem;
  final String? searchHint;
  final List<QueryDocumentSnapshot<Object?>>? matchedProducts;

  const Products({
    super.key,
    this.userId,
    required this.productLabel,
    required this.productItem,
    this.searchHint,
    this.matchedProducts,
  });

  @override
  State<Products> createState() => _ProductsState();
}

class _ProductsState extends State<Products> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB0D4F1),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: SearchBarWidget(
          userId: widget.userId,
          hintTexts: [],
          hintText: widget.searchHint ?? widget.productLabel,
          showTrailing: false,
        ),
        actions:  [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: IconButton(
              icon: Icon(Icons.shopping_cart, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Cart(
                      userId: widget.userId,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: ProductBody(
            userId: widget.userId,
            itemType: widget.productItem,
            matchedProducts: widget.matchedProducts),
      ),
    );
  }
}

// 🎯 ProductBody dynamically loads content based on itemType
class ProductBody extends StatelessWidget {
  final String itemType;
  final String? userId;
  final List<QueryDocumentSnapshot<Object?>>? matchedProducts;

  const ProductBody({
    super.key,
    required this.itemType,
    this.matchedProducts,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    print("✅ ProductBody received: ${matchedProducts?.length ?? 0} products");

    // 🛠️ Case 1: Show matched products if available
    if (matchedProducts != null && matchedProducts!.isNotEmpty) {
      print("matchedProducts is not empty");
      return _buildProductGrid(matchedProducts!);
    }

    // 🔍 Case 2: Fallback to category-wide stream fetch
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("products")
          .where("item", isEqualTo: itemType)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        // 🛑 No products in this category
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No products found."));
        }

        // ✅ Case 2 success: Load all products from this category
        var products = snapshot.data!.docs;
        print("matchedProducts is empty");
        return _buildProductGrid(products);
      },
    );
  }

  // 🔥 Extracted reusable grid builder
  Widget _buildProductGrid(List<QueryDocumentSnapshot<Object?>> products) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.62,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final productData = products[index].data() as Map<String, dynamic>;

        return ProductCard(
          userId: userId,
          product: productData,
          productId: products[index].id,
        );
      },
    );
  }
}

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final String productId;
  final String? userId;

  const ProductCard({
    super.key,
    this.userId,
    required this.product,
    required this.productId, // ✅ Require Firestore document ID
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Extract product data with safe fallbacks
    String name = product['name'] ?? "No Name";
    String image = product['img1'] ?? "";
    String price = product['price'] ?? "0";
    String exPrice = product['exPrice'] ?? "0";
    double rating = product['rating'] is int
        ? (product['rating'] as int).toDouble()
        : (product['rating'] ?? 4.0);
    int discount = _calculateDiscount(price, exPrice);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetails(
              userId: userId,
              productId: productId, // ✅ Pass the correct Firestore ID
              name: name,
              item: product['item'] ?? "No Description",
              price: price,
              exPrice: exPrice,
              rating: rating,
              images: [
                product['img1'] ?? "",
                product['img2'] ?? "",
                product['img3'] ?? "",
                product['img4'] ?? "",
              ],
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📸 Product Image
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  image: image.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(image),
                          fit: BoxFit.contain,
                        )
                      : null,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
                child: image.isEmpty
                    ? const Center(child: Icon(Icons.image_not_supported))
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🏷️ Product Name
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 💰 Price, Discount, and Original Price
                  Row(
                    children: [
                      Text(
                        "₹$price",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "₹$exPrice",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        " $discount% off",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // ⭐ Product Rating & Delivery Info
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
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
                            const Icon(Icons.star,
                                size: 12, color: Colors.white),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        "Free Delivery",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🎯 Calculate Discount Percentage (handles commas too)
  int _calculateDiscount(String price, String exPrice) {
    double parsePrice(String value) {
      String cleanedValue = value.replaceAll(',', ''); // 🔍 Clean commas
      return double.tryParse(cleanedValue) ?? 0;
    }

    double priceValue = parsePrice(price);
    double exPriceValue = parsePrice(exPrice);

    if (exPriceValue <= priceValue || exPriceValue == 0) return 0;

    return (((exPriceValue - priceValue) / exPriceValue) * 100).round();
  }
}
