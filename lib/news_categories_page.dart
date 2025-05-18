import 'package:flutter/material.dart';
import 'news_screen.dart'; // Make sure this path matches where NewsScreen is located

class NewsCategoriesPage extends StatelessWidget {
  final List<Map<String, dynamic>> categories = [
    {'title': 'World', 'color': Colors.blueAccent},
    {'title': 'Technology', 'color': Colors.deepPurple},
    {'title': 'Business', 'color': Colors.green},
    {'title': 'Entertainment', 'color': Colors.orange},
    {'title': 'Nation', 'color': Colors.yellow[700]},
    {'title': 'Sports', 'color': Colors.teal},
    {'title': 'Science', 'color': Colors.indigo},
    {'title': 'Health', 'color': Colors.pinkAccent},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("News Categories"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: categories.map((category) {
            return GestureDetector(
              onTap: () {
                // Navigate to NewsScreen with the selected category
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NewsScreen(topic: category['title']),
                  ),
                );
              },
              child: Card(
                color: category['color'],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    category['title'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
