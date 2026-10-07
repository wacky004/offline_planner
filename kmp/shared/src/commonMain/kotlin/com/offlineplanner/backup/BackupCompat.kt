package com.offlineplanner.backup

import com.offlineplanner.domain.Entry
import com.offlineplanner.domain.Goal
import com.offlineplanner.domain.Playlist
import com.offlineplanner.domain.Recipe
import com.offlineplanner.domain.ScannedDocument
import com.offlineplanner.domain.Song
import com.offlineplanner.domain.StepEntry
import com.offlineplanner.domain.WeightEntry
import kotlinx.serialization.Serializable

// backup.json v3 — identical keys to Flutter BackupService.exportToJson().
// Old v2 backups (with bibleBooks/bibleChapters/bibleVerses) are ignored.
@Serializable
data class BackupPayload(
    val exportedAt: String,
    val deviceId: String,
    val version: Int = 3,
    val entries: List<Entry> = emptyList(),
    val goals: List<Goal> = emptyList(),
    val recipes: List<Recipe> = emptyList(),
    val songs: List<Song> = emptyList(),
    val playlists: List<Playlist> = emptyList(),
    val stepEntries: List<StepEntry> = emptyList(),
    val weightEntries: List<WeightEntry> = emptyList(),
    val scannedDocuments: List<ScannedDocument> = emptyList(),
)

// ZIP layout (must match Flutter exportBackupZip):
//   backup.json
//   media/<n>_<basename>  (mp3, scanned_docs, recipe images, receipts)
// Song.filePath / doc paths inside backup.json are media/... relative;
// on import, copy media/ to app docs and keep relative (resolve at view time).
object BackupLayout {
    const val BACKUP_JSON = "backup.json"
    const val MEDIA_PREFIX = "media/"
}
