import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../widgets/search_bar.dart';
import 'cart.dart';

class Categories extends StatefulWidget {
  final String? userId;
  const Categories({super.key, this.userId});

  @override
  State<Categories> createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories>
    with AutomaticKeepAliveClientMixin {
  String? selectedCategoryId;
  String? selectedCategoryName;
  String? selectedCategoryBanner;
  final _categoryStream =
      FirebaseFirestore.instance.collection('category').snapshots();
  Map<int, GlobalKey> itemKeys = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchFirstCategory(); // Fetch and select first category
  }

  void _fetchFirstCategory() async {
    var snapshot =
        await FirebaseFirestore.instance.collection('category').limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      setState(() {
        selectedCategoryId = snapshot.docs.first.id;
        selectedCategoryName = snapshot.docs.first["label"];
        selectedCategoryBanner = snapshot.docs.first["bannerImage"];
      });
    }
  }

  void _showSearchBar(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: () => overlayEntry.remove(),
        child: Container(
          color: Colors.black12,
          alignment: const Alignment(0, -0.775),
          child: GestureDetector(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SearchBarWidget(
                userId: widget.userId,
                hintText: "Search Products",
                showTrailing: false,
                onSubmitted: (String query) {
                  overlayEntry.remove();
                },
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'All Categories',
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
        actions: [
          IconButton(
            onPressed: () => _showSearchBar(context),
            icon: const Icon(Icons.search, color: Colors.black),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.camera_alt_rounded, color: Colors.black),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Cart(userId: widget.userId),
                ),
              );
            },
            icon: const Icon(Icons.shopping_cart, color: Colors.black),
          )
        ],
      ),
      body: Row(
        children: [
          // Left side: Category list
          Container(
            width: 100,
            height: double.infinity,
            color: Colors.white,
            child: StreamBuilder<QuerySnapshot>(
              stream: _categoryStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No categories available"));
                }

                final categories = snapshot.data!.docs;

                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    var category = categories[index];
                    bool isSelected = category.id == selectedCategoryId;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategoryId = category.id;
                          selectedCategoryName = category["label"];
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Container(
                          width: 75,
                          height: 108,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: isSelected
                                  ? CupertinoColors.activeBlue
                                  : Colors.grey,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              category["image"] != null &&
                                  category["image"].isNotEmpty
                                  ? Image.network(category["image"],
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.contain)
                                  : const Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 60),
                              const SizedBox(height: 2),
                              Text(
                                category["label"],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? CupertinoColors.activeBlue
                                      : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Right side: Display products from selected category
          Expanded(
            child: Column(
              children: [
                // Category Banner at the top
                if (selectedCategoryId != null)
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('category')
                        .doc(selectedCategoryId)
                        .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const SizedBox.shrink();
                      }

                      final categoryData = snapshot.data!;
                      final String bannerImage =
                          categoryData["bannerImage"] ?? "";
                      final String categoryName =
                          categoryData["label"] ?? "Category";

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        child: Container(
                          width: double.infinity,
                          height: 100, // Adjust height as needed
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade200,
                                spreadRadius: 2,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Category Name
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 100, // Adjust width as needed
                                      child: Text(
                                        categoryName,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: CupertinoColors.activeBlue,
                                        ),
                                        maxLines: 2,
                                        softWrap: true,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      color: CupertinoColors.activeBlue,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              // Category Banner Image
                              if (bannerImage.isNotEmpty)
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(8),
                                    bottomRight: Radius.circular(8),
                                  ),
                                  child: ShaderMask(
                                    shaderCallback: (Rect bounds) {
                                      return const LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.center,
                                        colors: [
                                          Colors
                                              .transparent, // Start fully transparent
                                          Colors.black, // Fully visible
                                        ],
                                      ).createShader(bounds);
                                    },
                                    blendMode: BlendMode
                                        .dstIn, // Keeps the gradient as a mask
                                    child: Image.network(
                                      bannerImage,
                                      width: 128, // Adjust width as needed
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                // Keep the existing product list as it is
                Expanded(
                  child: selectedCategoryId == null
                      ? const Center(child: Text("Select a category"))
                      : StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('category')
                              .doc(selectedCategoryId)
                              .collection('items')
                              .snapshots(),
                          builder: (context, itemSnapshot) {
                            if (itemSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            if (!itemSnapshot.hasData ||
                                itemSnapshot.data!.docs.isEmpty) {
                              return SizedBox(
                                height: 650,
                                child: Center(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/icons/no_pdts.png',
                                        fit: BoxFit.contain,
                                        width: 100,
                                        height: 100,
                                      ),
                                      const Text(
                                        "No items available.",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final items = itemSnapshot.data!.docs;

                            return Expanded(
                              child: ListView(
                                children: items.map((itemDoc) {
                                  final String itemId = itemDoc.id;
                                  final String itemName =
                                      itemDoc["name"] ?? "Unnamed Item";

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              itemName,
                                              style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            const Icon(
                                                Icons
                                                    .arrow_circle_right_rounded,
                                                color:
                                                    CupertinoColors.activeBlue),
                                          ],
                                        ),
                                      ),
                                      StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('category')
                                            .doc(selectedCategoryId)
                                            .collection('items')
                                            .doc(itemId)
                                            .collection('pdt_categories')
                                            .snapshots(),
                                        builder: (context, pdtSnapshot) {
                                          if (pdtSnapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Center(
                                                child:
                                                    CircularProgressIndicator());
                                          }
                                          if (!pdtSnapshot.hasData ||
                                              pdtSnapshot.data!.docs.isEmpty) {
                                            return const Center(
                                                child: Text(
                                                    "No products available"));
                                          }

                                          final products =
                                              pdtSnapshot.data!.docs;

                                          return GridView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            gridDelegate:
                                                const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 3,
                                              crossAxisSpacing: 8,
                                              mainAxisSpacing: 5,
                                              childAspectRatio: 0.8,
                                            ),
                                            itemCount: products.length,
                                            itemBuilder: (context, index) {
                                              var product = products[index];
                                              return Column(
                                                children: [
                                                  Container(
                                                    width: 64,
                                                    height: 64,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(color: Colors.grey.shade200, width: 0.75),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5),
                                                      image: DecorationImage(
                                                        image: NetworkImage(
                                                            product["image"] ??
                                                                ""),
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    product["label"] ??
                                                        "No Label",
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
