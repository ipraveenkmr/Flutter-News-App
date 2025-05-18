import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';


class NewsItem {
  final String title;
  final String link;
  final String pubDate;
  final String description;
  final String imageUrl;

  NewsItem({
    required this.title,
    required this.link,
    required this.pubDate,
    required this.description,
    required this.imageUrl,
  });
}

class NewsScreen extends StatefulWidget {
  final String topic;

  const NewsScreen({super.key, required this.topic});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<List<NewsItem>> _newsFuture;

  @override
  void initState() {
    super.initState();
    _newsFuture = fetchGoogleNewsRSS(widget.topic);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.topic} News')),
      body: FutureBuilder<List<NewsItem>>(
        future: _newsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final newsItems = snapshot.data!;
          return ListView.builder(
            itemCount: newsItems.length,
            itemBuilder: (context, index) {
              final item = newsItems[index];
              return GestureDetector(
                onTap: () => _launchURL(item.link),
                child: Card(
                  margin: const EdgeInsets.all(10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.imageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.network(
                            item.imageUrl,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.black87),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.pubDate,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch URL')),
      );
    }
  }
}

Future<List<NewsItem>> fetchGoogleNewsRSS(String topic) async {
  final rssUrl =
      'https://news.google.com/rss/search?q=${Uri.encodeComponent(topic)}&hl=en-IN&gl=IN&ceid=IN:en';

  final response = await http.get(Uri.parse(rssUrl));
  if (response.statusCode != 200) {
    throw Exception('Failed to load news');
  }

  final document = XmlDocument.parse(response.body);
  final items = document.findAllElements('item');

  // Fetch multiple images for the topic from Pexels
  final imageUrls = await fetchPexelsImages(topic, 10);

  int index = 0;
  return items.map((node) {
    final title = node.getElement('title')?.text ?? 'No title';
    final link = node.getElement('link')?.text ?? '';
    final pubDate = node.getElement('pubDate')?.text ?? '';
    final description = node.getElement('description')?.text ?? '';
    final plainTextDescription = description.replaceAll(RegExp(r'<[^>]*>'), '').trim();

    // Assign images cycling through the list if there are fewer images than news items
    final imageUrl = imageUrls.isNotEmpty
        ? imageUrls[index++ % imageUrls.length]
        : 'https://via.placeholder.com/600x400?text=${Uri.encodeComponent(topic)}';

    return NewsItem(
      title: title,
      link: link,
      pubDate: pubDate,
      description: plainTextDescription,
      imageUrl: imageUrl,
    );
  }).toList();
}

Future<List<String>> fetchPexelsImages(String topic, int maxImages) async {
  const apiKey = '7N4slirDGG9JOzfU5xWlHHujbLyAZVOsTBMP5QbmljBRwIJdfa6rLTgU'; // Your API key
  final url =
      'https://api.pexels.com/v1/search?query=${Uri.encodeComponent(topic)}&per_page=$maxImages';

  final response = await http.get(
    Uri.parse(url),
    headers: {'Authorization': apiKey},
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final photos = data['photos'];
    if (photos != null && photos.isNotEmpty) {
      // Extract the medium image URLs
      return List<String>.from(photos.map((photo) => photo['src']['medium']));
    }
  }

  // Return empty list if failed, fallback handled later
  return [];
}



