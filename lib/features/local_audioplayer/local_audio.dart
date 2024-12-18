import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioFilesScreen extends StatefulWidget {
  const AudioFilesScreen({super.key});

  @override
  _AudioFilesScreenState createState() => _AudioFilesScreenState();
}

class _AudioFilesScreenState extends State<AudioFilesScreen>
    with WidgetsBindingObserver {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> _songs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchAudioFiles();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchAudioFiles();
    }
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
      body: RefreshIndicator(
        onRefresh: _fetchAudioFiles,
        child: _songs.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _songs.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      title: Text(_songs[index].title),
                      subtitle: Text(_songs[index].artist ?? "Unknown Artist"),
                      onTap: () => _openPlayer(context, index),
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _openPlayer(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) => AudioPlayerBottomSheet(
        song: _songs[index],
        songs: _songs,
        initialIndex: index,
      ),
    );
  }
}

class AudioPlayerBottomSheet extends StatefulWidget {
  final SongModel song;
  final List<SongModel> songs;
  final int initialIndex;

  const AudioPlayerBottomSheet({
    super.key,
    required this.song,
    required this.songs,
    required this.initialIndex,
  });

  @override
  _AudioPlayerBottomSheetState createState() => _AudioPlayerBottomSheetState();
}

class _AudioPlayerBottomSheetState extends State<AudioPlayerBottomSheet> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _songDuration = Duration.zero;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _initializePlayer();
  }

  void _initializePlayer() async {
    _audioPlayer
        .setSource(DeviceFileSource(widget.songs[_currentIndex].data))
        .then((val) {
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

  void _nextSong() {
    if (_currentIndex < widget.songs.length - 1) {
      setState(() {
        _currentIndex++;
        _initializePlayer();
      });
    }
  }

  void _previousSong() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _initializePlayer();
      });
    }
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
    return PopScope(
      onPopInvoked: (bool popped) {
        if (_isPlaying && popped) {
          _audioPlayer.pause();
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Text(
            widget.songs[_currentIndex].title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Text(
            widget.songs[_currentIndex].artist ?? "Unknown Artist",
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
                onPressed: _previousSong,
              ),
              IconButton(
                iconSize: 48,
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: _playPauseAudio,
              ),
              IconButton(
                iconSize: 36,
                icon: const Icon(Icons.skip_next),
                onPressed: _nextSong,
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
