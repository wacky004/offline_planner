package com.offlineplanner.app

import android.os.Bundle
import android.widget.TextView
import androidx.activity.ComponentActivity

// Placeholder host — full Compose drawer nav (Dashboard/Planner/Summary/Goals/
// Cookbook/Music/Health/Camera/Game/Settings) lands in next milestone.
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(
            TextView(this).apply { text = "Offline Planner KMP scaffold" },
        )
    }
}
