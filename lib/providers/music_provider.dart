import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../models/song.dart';
import '../models/playlist.dart';
import '../services/database_service.dart';

enum RepeatMode { off, all, one }

class MusicProvider extends ChangeNotifier {
  final DatabaseService _dbService;
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<Song> _songs = [];
  List<Song> get songs => _songs;

  List<Playlist> _playlists = [];
  List<Playlist> get playlists => _playlists;

  Song? _currentSong;
  Song? get currentSong => _currentSong;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  Duration _duration = Duration.zero;
  Duration get duration => _duration;

  Duration _position = Duration.zero;
  Duration get position => _position;

  // Playback constraints
  List<Song> _currentQueue = [];
  List<Song> _originalQueue = [];
  
  bool _isShuffle = false;
  bool get isShuffle => _isShuffle;

  RepeatMode _repeatMode = RepeatMode.off;
  RepeatMode get repeatMode => _repeatMode;

  MusicProvider(this._dbService) {
    _loadAll();
    _initAudioPlayer();
  }

  void _loadAll() {
    _songs = _dbService.getAllSongs();
    _songs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    _playlists = _dbService.getAllPlaylists();
    _playlists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    notifyListeners();
  }

  void _initAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      _duration = newDuration;
      if (_currentSong != null && _currentSong!.durationMs == null) {
         final updatedSong = _currentSong!.copyWith(durationMs: newDuration.inMilliseconds);
         _currentSong = updatedSong;
         _dbService.updateSong(updatedSong);
         _updateLocalSongReference(updatedSong);
      }
      notifyListeners();
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      _position = newPosition;
      notifyListeners();
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      _incrementPlayCount(_currentSong);
      if (_repeatMode == RepeatMode.one) {
        seek(Duration.zero);
        _audioPlayer.resume();
      } else {
        next(autoPlay: true);
      }
    });
  }

  void _updateLocalSongReference(Song updatedSong) {
    final index = _songs.indexWhere((s) => s.id == updatedSong.id);
    if (index >= 0) {
      _songs[index] = updatedSong;
    }
  }

  void _incrementPlayCount(Song? song) {
    if (song != null) {
      final updated = song.copyWith(playCount: song.playCount + 1);
      _dbService.updateSong(updated);
      _updateLocalSongReference(updated);
      if (_currentSong?.id == updated.id) _currentSong = updated;
      notifyListeners();
    }
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
          _loadAll();
        }
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
    }
  }

  Future<void> removeSong(Song song) async {
    // Cascade removal from playlists
    for (var playlist in _playlists) {
      if (playlist.songIds.contains(song.id)) {
        final updatedIds = List<String>.from(playlist.songIds)..remove(song.id);
        await updatePlaylist(playlist.copyWith(songIds: updatedIds, updatedAt: DateTime.now()));
      }
    }
    
    await _dbService.deleteSong(song.id);
    if (_currentSong?.id == song.id) {
      await stop();
    }
    _loadAll();
  }

  Future<void> saveLyrics(String songId, String lyrics) async {
    final song = _songs.firstWhere((s) => s.id == songId);
    final updated = song.copyWith(lyrics: lyrics);
    await _dbService.updateSong(updated);
    _updateLocalSongReference(updated);
    if (_currentSong?.id == updated.id) _currentSong = updated;
    notifyListeners();
  }

  // --- Playlists --- //
  Future<void> addPlaylist(String name) async {
    final pl = Playlist(
      id: const Uuid().v4(),
      name: name,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _dbService.addPlaylist(pl);
    _loadAll();
  }

  Future<void> updatePlaylist(Playlist pl) async {
    await _dbService.updatePlaylist(pl);
    _loadAll();
  }

  Future<void> deletePlaylist(String id) async {
    await _dbService.deletePlaylist(id);
    _loadAll();
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    final pl = _playlists.firstWhere((p) => p.id == playlistId);
    if (!pl.songIds.contains(songId)) {
      final updatedIds = List<String>.from(pl.songIds)..add(songId);
      await updatePlaylist(pl.copyWith(songIds: updatedIds, updatedAt: DateTime.now()));
    }
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final pl = _playlists.firstWhere((p) => p.id == playlistId);
    final updatedIds = List<String>.from(pl.songIds)..remove(songId);
    await updatePlaylist(pl.copyWith(songIds: updatedIds, updatedAt: DateTime.now()));
  }

  // --- Playback Controls --- //
  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    if (_isShuffle) {
      _currentQueue.shuffle();
      // Ensure current song is at the top conceptually or just leave random
      if (_currentSong != null) {
        _currentQueue.removeWhere((s) => s.id == _currentSong!.id);
        _currentQueue.insert(0, _currentSong!);
      }
    } else {
      // Restore original queue order
      _currentQueue = List.from(_originalQueue);
    }
    notifyListeners();
  }

  void cycleRepeatMode() {
    if (_repeatMode == RepeatMode.off) {
      _repeatMode = RepeatMode.all;
    } else if (_repeatMode == RepeatMode.all) {
      _repeatMode = RepeatMode.one;
    } else {
      _repeatMode = RepeatMode.off;
    }
    notifyListeners();
  }

  Future<void> _playDirect(Song song) async {
    final file = File(song.filePath);
    if (!await file.exists()) return;
    
    if (_currentSong?.id != song.id) {
      _currentSong = song;
      _position = Duration.zero;
      _duration = Duration.zero;
      notifyListeners();
      await _audioPlayer.setSourceDeviceFile(song.filePath);
    }
    await _audioPlayer.resume();
  }

  Future<void> play(Song song, {List<Song>? queueContext}) async {
    final file = File(song.filePath);
    if (!await file.exists()) {
      return;
    }
    
    // Create explicitly isolated copies so clear() doesn't wipe our DB memory state
    if (queueContext != null) {
      _originalQueue = List.from(queueContext);
    } else {
      _originalQueue = List.from(_songs);
    }
    
    _currentQueue = List.from(_originalQueue);
    
    if (_isShuffle) {
      _currentQueue.shuffle();
      _currentQueue.removeWhere((s) => s.id == song.id);
      _currentQueue.insert(0, song);
    }
    
    await _playDirect(song);
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentSong = null;
    _position = Duration.zero;
    _currentQueue.clear();
    _originalQueue.clear();
    notifyListeners();
  }

  Future<void> next({bool autoPlay = false}) async {
    if (_currentQueue.isEmpty) return;
    int currentIndex = _currentQueue.indexWhere((s) => s.id == _currentSong?.id);
    
    if (currentIndex >= 0 && currentIndex < _currentQueue.length - 1) {
      await _playDirect(_currentQueue[currentIndex + 1]);
    } else {
      if (_repeatMode == RepeatMode.all || !autoPlay) {
        await _playDirect(_currentQueue.first);
      } else {
        await stop();
      }
    }
  }

  Future<void> previous() async {
    if (_currentQueue.isEmpty) return;
    int currentIndex = _currentQueue.indexWhere((s) => s.id == _currentSong?.id);
    
    // If past 3 seconds, previous restarts current track
    if (_position.inSeconds > 3 && _currentSong != null) {
      await seek(Duration.zero);
      return;
    }
    
    if (currentIndex > 0) {
      await _playDirect(_currentQueue[currentIndex - 1]);
    } else {
      await _playDirect(_currentQueue.last);
    }
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  List<Song> get topSongs {
    final sorted = List<Song>.from(_songs)..sort((a, b) => b.playCount.compareTo(a.playCount));
    return sorted;
  }

  List<Song> getSongsForPlaylist(Playlist pl) {
    return pl.songIds.map((id) => _songs.firstWhere((s) => s.id == id, orElse: () => Song(id: '', title: '', filePath: '', createdAt: DateTime.now()))).where((s) => s.id.isNotEmpty).toList();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
