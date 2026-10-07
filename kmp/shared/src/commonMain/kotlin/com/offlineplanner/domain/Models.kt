package com.offlineplanner.domain

import kotlinx.serialization.Serializable

// Port of Flutter lib/models/* — field names kept identical to backup.json v3
// so Flutter ZIP backups import without migration.
enum class EntryType { expense, todo, note }

@Serializable
data class Entry(
    val id: String,
    val type: Int, // EntryType.ordinal
    val title: String,
    val notes: String = "",
    val amount: Double? = null,
    val date: String, // ISO-8601
    val isCompletedOrPaid: Boolean = false,
    val hasReminder: Boolean = false,
    val reminderTime: String? = null,
    val alarmSoundId: String? = null,
    val updatedAt: String,
    val createdAt: String,
    val receiptPaths: List<String> = emptyList(),
)

@Serializable
data class Goal(
    val id: String,
    val title: String,
    val targetAmount: Double,
    val currentAmount: Double = 0.0,
    val updatedAt: String,
)

@Serializable
data class Recipe(
    val id: String,
    val title: String,
    val ingredients: String = "",
    val cookingSteps: String = "",
    val category: Int = 0,
    val estimatedCost: Double? = null,
    val notes: String = "",
    val isFavorite: Boolean = false,
    val createdAt: String,
    val updatedAt: String,
    val imagePath: String? = null,
    val tags: List<String> = emptyList(),
)

@Serializable
data class Song(
    val id: String,
    val title: String,
    val filePath: String, // relative media/... in ZIP, absolute on device
    val durationMs: Long? = null,
    val playCount: Int = 0,
    val lyrics: String = "",
    val createdAt: String,
)

@Serializable
data class Playlist(
    val id: String,
    val name: String,
    val songIds: List<String> = emptyList(),
    val createdAt: String,
    val updatedAt: String,
)

@Serializable
data class StepEntry(val id: String, val date: String, val steps: Int, val createdAt: String, val updatedAt: String)

@Serializable
data class WeightEntry(val id: String, val date: String, val weight: Double, val createdAt: String, val updatedAt: String)

@Serializable
data class ScannedDocument(
    val id: String,
    val title: String,
    val filePath: String,
    val thumbnailPath: String? = null,
    val categories: List<String> = emptyList(),
    val notes: String = "",
    val createdAt: String,
    val updatedAt: String,
)

// Planner aggregation ported from PlannerProvider helpers.
object PlannerStats {
    fun totalFor(expenses: List<Entry>): Double = expenses.sumOf { it.amount ?: 0.0 }
    fun paidTotal(expenses: List<Entry>): Double = expenses.filter { it.isCompletedOrPaid }.sumOf { it.amount ?: 0.0 }
    fun unpaidTotal(expenses: List<Entry>): Double = expenses.filter { !it.isCompletedOrPaid }.sumOf { it.amount ?: 0.0 }
}

// Music queue ported from MusicProvider next()/RepeatMode.
enum class RepeatMode { Off, All, One }

fun nextIndex(current: Int, size: Int, repeat: RepeatMode, autoPlay: Boolean): Int? {
    if (size == 0) return null
    if (current < 0) return 0
    if (current < size - 1) return current + 1
    return if (repeat == RepeatMode.All || !autoPlay) 0 else null // null = natural end, keep last visible
}
