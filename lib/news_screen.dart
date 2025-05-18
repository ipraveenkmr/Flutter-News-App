import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

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

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch URL')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

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

          final newsItems = snapshot.data;
          if (newsItems == null || newsItems.isEmpty) {
            return const Center(child: Text('No news available.'));
          }

          return CardSwiper(
            cards: newsItems.map((item) {
              return GestureDetector(
                onTap: () => _launchURL(item.link),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      if (item.imageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Image.network(
                            item.imageUrl,
                            height: MediaQuery.of(context).size.height * 0.35,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Text(
                                    item.description,
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
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
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );

        },
      ),
    );
  }
}

Future<List<NewsItem>> fetchGoogleNewsRSS(String topic) async {
  // Convert topic to uppercase and encode for URL
  final encodedTopic = Uri.encodeComponent(topic.toUpperCase());

  final rssUrl =
      'https://news.google.com/news/rss/headlines/section/topic/$encodedTopic';

  print('RSS Feed URL: $rssUrl');

  final response = await http.get(Uri.parse(rssUrl));
  print('HTTP Response status: ${response.statusCode}');

  if (response.statusCode != 200) {
    throw Exception('Failed to load news');
  }

  final document = XmlDocument.parse(response.body);
  final items = document.findAllElements('item');

  // Fetch images for the topic
  final imageUrls = await fetchPexelsImages(topic, 10);

  int index = 0;
  return items.map((node) {
    final title = node.getElement('title')?.text ?? 'No title';
    final link = node.getElement('link')?.text ?? '';
    final pubDate = node.getElement('pubDate')?.text ?? '';
    final description = node.getElement('description')?.text ?? '';

    // Remove HTML tags and clean up text
    final plainTextDescription = description
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .trim();

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
  const apiKey = 'xWlHHujbLyAZVOsTBMP5Qb'; // Replace for production use
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
      return List<String>.from(photos.map((photo) => photo['src']['medium']));
    }
  }

  return [];
}
