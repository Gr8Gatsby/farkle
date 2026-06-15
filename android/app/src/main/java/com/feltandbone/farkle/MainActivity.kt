package com.feltandbone.farkle

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import com.feltandbone.farkle.ui.FarkleApp
import com.feltandbone.farkle.ui.theme.FarkleTheme
import com.feltandbone.farkle.ui.theme.Paper

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            FarkleTheme {
                Surface(modifier = Modifier.fillMaxSize(), color = Paper) {
                    FarkleApp()
                }
            }
        }
    }
}
