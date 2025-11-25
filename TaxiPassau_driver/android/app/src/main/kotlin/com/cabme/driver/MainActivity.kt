package com.taxipassau.driver
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterFragmentActivity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.Bundle

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Define the custom sound URI
            val soundUri = Uri.parse("android.resource://$packageName/raw/notification_sound")

            // Configure audio attributes
            val audioAttributes = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .build()

            // Create or update the notification channel
            val channel = NotificationChannel(
                "taxipassaudriver", // Channel ID
                "taxipassaudriver",    // Channel Name
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "This is a custom notification channel"
                setSound(soundUri, audioAttributes)
            }

            // Register the channel
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }
}

