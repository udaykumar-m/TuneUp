import 'package:flutter/material.dart';
import 'youtube_service.dart';
import 'video_player_screen.dart';

class YouTubeScreen extends StatefulWidget {
  const YouTubeScreen({super.key});

  @override
  _YouTubeScreenState createState() => _YouTubeScreenState();
}

class _YouTubeScreenState extends State<YouTubeScreen> {
  final _searchController = TextEditingController();
  final _youtubeService = YouTubeService();
  List<Map<String, String>> _videos = [];

  void _searchVideos() async {
    final query = _searchController.text;
    if (query.isNotEmpty) {
      final videos = await _youtubeService.searchVideos(query);
      setState(() {
        _videos = videos;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("YouTube Music Search")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search for music",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchVideos,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _videos.length,
              itemBuilder: (context, index) {
                final video = _videos[index];
                return ListTile(
                  leading: Image.network(video["thumbnail"]!),
                  title: Text(video["title"]!),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            VideoPlayerScreen(videoId: video["videoId"]!),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
