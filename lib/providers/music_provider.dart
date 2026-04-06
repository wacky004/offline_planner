import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../models/song.dart';
import '../services/database_service.dart';

class MusicProvider extends ChangeNotifier {
  final DatabaseService _dbService;
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<Song> _songs = [];
  List<Song> get songs => _songs;

  Song? _currentSong;
  Song? get currentSong => _currentSong;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  Duration _duration = Duration.zero;
  Duration get duration => _duration;

  Duration _position = Duration.zero;
  Duration get position => _position;

  MusicProvider(this._dbService) {
    _loadSongs();
    _initAudioPlayer();
  }

  void _loadSongs() {
    _songs = _dbService.getAllSongs();
    _songs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  void _initAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      _duration = newDuration;
      // We can also update the song duration in db if it's missing
      if (_currentSong != null && _currentSong!.durationMs == null) {
         final updatedSong = _currentSong!.copyWith(durationMs: newDuration.inMilliseconds);
         _currentSong = updatedSong;
         _dbService.updateSong(updatedSong);
         // Update the list entry as well
         final index = _songs.indexWhere((s) => s.id == updatedSong.id);
         if (index >= 0) {
           _songs[index] = updatedSong;
         }
      }
      notifyListeners();
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      _position = newPosition;
      notifyListeners();
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      next(); // Auto-play next song
    });
  }

  Future<void> addSong() async {
    try {
      fp.FilePickerResult? result = await fp.FilePicker.platform.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'wav'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        if (await file.exists()) {
          final song = Song(
            id: const Uuid().v4(),
            title: result.files.single.name,
            filePath: file.path,
            createdAt: DateTime.now(),
          );
          await _dbService.addSong(song);
          _loadSongs();
        }
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
    }
  }

  Future<void> removeSong(Song song) async {
    await _dbService.deleteSong(song.id);
    if (_currentSong?.id == song.id) {
      await stop();
    }
    _loadSongs();
  }

  Future<void> play(Song song) async {
    final file = File(song.filePath);
    if (!await file.exists()) {
      // Handle missing file
      return;
    }
    
    if (_currentSong?.id != song.id) {
      _currentSong = song;
      _position = Duration.zero;
      _duration = Duration.zero;
      notifyListeners();
      await _audioPlayer.setSourceDeviceFile(song.filePath);
    }
    await _audioPlayer.resume();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentSong = null;
    _position = Duration.zero;
    notifyListeners();
  }

  Future<void> next() async {
    if (_songs.isEmpty) return;
    int currentIndex = _songs.indexWhere((s) => s.id == _currentSong?.id);
    if (currentIndex >= 0 && currentIndex < _songs.length - 1) {
      await play(_songs[currentIndex + 1]);
    } else {
      await play(_songs.first);
    }
  }

  Future<void> previous() async {
    if (_songs.isEmpty) return;
    int currentIndex = _songs.indexWhere((s) => s.id == _currentSong?.id);
    if (currentIndex > 0) {
      await play(_songs[currentIndex - 1]);
    } else {
      await play(_songs.last);
    }
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
