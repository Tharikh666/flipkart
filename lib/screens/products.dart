import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flipkart/screens/product_details.dart';
import 'package:flutter/cupertino.dart';
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
        actions: [
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
          crossAxisCount: 1,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.62,
          mainAxisExtent: 150),
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

class ProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final String productId;
  final String? userId;

  const ProductCard({
    super.key,
    this.userId,
    required this.product,
    required this.productId,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool isWishlisted = false;
  final CollectionReference wishlistRef =
  FirebaseFirestore.instance.collection('wishlist');

  @override
  void initState() {
    super.initState();
    _checkWishlistStatus();
  }

  // ✅ Check if product is already in the wishlist
  Future<void> _checkWishlistStatus() async {
    if (widget.userId == null) return;

    final snapshot = await wishlistRef
        .where('userId', isEqualTo: widget.userId)
        .where('productId', isEqualTo: widget.productId)
        .get();

    setState(() {
      isWishlisted = snapshot.docs.isNotEmpty;
    });
  }

  // 🔥 Toggle Wishlist: Add/Remove product
  Future<void> _toggleWishlist() async {
    if (widget.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to manage your wishlist!")),
      );
      return;
    }

    if (isWishlisted) {
      // ✅ Remove from wishlist
      final snapshot = await wishlistRef
          .where('userId', isEqualTo: widget.userId)
          .where('productId', isEqualTo: widget.productId)
          .get();

      for (var doc in snapshot.docs) {
        await wishlistRef.doc(doc.id).delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Removed from wishlist")),
      );
    } else {
      // ✅ Add to wishlist
      await wishlistRef.add({
        'userId': widget.userId,
        'productId': widget.productId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Added to wishlist")),
      );
    }

    setState(() => isWishlisted = !isWishlisted);
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

  @override
  Widget build(BuildContext context) {
    String name = widget.product['name'] ?? "No Name";
    String image = widget.product['img1'] ?? "";
    String price = widget.product['price'] ?? "0";
    String exPrice = widget.product['exPrice'] ?? "0";
    double rating = widget.product['rating'] is int
        ? (widget.product['rating'] as int).toDouble()
        : (widget.product['rating'] ?? 4.0);
    int discount = _calculateDiscount(price, exPrice);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetails(
              userId: widget.userId,
              productId: widget.productId,
              name: name,
              item: widget.product['item'] ?? "No Description",
              price: price,
              exPrice: exPrice,
              rating: rating,
              images: [
                widget.product['img1'] ?? "",
                widget.product['img2'] ?? "",
                widget.product['img3'] ?? "",
                widget.product['img4'] ?? "",
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📸 Product Image
            Container(
              width: 100,
              height: 150,
              decoration: BoxDecoration(
                image: image.isNotEmpty
                    ? DecorationImage(
                  image: NetworkImage(image),
                  fit: BoxFit.contain,
                )
                    : null,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(8),
                ),
              ),
              child: image.isEmpty
                  ? const Center(child: Icon(Icons.image_not_supported))
                  : null,
            ),

            // 📌 Product Details Section
            Expanded(
              child: Padding(
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

                    // ⭐ Product Rating
                    Row(
                      children: List.generate(
                        5,
                            (index) => Icon(
                          index < rating.round()
                              ? Icons.star
                              : Icons.star_border,
                          size: 14,
                          color: Colors.green,
                        ),
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
                          "$discount% off",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ❤️ Wishlist Icon with toggle
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 4),
              child: IconButton(
                onPressed: _toggleWishlist,
                icon: Icon(
                  isWishlisted ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                  color: isWishlisted ? Colors.red : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
