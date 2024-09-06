import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AudioFilesScreen(),
    );
  }
}

class AudioFilesScreen extends StatefulWidget {
  @override
  _AudioFilesScreenState createState() => _AudioFilesScreenState();
}

class _AudioFilesScreenState extends State<AudioFilesScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<SongModel> _songs = [];
  bool _isPlaying = false;
  String? _currentSongPath;

  @override
  void initState() {
    super.initState();
    _fetchAudioFiles();
  }

  Future<void> _fetchAudioFiles() async {
    // Request storage permission
    if (await _requestPermission()) {
      // Query all songs on the device
      List<SongModel> songs = await _audioQuery.querySongs();
      setState(() {
        _songs = songs;
      });
    }
  }

  Future<bool> _requestPermission() async {
    PermissionStatus status = await Permission.storage.request();
    return status.isGranted;
  }

  // Function to play or pause the audio
  Future<void> _playPauseAudio(String songPath) async {
    if (_isPlaying && _currentSongPath == songPath) {
      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
    } else {
      await _audioPlayer.play(DeviceFileSource(
          songPath)); // Use DeviceFileSource to play local files
      setState(() {
        _isPlaying = true;
        _currentSongPath = songPath;
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Audio Files"),
      ),
      body: _songs.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_songs[index].title),
                  subtitle: Text(_songs[index].artist ?? "Unknown Artist"),
                  trailing: IconButton(
                    icon: Icon(
                      _isPlaying && _currentSongPath == _songs[index].data
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    onPressed: () {
                      _playPauseAudio(_songs[index].data);
                    },
                  ),
                );
              },
            ),
    );
  }
}
