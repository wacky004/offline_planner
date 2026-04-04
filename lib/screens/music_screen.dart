import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Music Player'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Provider.of<MusicProvider>(context, listen: false).addSong();
            },
            tooltip: 'Add new MP3',
          )
        ],
      ),
      body: Consumer<MusicProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              Expanded(
                child: provider.songs.isEmpty
                    ? Center(
                        child: Text(
                          'No music added yet.\nTap + to add local files.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Theme.of(context).disabledColor, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: provider.songs.length,
                        itemBuilder: (context, index) {
                          final song = provider.songs[index];
                          final isCurrentlyPlaying = provider.currentSong?.id == song.id;

                          return ListTile(
                            leading: Icon(
                              isCurrentlyPlaying ? Icons.volume_up : Icons.music_note,
                              color: isCurrentlyPlaying
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
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
                            subtitle: song.durationMs != null
                                ? Text(_formatDuration(Duration(milliseconds: song.durationMs!)))
                                : const Text('Local track'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.grey),
                              onPressed: () {
                                provider.removeSong(song);
                              },
                            ),
                            onTap: () {
                              provider.play(song);
                            },
                          );
                        },
                      ),
              ),
              if (provider.currentSong != null)
                Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        provider.currentSong!.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                        mainAxisAlignment: MainAxisAlignment.center,
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
                    ],
                  ),
                )
            ],
          );
        },
      ),
    );
  }
}
