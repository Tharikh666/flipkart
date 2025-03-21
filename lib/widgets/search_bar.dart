import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../screens/products.dart';

class SearchBarWidget extends StatefulWidget {
  final List<String>? hintTexts;
  final String? hintText;
  final bool showTrailing;
  final Function(String)? onSubmitted;

  const SearchBarWidget({
    super.key,
    this.hintTexts,
    this.hintText,
    this.showTrailing = true,
    this.onSubmitted,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  late List<String> _hintTexts;
  int _currentHintIndex = 0;
  late Timer _hintTimer;

  @override
  void initState() {
    super.initState();

    // Use provided hint texts or default ones
    _hintTexts = widget.hintTexts ??
        [
          "Fashion",
          "TV",
          "Laptops",
          "Mobiles",
          "Watches",
          "Food",
          "Accessories",
          "Shoes",
          "Furniture"
        ];

    // Timer to rotate hints every 2 seconds
    _hintTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _currentHintIndex = (_currentHintIndex + 1) % _hintTexts.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _hintTimer.cancel();
    super.dispose();
  }

  // ✅ Improved search logic
  void _searchProducts(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    try {
      final queryLower = query.toLowerCase();

      final allProducts =
          await FirebaseFirestore.instance.collection('products').get();

      setState(() {
        _searchResults = allProducts.docs
            .map((doc) => doc.data())
            .where((product) =>
                product['name'].toString().toLowerCase().contains(queryLower) ||
                product['item'].toString().toLowerCase().contains(queryLower))
            .toList();

        if (_searchResults.isEmpty) {
          _searchResults = [
            {"name": "No products found", "item": ""}
          ];
        }
      });
    } catch (e) {
      print("Error searching products: $e");
      setState(() {
        _searchResults = [
          {"name": "Error loading products", "item": "Please try again"}
        ];
      });
    }
  }

  // ✅ Navigate to product detail page for a specific product
  void _navigateToProductDetail(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Products(
          productLabel: product['name'] ?? 'Unknown',
          productItem: product['item'] ?? 'No Details',
        ),
      ),
    );
  }

  // ✅ Navigate to search results page when pressing Enter/Done key
  void _navigateToResultsPage(String query) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Products(
          productLabel: query,
          productItem: _searchResults.isNotEmpty
              ? _searchResults.first['item'] ?? 'No Details'
              : 'No results found',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: SearchAnchor(
        builder: (context, controller) {
          return SearchBar(
            backgroundColor: WidgetStateProperty.all<Color>(Colors.white),
            controller: _searchController,
            hintText: widget.hintText ?? _hintTexts[_currentHintIndex],
            hintStyle: WidgetStateProperty.all<TextStyle>(
              const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            leading: const Icon(
              Icons.search,
              color: CupertinoColors.activeBlue,
            ),

            // ✅ Show dropdown suggestions on text change
            onChanged: (query) => _searchProducts(query),

            // ✅ Keep Enter/Done key navigation working
            onSubmitted: (query) {
              if (widget.onSubmitted != null) {
                widget.onSubmitted!(query);
              }
              if (_searchResults.isNotEmpty) {
                _navigateToResultsPage(query);
              }
            },

            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(
                    color: CupertinoColors.activeBlue, width: 1),
              ),
            ),
            trailing: widget.showTrailing
                ? [
                    Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: Icon(
                        Icons.photo_camera_outlined,
                        color: CupertinoColors.activeBlue,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Icon(
                        Icons.qr_code_scanner,
                        color: CupertinoColors.activeBlue,
                      ),
                    ),
                  ]
                : null,
          );
        },

        // ✅ Show suggestion dropdown immediately
        suggestionsBuilder: (context, controller) {
          if (_searchResults.isEmpty) {
            return [const ListTile(title: Text('No results found'))];
          }

          return _searchResults.map((product) {
            return ListTile(
              title: Text(product['name'] ?? ''),
              subtitle: Text(product['item'] ?? ''),
              onTap: () {
                controller.closeView(product['name'] ?? '');
                _navigateToProductDetail(product);
              },
            );
          }).toList();
        },
      ),
    );
  }
}
