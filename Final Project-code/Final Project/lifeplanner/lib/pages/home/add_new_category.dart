import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lifeplanner/widgets/base_scaffold.dart';

class AddCustomCategoryPage extends StatefulWidget {
  const AddCustomCategoryPage({super.key});

  @override
  State<AddCustomCategoryPage> createState() => _AddCustomCategoryPageState();
}

class _AddCustomCategoryPageState extends State<AddCustomCategoryPage> {
  final TextEditingController customCategoryController =
      TextEditingController();
  final TextEditingController editingController = TextEditingController();
  // Track current input length for live character count
  int currentInputLength = 0;

  late final StreamSubscription<DocumentSnapshot> _subscription;
  List<String> userCustomCategories = [];
  bool isLoading = true;

  String? editingCategory;
  static const int maxCategoriesAllowed = 50;

  @override
  void initState() {
    super.initState();
    _subscribeToCategories();

    // Listen to text changes for live count update
    customCategoryController.addListener(() {
      // Debug print to verify listener fires
      // print('Input length: ${customCategoryController.text.length}');
      setState(() {
        currentInputLength = customCategoryController.text.length;
      });
    });
  }

  Future<void> _subscribeToCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance.collection("Users").doc(user.uid);

    // Try to bootstrap from cache
    try {
      final cachedDoc = await docRef.get(
        const GetOptions(source: Source.cache),
      );
      if (cachedDoc.exists && mounted) {
        final cats =
            cachedDoc.data()?['customCategories'] as List<dynamic>? ?? [];
        setState(() {
          userCustomCategories = List<String>.from(cats);
          isLoading = false;
        });
      }
    } catch (_) {
      // ignore
    }

    // Listen to all changes (cache, pending, server)
    _subscription = docRef
        .snapshots(includeMetadataChanges: true)
        .listen(
          (docSnap) {
            final cats =
                docSnap.data()?['customCategories'] as List<dynamic>? ?? [];
            if (!mounted) return;
            setState(() {
              userCustomCategories = List<String>.from(cats);
              isLoading = false;
            });
          },
          onError: (e) {
            if (!mounted) return;
            setState(() => isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error loading categories: $e')),
            );
          },
        );
  }

  @override
  void dispose() {
    _subscription.cancel();
    customCategoryController.dispose();
    editingController.dispose();
    super.dispose();
  }

  bool isValidCategory(String input) {
    final trimmed = input.trim();
    final disallowedPattern = RegExp(r'[<>{}";]');
    if (trimmed.isEmpty) {
      showSnackbar("Category name cannot be empty.");
      return false;
    }
    if (trimmed.length > 30) {
      showSnackbar("Category name must be under 30 characters.");
      return false;
    }
    if (disallowedPattern.hasMatch(trimmed)) {
      showSnackbar("Invalid characters in category name.");
      return false;
    }
    return true;
  }

  Future<void> addCustomCategory(String newCategory) async {
    final trimmed = newCategory.trim();
    if (!isValidCategory(trimmed)) return;
    if (userCustomCategories.contains(trimmed)) {
      showSnackbar("Category already exists.");
      return;
    }
    if (userCustomCategories.length >= maxCategoriesAllowed) {
      showSnackbar(
        "You've reached the maximum of $maxCategoriesAllowed categories.",
      );
      return;
    }

    // Optimistic UI update
    setState(() {
      userCustomCategories.add(trimmed);
      customCategoryController.clear();
      currentInputLength = 0; // Reset counter
    });
    showSnackbar("Category added!", backgroundColor: Colors.green);

    // Firestore write (write the full updated list)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection("Users").doc(user.uid).update(
        {
          'customCategories': userCustomCategories,
          'timestamp': FieldValue.serverTimestamp(), // ← new cache‐stamp
        },
      );
    }
  }

  Future<void> deleteCustomCategory(String category) async {
    // Optimistic UI update
    setState(() {
      userCustomCategories.remove(category);
    });
    showSnackbar("Category deleted.", backgroundColor: Colors.orange);

    // Firestore write (write the full updated list)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(user.uid)
          .update({
            'customCategories': userCustomCategories,
            'timestamp': FieldValue.serverTimestamp(),
          });
    }
  }

  Future<void> saveEditedCategory(
    String oldCategory,
    String newCategory,
  ) async {
    final trimmed = newCategory.trim();
    if (!isValidCategory(trimmed)) return;
    if (userCustomCategories.contains(trimmed)) {
      showSnackbar("Category already exists.");
      return;
    }

    // Optimistic UI update
    final idx = userCustomCategories.indexOf(oldCategory);
    if (idx != -1) {
      setState(() {
        userCustomCategories[idx] = trimmed;
        editingCategory = null;
        editingController.clear();
      });
      showSnackbar("Category updated!", backgroundColor: Colors.green);
    }

    // Firestore write (write the full updated list)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(user.uid)
          .update({
            'customCategories': userCustomCategories,
            'timestamp': FieldValue.serverTimestamp(),
          });
    }
  }

  void showSnackbar(
    String message, {
    Color backgroundColor = Colors.redAccent,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  Future<bool?> showDeleteConfirmationDialog(String category) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: Text('Are you sure you want to delete "$category"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD27F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Custom Category',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black),
            onPressed:
                () => showDialog(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text("Page Guide"),
                        content: const SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "• Enter a name and tap 'Add Category' to create one.",
                              ),
                              SizedBox(height: 8),
                              Text("• Double tap a category to edit it."),
                              SizedBox(height: 8),
                              Text("• Tap the 🗑️ icon to delete a category."),
                              SizedBox(height: 8),
                              Text(
                                "• Max length is 30 characters. No special symbols.",
                              ),
                              SizedBox(height: 8),
                              Text("• You can add up to 50 categories."),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Got it!"),
                          ),
                        ],
                      ),
                ),
          ),
        ],
      ),
      child:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // New count of categories line
                    Text(
                      "You have ${userCustomCategories.length} out of $maxCategoriesAllowed categories.",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: customCategoryController,
                      maxLength: 30,
                      decoration: const InputDecoration(
                        hintText: 'Enter category name',
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                    ),
                    // Live character count below the text box
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "${30 - currentInputLength} characters left",
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              currentInputLength > 30
                                  ? Colors.red
                                  : Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    ElevatedButton(
                      onPressed: () {
                        if (editingCategory != null) {
                          showSnackbar("Finish editing first.");
                          return;
                        }
                        final input = customCategoryController.text.trim();
                        if (input.isNotEmpty) addCustomCategory(input);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD27F),
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 6,
                      ),
                      child: const Text('Add Category'),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Your Categories:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    if (userCustomCategories.isEmpty)
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.category_outlined,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "No categories yet.\nAdd some to get started!",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: userCustomCategories.length,
                        itemBuilder: (context, index) {
                          final category = userCustomCategories[index];
                          final isEditing = category == editingCategory;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            child: ListTile(
                              title:
                                  isEditing
                                      ? TextField(
                                        controller: editingController,
                                        maxLength: 30,
                                        autofocus: true,
                                        decoration: const InputDecoration(
                                          counterText: '',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 10,
                                          ),
                                        ),
                                      )
                                      : GestureDetector(
                                        onDoubleTap: () {
                                          setState(() {
                                            editingCategory = category;
                                            editingController.text = category;
                                          });
                                        },
                                        child: Text(category),
                                      ),
                              trailing:
                                  isEditing
                                      ? Wrap(
                                        spacing: 4,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.close,
                                              color: Colors.grey,
                                            ),
                                            onPressed:
                                                () => setState(() {
                                                  editingCategory = null;
                                                  editingController.clear();
                                                }),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.check,
                                              color: Colors.green,
                                            ),
                                            onPressed:
                                                () => saveEditedCategory(
                                                  category,
                                                  editingController.text,
                                                ),
                                          ),
                                        ],
                                      )
                                      : IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.redAccent,
                                        ),
                                        tooltip: 'Delete',
                                        onPressed: () async {
                                          final confirmed =
                                              await showDeleteConfirmationDialog(
                                                category,
                                              );
                                          if (confirmed == true) {
                                            deleteCustomCategory(category);
                                          }
                                        },
                                      ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
    );
  }
}
