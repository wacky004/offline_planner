package com.offlineplanner.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.material3.Text

// Placeholder host — full drawer nav (Dashboard/Planner/Summary/Goals/
// Cookbook/Music/Health/Camera/Game/Settings) lands in next milestone.
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { Text("Offline Planner KMP scaffold") }
    }
}
