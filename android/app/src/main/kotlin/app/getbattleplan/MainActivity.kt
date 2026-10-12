package app.getbattleplan

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
    }

    // One channel per kind of notification (ARCH §6.5), so people can
    // silence, say, documents but keep messages in Android's settings. The
    // server names a channel in every push; the IDs must match notifyChannel
    // in shared/constants.json. Creating a channel that exists only updates
    // its name, so this is safe on every start.
    private fun createNotificationChannels() {
        val manager = getSystemService(NotificationManager::class.java) ?: return
        val channels = listOf(
            Triple("messages", R.string.notification_channel_messages, NotificationManager.IMPORTANCE_HIGH),
            Triple("replies", R.string.notification_channel_replies, NotificationManager.IMPORTANCE_HIGH),
            Triple("team", R.string.notification_channel_team, NotificationManager.IMPORTANCE_DEFAULT),
            Triple("polls", R.string.notification_channel_polls, NotificationManager.IMPORTANCE_DEFAULT),
            Triple("events", R.string.notification_channel_events, NotificationManager.IMPORTANCE_HIGH),
            Triple("documents", R.string.notification_channel_documents, NotificationManager.IMPORTANCE_DEFAULT),
        )
        manager.createNotificationChannels(
            channels.map { (id, name, importance) ->
                NotificationChannel(id, getString(name), importance)
            },
        )
    }
}
