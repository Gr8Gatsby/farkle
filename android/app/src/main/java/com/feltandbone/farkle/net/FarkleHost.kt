package com.feltandbone.farkle.net

import android.content.Context
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.util.Log
import com.feltandbone.farkle.model.Game
import kotlinx.serialization.encodeToString
import org.java_websocket.WebSocket
import org.java_websocket.handshake.ClientHandshake
import org.java_websocket.server.WebSocketServer
import java.net.InetSocketAddress

/**
 * Hosts the live scoreboard: a small WebSocket server broadcasting [Snapshot]s, advertised on the
 * local network via NSD (Bonjour). Joiners — on any platform — can discover and mirror the game.
 * Nothing leaves the LAN.
 */
class FarkleHost(
    context: Context,
    val roomCode: String,
    private val onClaim: (PlayerClaim) -> Unit,
    private val onViewerCountChanged: (Int) -> Unit,
) {
    private val appContext = context.applicationContext
    private val nsd = appContext.getSystemService(Context.NSD_SERVICE) as NsdManager
    private var server: WsServer? = null
    private var registration: NsdManager.RegistrationListener? = null
    private var latestJson: String? = null
    private var started = false

    val serviceName = "Farkle-$roomCode"

    fun start() {
        if (started) return
        started = true
        try {
            val s = WsServer(InetSocketAddress(0))
            s.isReuseAddr = true
            server = s
            s.start() // onStart() fires with the bound port -> register NSD there
        } catch (e: Exception) {
            Log.w(TAG, "host start failed: ${e.message}")
        }
    }

    fun broadcast(game: Game) {
        val env = Envelope(Envelope.SNAPSHOT, snapshot = Snapshot(roomCode, game))
        val msg = netJson.encodeToString(env)
        latestJson = msg
        server?.connections?.forEach { runCatching { it.send(msg) } }
    }

    fun viewerCount(): Int = server?.connections?.size ?: 0

    fun stop() {
        started = false
        registration?.let { runCatching { nsd.unregisterService(it) } }
        registration = null
        runCatching { server?.stop(0) }
        server = null
    }

    private fun registerNsd(port: Int) {
        val info = NsdServiceInfo().apply {
            serviceName = this@FarkleHost.serviceName
            serviceType = FARKLE_SERVICE_TYPE
            setPort(port)
        }
        val listener = object : NsdManager.RegistrationListener {
            override fun onServiceRegistered(info: NsdServiceInfo) {
                Log.i(TAG, "NSD registered: ${info.serviceName} on $port")
            }
            override fun onRegistrationFailed(info: NsdServiceInfo, errorCode: Int) {
                Log.w(TAG, "NSD registration failed: $errorCode")
            }
            override fun onServiceUnregistered(info: NsdServiceInfo) {}
            override fun onUnregistrationFailed(info: NsdServiceInfo, errorCode: Int) {}
        }
        registration = listener
        runCatching { nsd.registerService(info, NsdManager.PROTOCOL_DNS_SD, listener) }
    }

    private inner class WsServer(addr: InetSocketAddress) : WebSocketServer(addr) {
        override fun onStart() {
            registerNsd(port)
        }

        override fun onOpen(conn: WebSocket, handshake: ClientHandshake) {
            latestJson?.let { runCatching { conn.send(it) } }
            onViewerCountChanged(connections.size)
        }

        override fun onClose(conn: WebSocket, code: Int, reason: String?, remote: Boolean) {
            onViewerCountChanged(connections.size)
        }

        override fun onMessage(conn: WebSocket, message: String) {
            runCatching {
                val env = netJson.decodeFromString(Envelope.serializer(), message)
                if (env.type == Envelope.CLAIM && env.claim != null) onClaim(env.claim)
            }
        }

        override fun onError(conn: WebSocket?, ex: Exception) {
            Log.w(TAG, "ws error: ${ex.message}")
        }
    }

    companion object {
        private const val TAG = "FarkleHost"
        fun randomRoomCode(): String = (1000..9999).random().toString()
    }
}
