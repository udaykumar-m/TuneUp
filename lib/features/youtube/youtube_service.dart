import 'dart:convert';
import 'package:http/http.dart' as http;

class YouTubeService {
  final String apiKey = "AIzaSyB6M6AmrYVZLLNNLB5wyAeDODD_CGvfzMQ";

  Future<List<Map<String, String>>> searchVideos(String query) async {
    final url =
        "https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&q=$query&key=$apiKey";
    final response = await http.get(Uri.parse(url));
    print("testtt ----- ");
    print(response.body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['items'] as List).map<Map<String, String>>((item) {
        return {
          "title": item['snippet']['title'] as String,
          "videoId": item['id']['videoId'] as String,
          "thumbnail":
              item['snippet']['thumbnails']['default']['url'] as String,
        };
      }).toList();
    } else {
      throw Exception("Failed to fetch videos");
    }
  }
}
