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

class _AudioFilesScreenState extends State<AudioFilesScreen>
    with WidgetsBindingObserver {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<SongModel> _songs = [];
  int? _currentSongIndex;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _songDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchAudioFiles();
    _audioPlayer.onPositionChanged.listen((Duration newPosition) {
      setState(() {
        _currentPosition = newPosition;
      });
    });

    _audioPlayer.onDurationChanged.listen((Duration newDuration) {
      setState(() {
        _songDuration = newDuration;
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance
        .removeObserver(this); // Remove observer to avoid memory leaks
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchAudioFiles(); // Refresh song list when the app comes to the foreground
    }
  }

  Future<void> _fetchAudioFiles() async {
    if (await _requestPermission()) {
      List<SongModel> songs = await _audioQuery.querySongs();
      setState(() {
        _songs = songs;
      });
    }
  }

  Future<bool> _requestPermission() async {
    if (await Permission.storage.isGranted) {
      return true;
    }

    if (await Permission.audio.request().isGranted) {
      return true;
    }

    if (await Permission.storage.isPermanentlyDenied) {
      openAppSettings();
      return false;
    }
    return false;
  }

  void _playPauseAudio(String songPath) async {
    if (_isPlaying && _currentSongIndex != null) {
      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
    } else {
      await _audioPlayer.play(DeviceFileSource(songPath));
      setState(() {
        _isPlaying = true;
      });
    }
  }

  void _nextSong() {
    if (_currentSongIndex != null && _currentSongIndex! < _songs.length - 1) {
      _currentSongIndex = _currentSongIndex! + 1;
      _playPauseAudio(_songs[_currentSongIndex!].data);
    }
  }

  void _previousSong() {
    if (_currentSongIndex != null && _currentSongIndex! > 0) {
      _currentSongIndex = _currentSongIndex! - 1;
      _playPauseAudio(_songs[_currentSongIndex!].data);
    }
  }

  void _openPlayer(BuildContext context, int songIndex) {
    _currentSongIndex = songIndex;
    _playPauseAudio(_songs[songIndex].data);

    showModalBottomSheet(
      context: context,
      builder: (context) => _musicPlayerUI(context, songIndex),
    );
  }

  Widget _musicPlayerUI(BuildContext context, int songIndex) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 20),
        QueryArtworkWidget(
          id: _songs[songIndex].id,
          type: ArtworkType.AUDIO,
          nullArtworkWidget: Icon(Icons.music_note, size: 100),
          artworkFit: BoxFit.cover,
        ),
        SizedBox(height: 10),
        Text(
          _songs[songIndex].title,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          _songs[songIndex].artist ?? "Unknown Artist",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
        SizedBox(height: 20),
        Slider(
          value: _currentPosition.inSeconds.toDouble(),
          min: 0,
          max: _songDuration.inSeconds.toDouble(),
          onChanged: (double value) async {
            final newPosition = Duration(seconds: value.toInt());
            await _audioPlayer.seek(newPosition);
            setState(() {
              _currentPosition = newPosition;
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formatDuration(_currentPosition)),
              Text(formatDuration(_songDuration)),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              iconSize: 36,
              icon: Icon(Icons.skip_previous),
              onPressed: _previousSong,
            ),
            IconButton(
              iconSize: 48,
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: () => _playPauseAudio(_songs[songIndex].data),
            ),
            IconButton(
              iconSize: 36,
              icon: Icon(Icons.skip_next),
              onPressed: _nextSong,
            ),
          ],
        ),
        SizedBox(height: 20),
      ],
    );
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Audio Files"),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAudioFiles,
        child: _songs.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _songs.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_songs[index].title),
                    subtitle: Text(_songs[index].artist ?? "Unknown Artist"),
                    onTap: () => _openPlayer(context, index),
                  );
                },
              ),
      ),
    );
  }
}
