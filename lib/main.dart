import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: AudioFilesScreen(),
    );
  }
}

class AudioFilesScreen extends StatefulWidget {
  const AudioFilesScreen({super.key});

  @override
  _AudioFilesScreenState createState() => _AudioFilesScreenState();
}

class _AudioFilesScreenState extends State<AudioFilesScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> _songs = [];

  @override
  void initState() {
    super.initState();
    _fetchAudioFiles();
  }

  Future<void> _fetchAudioFiles() async {
    if (await _requestPermissions()) {
      List<SongModel> songs = await _audioQuery.querySongs();
      setState(() {
        _songs = songs;
      });
    }
  }

  Future<bool> _requestPermissions() async {
    if (await Permission.storage.isGranted) {
      return true;
    }

    if (await Permission.audio.request().isGranted) {
      return true;
    } else {
      openAppSettings();
    }

    if (await Permission.storage.isPermanentlyDenied) {
      openAppSettings();
      return false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Files'),
      ),
      body: _songs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_songs[index].title),
                  subtitle: Text(_songs[index].artist ?? "Unknown Artist"),
                  onTap: () => _openPlayer(context, _songs[index]),
                );
              },
            ),
    );
  }

  void _openPlayer(BuildContext context, SongModel song) {
    showModalBottomSheet(
      context: context,
      builder: (context) => AudioPlayerBottomSheet(song: song),
    );
  }
}

class AudioPlayerBottomSheet extends StatefulWidget {
  final SongModel song;

  const AudioPlayerBottomSheet({super.key, required this.song});

  @override
  _AudioPlayerBottomSheetState createState() => _AudioPlayerBottomSheetState();
}

class _AudioPlayerBottomSheetState extends State<AudioPlayerBottomSheet> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _songDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() async {
    _audioPlayer.setSource(DeviceFileSource(widget.song.data)).then((val) {
      _audioPlayer.resume();
      setState(() {
        _isPlaying = true;
      });
    });
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

  void _playPauseAudio() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _seekAudio(double value) async {
    final newPosition = Duration(seconds: value.toInt());
    await _audioPlayer.seek(newPosition);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // SizedBox(height: 20),
        // QueryArtworkWidget(
        //   id: widget.song.id,
        //   type: ArtworkType.AUDIO,
        //   nullArtworkWidget: Icon(Icons.music_note, size: 100),
        //   artworkFit: BoxFit.cover,
        // ),
        const SizedBox(height: 10),
        Text(
          widget.song.title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        Text(
          widget.song.artist ?? "Unknown Artist",
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        Slider(
          value: _currentPosition.inSeconds.toDouble(),
          min: 0,
          max: _songDuration.inSeconds.toDouble(),
          onChanged: (double value) {
            _seekAudio(value);
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
              icon: const Icon(Icons.skip_previous),
              onPressed: () {}, // Add skip logic if needed
            ),
            IconButton(
              iconSize: 48,
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: () {
                _playPauseAudio();
              },
            ),
            IconButton(
              iconSize: 36,
              icon: const Icon(Icons.skip_next),
              onPressed: () {}, // Add skip logic if needed
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
