import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../widgets/app_drawer.dart';

class MusicScreen extends StatelessWidget {
  const MusicScreen({super.key});

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    if (d.inHours > 0) {
      return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }

  void _showLyricsModal(BuildContext context, Song song) {
    final controller = TextEditingController(text: song.lyrics);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 16, left: 16, right: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Lyrics - ${song.title}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 15,
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Enter/Paste lyrics here...'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Provider.of<MusicProvider>(context, listen: false).saveLyrics(song.id, controller.text);
                  Navigator.pop(ctx);
                },
                icon: const Icon(Icons.save),
                label: const Text('Save Lyrics'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      }
    );
  }

  void _showAddToPlaylistModal(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Consumer<MusicProvider>(
          builder: (context, provider, _) {
            if (provider.playlists.isEmpty) {
              return const Center(child: Text('No playlists available. Create one first.'));
            }
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Add to Playlist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: provider.playlists.length,
                    itemBuilder: (context, index) {
                      final pl = provider.playlists[index];
                      final inPlaylist = pl.songIds.contains(song.id);
                      return ListTile(
                        leading: const Icon(Icons.playlist_play),
                        title: Text(pl.name),
                        trailing: inPlaylist ? const Icon(Icons.check_circle, color: Colors.green) : const Icon(Icons.circle_outlined),
                        onTap: () {
                          if (inPlaylist) {
                             provider.removeSongFromPlaylist(pl.id, song.id);
                          } else {
                             provider.addSongToPlaylist(pl.id, song.id);
                          }
                        },
                      );
                    }
                  ),
                ),
              ],
            );
          }
        );
      }
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Playlist'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Playlist Name', border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
               if (controller.text.trim().isNotEmpty) {
                 Provider.of<MusicProvider>(context, listen: false).addPlaylist(controller.text.trim());
               }
               Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      )
    );
  }

  void _showPlaylistSongsModal(BuildContext context, Playlist pl, MusicProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return Consumer<MusicProvider>(
          builder: (context, reactiveProvider, _) {
            final playlistSongs = reactiveProvider.getSongsForPlaylist(pl);
            return Column(
              children: [
                AppBar(
                  title: Text(pl.name),
                  leading: IconButton(icon: const Icon(Icons.keyboard_arrow_down), onPressed: () => Navigator.pop(ctx)),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        reactiveProvider.deletePlaylist(pl.id);
                        Navigator.pop(ctx);
                      },
                    )
                  ],
                ),
                Expanded(
                  child: playlistSongs.isEmpty 
                  ? const Center(child: Text('Playlist is empty. Add songs from "All Songs".'))
                  : ListView.builder(
                    itemCount: playlistSongs.length,
                    itemBuilder: (context, index) {
                       final song = playlistSongs[index];
                       return ListTile(
                         leading: const Icon(Icons.music_note),
                         title: Text(song.title, maxLines: 1),
                         trailing: IconButton(
                           icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                           onPressed: () => reactiveProvider.removeSongFromPlaylist(pl.id, song.id),
                         ),
                         onTap: () {
                           reactiveProvider.play(song, queueContext: playlistSongs);
                         },
                       );
                    }
                  )
                ),
              ],
            );
          }
        );
      }
    );
  }

  Widget _buildSongTile(BuildContext context, Song song, MusicProvider provider, {List<Song>? contextQueue}) {
    final isCurrentlyPlaying = provider.currentSong?.id == song.id;
    return ListTile(
      leading: Icon(
        isCurrentlyPlaying ? Icons.volume_up : Icons.music_note,
        color: isCurrentlyPlaying ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(
        song.title,
        style: TextStyle(
          fontWeight: isCurrentlyPlaying ? FontWeight.bold : FontWeight.normal,
          color: isCurrentlyPlaying ? Theme.of(context).colorScheme.primary : null,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Icon(Icons.play_arrow, size: 14, color: Theme.of(context).disabledColor),
          const SizedBox(width: 4),
          Text('${song.playCount} • ', style: TextStyle(color: Theme.of(context).disabledColor, fontSize: 12)),
          song.durationMs != null
              ? Text(_formatDuration(Duration(milliseconds: song.durationMs!)), style: TextStyle(color: Theme.of(context).disabledColor, fontSize: 12))
              : Text('Local track', style: TextStyle(color: Theme.of(context).disabledColor, fontSize: 12)),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (val) {
          if (val == 'play') provider.play(song, queueContext: contextQueue);
          if (val == 'playlist') _showAddToPlaylistModal(context, song);
          if (val == 'lyrics') _showLyricsModal(context, song);
          if (val == 'delete') provider.removeSong(song);
        },
        itemBuilder: (ctx) => [
          const PopupMenuItem(value: 'play', child: Text('Play')),
          const PopupMenuItem(value: 'playlist', child: Text('Add to Playlist')),
          const PopupMenuItem(value: 'lyrics', child: Text('Lyrics')),
          const PopupMenuItem(value: 'delete', child: Text('Delete File', style: TextStyle(color: Colors.red))),
        ],
      ),
      onTap: () {
        provider.play(song, queueContext: contextQueue);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: const Text('Music Player'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                Provider.of<MusicProvider>(context, listen: false).addSong();
              },
              tooltip: 'Import MP3',
            )
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All Songs'),
              Tab(text: 'Playlists'),
              Tab(text: 'Rankings'),
            ],
          ),
        ),
        body: Consumer<MusicProvider>(
          builder: (context, provider, child) {
            return Column(
              children: [
                Expanded(
                  child: TabBarView(
                    children: [
                      // TAB 1: ALL SONGS
                      provider.songs.isEmpty
                      ? Center(child: Text('No music added yet.\nTap + to add local files.', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).disabledColor, fontSize: 16)))
                      : ListView.builder(
                          itemCount: provider.songs.length,
                          itemBuilder: (context, index) {
                            return _buildSongTile(context, provider.songs[index], provider, contextQueue: provider.songs);
                          },
                        ),
                        
                      // TAB 2: PLAYLISTS
                      Scaffold(
                        floatingActionButton: FloatingActionButton.extended(
                          onPressed: () => _showCreatePlaylistDialog(context),
                          label: const Text('New Playlist'),
                          icon: const Icon(Icons.playlist_add),
                        ),
                        body: provider.playlists.isEmpty
                        ? Center(child: Text('No playlists yet.', style: TextStyle(color: Theme.of(context).disabledColor)))
                        : ListView.builder(
                            itemCount: provider.playlists.length,
                            padding: const EdgeInsets.only(bottom: 80),
                            itemBuilder: (context, index) {
                               final pl = provider.playlists[index];
                               return Card(
                                 margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                 child: ListTile(
                                    leading: const CircleAvatar(child: Icon(Icons.queue_music)),
                                    title: Text(pl.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('${pl.songIds.length} songs'),
                                    onTap: () => _showPlaylistSongsModal(context, pl, provider),
                                 ),
                               );
                            }
                          )
                      ),
                      
                      // TAB 3: RANKINGS
                      provider.topSongs.isEmpty || provider.topSongs.first.playCount == 0
                      ? Center(child: Text('Play songs to build your rankings!', style: TextStyle(color: Theme.of(context).disabledColor)))
                      : ListView.builder(
                          itemCount: provider.topSongs.length,
                          itemBuilder: (context, index) {
                            if (provider.topSongs[index].playCount == 0) return const SizedBox.shrink();
                            final song = provider.topSongs[index];
                            return _buildSongTile(context, song, provider, contextQueue: provider.topSongs);
                          },
                        ),
                    ],
                  ),
                ),
                if (provider.currentSong != null)
                  Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                provider.currentSong!.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(_formatDuration(provider.position), style: const TextStyle(fontSize: 12)),
                            Expanded(
                              child: Slider(
                                value: provider.position.inMilliseconds.toDouble(),
                                max: provider.duration.inMilliseconds > 0 
                                    ? provider.duration.inMilliseconds.toDouble() 
                                    : 1.0,
                                onChanged: (val) {
                                  provider.seek(Duration(milliseconds: val.toInt()));
                                },
                              ),
                            ),
                            Text(_formatDuration(provider.duration), style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(provider.isShuffle ? Icons.shuffle_on : Icons.shuffle),
                              color: provider.isShuffle ? Theme.of(context).colorScheme.primary : null,
                              onPressed: () => provider.toggleShuffle(),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.skip_previous),
                                  iconSize: 36,
                                  onPressed: () => provider.previous(),
                                ),
                                IconButton(
                                  icon: Icon(provider.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
                                  iconSize: 54,
                                  color: Theme.of(context).colorScheme.primary,
                                  onPressed: () {
                                    if (provider.isPlaying) {
                                      provider.pause();
                                    } else {
                                      provider.play(provider.currentSong!);
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.skip_next),
                                  iconSize: 36,
                                  onPressed: () => provider.next(),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(
                                provider.repeatMode == RepeatMode.one 
                                  ? Icons.repeat_one_on 
                                  : (provider.repeatMode == RepeatMode.all ? Icons.repeat_on : Icons.repeat)
                              ),
                              color: provider.repeatMode != RepeatMode.off ? Theme.of(context).colorScheme.primary : null,
                              onPressed: () => provider.cycleRepeatMode(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
              ],
            );
          },
        ),
      ),
    );
  }
}
