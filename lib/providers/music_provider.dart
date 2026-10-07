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

    _audioPlayer.onPlayerComplete.listen((event) async {
      _incrementPlayCount(_currentSong);
      if (_repeatMode == RepeatMode.one && _currentSong != null) {
        await _audioPlayer.seek(Duration.zero);
        await _audioPlayer.resume();
      } else {
        await next(autoPlay: true);
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

  /// Returns false if file is missing (caller should skip).
  Future<bool> _playDirect(Song song) async {
    final file = File(song.filePath);
    if (!await file.exists()) {
      debugPrint('Missing audio file: ${song.filePath}');
      return false;
    }

    if (_currentSong?.id != song.id) {
      _currentSong = song;
      _position = Duration.zero;
      _duration = Duration.zero;
      notifyListeners();
      await _audioPlayer.setSourceDeviceFile(song.filePath);
    }
    await _audioPlayer.resume();
    return true;
  }

  /// Resume current track without rebuilding queues (fixes play/pause
  /// button destroying playlist/shuffle context).
  Future<void> resumeCurrent() async {
    if (_currentSong == null) return;
    final ok = await _playDirect(_currentSong!);
    if (!ok) await next(autoPlay: true);
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
    if (_currentQueue.isEmpty) {
      // Rebuild from library so auto-next never silently dies.
      if (_songs.isNotEmpty) {
        _originalQueue = List.from(_songs);
        _currentQueue = List.from(_songs);
      } else {
        return;
      }
    }
    int currentIndex = _currentQueue.indexWhere((s) => s.id == _currentSong?.id);
    // Unknown current (e.g. deleted) -> start from top.
    if (currentIndex == -1) {
      final ok = await _playDirect(_currentQueue.first);
      if (!ok) await _skipMissingForward(0);
      return;
    }

    if (currentIndex < _currentQueue.length - 1) {
      final ok = await _playDirect(_currentQueue[currentIndex + 1]);
      if (!ok) await _skipMissingForward(currentIndex + 1);
    } else {
      // End of queue.
      if (_repeatMode == RepeatMode.all || !autoPlay) {
        final ok = await _playDirect(_currentQueue.first);
        if (!ok) await _skipMissingForward(0);
      } else {
        // Keep last track visible, pause at start instead of wiping queues.
        await _audioPlayer.pause();
        await _audioPlayer.seek(Duration.zero);
        _position = Duration.zero;
        _isPlaying = false;
        notifyListeners();
      }
    }
  }

  /// Advance past missing files starting after [failedIndex].
  Future<void> _skipMissingForward(int failedIndex) async {
    for (int i = failedIndex + 1; i < _currentQueue.length; i++) {
      if (await _playDirect(_currentQueue[i])) return;
    }
    if (_repeatMode == RepeatMode.all) {
      for (int i = 0; i <= failedIndex && i < _currentQueue.length; i++) {
        if (await _playDirect(_currentQueue[i])) return;
      }
    }
    await _audioPlayer.pause();
    notifyListeners();
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
    } else if (_repeatMode == RepeatMode.all) {
      await _playDirect(_currentQueue.last);
    } else {
      await seek(Duration.zero);
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
