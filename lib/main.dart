import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => DataProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainCategoryScreen(),
    );
  }
}

class DataProvider with ChangeNotifier {
  List<String> _categories = [];
  Map<String, List<String>> _subcategoriesCache = {};

  List<String> get categories => _categories;
  List<String> getSubcategories(String category) => _subcategoriesCache[category] ?? [];

  DataProvider() {
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    final response = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/users'));
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      _categories = data.map((item) => item['name'].toString()).toList();
      notifyListeners();
    } else {
      throw Exception('Failed to load categories');
    }
  }

  Future<void> fetchSubcategories(String category) async {
    if (_subcategoriesCache.containsKey(category)) return;

    final response = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/posts?userId=1'));
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      _subcategoriesCache[category] = data.map((item) => item['title'].toString()).toList();
      notifyListeners();
    } else {
      throw Exception('Failed to load subcategories');
    }
  }
}

class MainCategoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Main Categories')),
      body: Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
          return ListView.builder(
            itemCount: dataProvider.categories.length,
            itemBuilder: (context, index) {
              final category = dataProvider.categories[index];
              return ListTile(
                title: Hero(
                  tag: category,
                  child: Material(
                    color: Colors.transparent,
                    child: Text(category),
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubcategoryScreen(category: category),
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

class SubcategoryScreen extends StatelessWidget {
  final String category;

  SubcategoryScreen({required this.category});

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Hero(
          tag: category,
          child: Material(
            color: Colors.transparent,
            child: Text(category),
          ),
        ),
      ),
      body: FutureBuilder(
        future: dataProvider.fetchSubcategories(category),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final subcategories = dataProvider.getSubcategories(category);
            return ListView.builder(
              itemCount: subcategories.length,
              itemBuilder: (context, index) {
                final subcategory = subcategories[index];
                return ListTile(
                  title: Text(subcategory),
                  onTap: () {
                    // Handle individual item selection
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
