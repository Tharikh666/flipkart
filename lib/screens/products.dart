import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flipkart/screens/product_details.dart';
import 'package:flutter/material.dart';

class Products extends StatefulWidget {
  final String productLabel;
  final String productItem;

  const Products({
    super.key,
    required this.productLabel,
    required this.productItem,
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
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
          ),
          child: TextFormField(
            decoration: InputDecoration(
              hintText: widget.productLabel,
              hintStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: InputBorder.none,
            ),
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.shopping_cart_outlined, color: Colors.black),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: ProductBody(itemType: widget.productItem),
      ),
    );
  }
}

// 🎯 ProductBody dynamically loads content based on itemType
class ProductBody extends StatelessWidget {
  final String itemType;

  const ProductBody({super.key, required this.itemType});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("products")
          .where("item", isEqualTo: itemType) // Filters by item type
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No products found."));
        }

        var products = snapshot.data!.docs;

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
            return ProductCard(
                product: products[index].data() as Map<String, dynamic>);
          },
        );
      },
    );
  }
}

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product; // Pass the full product map

  const ProductCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
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
            // Product Image
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
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
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
                  // Price, Discount, and Original Price
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
                  // Product Rating
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
      // Remove commas and parse the number
      String cleanedValue = value.replaceAll(',', '');
      return double.tryParse(cleanedValue) ?? 0;
    }

    double priceValue = parsePrice(price);
    double exPriceValue = parsePrice(exPrice);

    if (exPriceValue <= priceValue || exPriceValue == 0) return 0;

    return (((exPriceValue - priceValue) / exPriceValue) * 100).round();
  }
}
