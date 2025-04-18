import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

import '../screens/products.dart';

class FlipkartHomeCarousel extends StatefulWidget {
  final String? userId;
  const FlipkartHomeCarousel({super.key, this.userId});

  @override
  State<FlipkartHomeCarousel> createState() => _FlipkartHomeCarouselState();
}

class _FlipkartHomeCarouselState extends State<FlipkartHomeCarousel> {
  int activeIndex = 0;
  Future<List<Map<String, dynamic>>>? carouselItemsFuture;

  @override
  void initState() {
    super.initState();
    carouselItemsFuture = fetchCarouselItems();
  }

  Future<List<Map<String, dynamic>>> fetchCarouselItems() async {
    try {
      var snapshot =
          await FirebaseFirestore.instance.collection('carousel').get();
      return snapshot.docs
          .map((doc) => {
                'image': doc['image'],
                'text': doc['text'],
                'item': doc['item'],
                'product': doc['product']
              })
          .toList();
    } catch (e) {
      print('Error fetching carousel items: $e');
      return [];
    }
  }

  void navigateToProducts(
      BuildContext context, String product, String item) async {
    try {
      // Fetch products that match both 'item' and 'product' fields
      var productSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('item', isEqualTo: item)
          .where('name', isGreaterThanOrEqualTo: product)
          .where('name', isLessThanOrEqualTo: '$product\uf8ff')
          .get();

      // Extract the product documents
      List<QueryDocumentSnapshot> matchedProductsSnap = productSnapshot.docs;

      if (matchedProductsSnap.isNotEmpty) {
        // Navigate to products page with filtered products
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Products(
              userId: widget.userId,
              productLabel: product,
              productItem: item,
              matchedProducts: matchedProductsSnap,
            ),
          ),
        );
      } else {
        // No exact matches — fallback to showing the category
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Products(
              productLabel: "Results for \"$product\"",
              productItem: item,
              matchedProducts: matchedProductsSnap,
            ),
          ),
        );
      }
    } catch (e) {
      print("Error fetching products: $e");

      // Navigate to category results with an empty list or error message
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Products(
            productLabel: "Results for \"$product\"",
            productItem: item,
            matchedProducts: [], // Pass an empty list or handle error more gracefully
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: carouselItemsFuture,
      builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No carousel images available'));
        }

        var imageCarouselItems = snapshot.data!;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CarouselSlider(
              options: CarouselOptions(
                height: 200.0,
                autoPlay: true,
                enlargeCenterPage: true,
                viewportFraction: 1,
                onPageChanged: (index, reason) {
                  setState(() => activeIndex = index);
                },
              ),
              items: imageCarouselItems.map((item) {
                return GestureDetector(
                  onTap: () => navigateToProducts(
                      context, item['product'] ?? '', item['item'] ?? ''),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        width: double.maxFinite,
                        height: 210,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(item['image'] ?? ''),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Container(
                        width: double.maxFinite,
                        height: 35,
                        decoration: const BoxDecoration(color: Colors.black),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                item['text'] ?? '',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.arrow_forward_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 7),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                imageCarouselItems.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: activeIndex == index ? 24 : 10,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: activeIndex == index ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

extension StringExtension on String {
  String capitalize() => "${this[0].toUpperCase()}${substring(1)}";
}

class ElectronicsCarousel extends StatefulWidget {
  const ElectronicsCarousel({super.key});

  @override
  State<ElectronicsCarousel> createState() => _ElectronicsCarouselState();
}

class _ElectronicsCarouselState extends State<ElectronicsCarousel> {
  int activeIndex = 0;
  List<Map<String, String>> imageCarouselItems = [];

  @override
  void initState() {
    super.initState();
    _fetchCarouselItems();
  }

  Future<void> _fetchCarouselItems() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('electronicsCarousel')
          .get();

      setState(() {
        imageCarouselItems = snapshot.docs.map((doc) {
          return {
            'image': doc['image'] as String,
            'text': doc['text'] as String,
          };
        }).toList();
      });
    } catch (e) {
      setState(() {
        imageCarouselItems = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (imageCarouselItems.isEmpty) {
      return const Center(child: Text('No carousel images available'));
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 200.0,
            autoPlay: true,
            enlargeCenterPage: false,
            viewportFraction: 1,
            onPageChanged: (index, reason) {
              setState(() => activeIndex = index);
            },
          ),
          items: imageCarouselItems.map((item) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: double.maxFinite,
                    height: 210,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(item['image'] ?? ''),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  Container(
                    width: double.maxFinite,
                    height: 35,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            item['text'] ?? '',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.arrow_forward_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            imageCarouselItems.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: activeIndex == index ? 24 : 10,
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: activeIndex == index ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class GadgetsCarousel extends StatefulWidget {
  const GadgetsCarousel({super.key});

  @override
  State<GadgetsCarousel> createState() => _GadgetsCarouselState();
}

class _GadgetsCarouselState extends State<GadgetsCarousel> {
  int activeIndex = 0;
  late Future<List<Map<String, dynamic>>> carouselItemsFuture;

  @override
  void initState() {
    super.initState();
    carouselItemsFuture = fetchCarouselItems();
  }

  Future<List<Map<String, dynamic>>> fetchCarouselItems() async {
    try {
      var snapshot =
          await FirebaseFirestore.instance.collection('gadgetsCarousel').get();
      return snapshot.docs.map((doc) {
        return {'image': doc['image'] ?? '', 'text': doc['text'] ?? ''};
      }).toList();
    } catch (e) {
      debugPrint('Error fetching carousel items: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: carouselItemsFuture,
      builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No carousel images available'));
        }

        var imageCarouselItems = snapshot.data!;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CarouselSlider(
              options: CarouselOptions(
                height: 200.0,
                autoPlay: true,
                enlargeCenterPage: false,
                viewportFraction: 1,
                onPageChanged: (index, reason) {
                  setState(() => activeIndex = index);
                },
              ),
              items: imageCarouselItems.map((item) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 210,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(item['image']!),
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: 35,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                item['text']!,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.arrow_forward_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 7),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                imageCarouselItems.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: activeIndex == index ? 24 : 10,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: activeIndex == index ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
