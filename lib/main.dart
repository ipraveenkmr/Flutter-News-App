import 'package:flutter/material.dart';
import 'news_categories_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News App',
      debugShowCheckedModeBanner: false,
      home: NewsCategoriesPage(),
    );
  }
}

