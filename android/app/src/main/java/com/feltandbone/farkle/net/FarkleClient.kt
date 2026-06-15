package com.feltandbone.farkle.net

import android.content.Context
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.util.Log
import com.feltandbone.farkle.model.Game
import kotlinx.serialization.encodeToString
import org.java_websocket.client.WebSocketClient
import org.java_websocket.handshake.ServerHandshake
import java.net.InetSocketAddress
import java.net.URI

/**
 * Joiner side of the live scoreboard: discovers hosts via NSD, connects over WebSocket, and
 * surfaces incoming [Snapshot]s. Read-only — the joiner can send a [PlayerClaim] but never edits.
 */
class FarkleClient(
    context: Context,
    private val onHostsChanged: (List<DiscoveredHost>) -> Unit,
    private val onSnapshot: (Game, String) -> Unit,
    private val onConnectionChanged: (Boolean) -> Unit,
    private val onHostEnded: () -> Unit,
) {
    private val nsd = context.applicationContext.getSystemService(Context.NSD_SERVICE) as NsdManager
    private var discoveryListener: NsdManager.DiscoveryListener? = null
    private val resolved = LinkedHashMap<String, NsdServiceInfo>()
    private var client: WebSocketClient? = null

    fun startDiscovery() {
        if (discoveryListener != null) return
        val listener = object : NsdManager.DiscoveryListener {
            override fun onDiscoveryStarted(serviceType: String) {}
            override fun onDiscoveryStopped(serviceType: String) {}
            override fun onStartDiscoveryFailed(serviceType: String, errorCode: Int) {}
            override fun onStopDiscoveryFailed(serviceType: String, errorCode: Int) {}
            override fun onServiceFound(info: NsdServiceInfo) {
                if (info.serviceName.startsWith("Farkle-")) resolve(info)
            }
            override fun onServiceLost(info: NsdServiceInfo) {
                resolved.remove(info.serviceName)
                emitHosts()
            }
        }
        discoveryListener = listener
        runCatching { nsd.discoverServices(FARKLE_SERVICE_TYPE, NsdManager.PROTOCOL_DNS_SD, listener) }
    }

    @Suppress("DEPRECATION")
    private fun resolve(info: NsdServiceInfo) {
        nsd.resolveService(info, object : NsdManager.ResolveListener {
            override fun onResolveFailed(info: NsdServiceInfo, errorCode: Int) {}
            override fun onServiceResolved(resolvedInfo: NsdServiceInfo) {
                resolved[resolvedInfo.serviceName] = resolvedInfo
                emitHosts()
            }
        })
    }

    private fun emitHosts() {
        onHostsChanged(resolved.keys.map { name ->
            DiscoveredHost(serviceName = name, roomCode = name.removePrefix("Farkle-"))
        })
    }

    /** Connect to a discovered host by its service name (or matching room code). */
    fun connect(roomCode: String) {
        val info = resolved.values.firstOrNull { it.serviceName.removePrefix("Farkle-") == roomCode }
            ?: return
        @Suppress("DEPRECATION")
        val host = info.host?.hostAddress ?: return
        val uri = URI.create("ws://$host:${info.port}")
        val c = object : WebSocketClient(uri) {
            override fun onOpen(handshakedata: ServerHandshake?) = onConnectionChanged(true)
            override fun onClose(code: Int, reason: String?, remote: Boolean) = onConnectionChanged(false)
            override fun onError(ex: Exception?) { Log.w(TAG, "client error: ${ex?.message}") }
            override fun onMessage(message: String) {
                runCatching {
                    val env = netJson.decodeFromString(Envelope.serializer(), message)
                    if (env.type == Envelope.SNAPSHOT && env.snapshot != null) {
                        onSnapshot(env.snapshot.game, env.snapshot.roomCode)
                        if (env.snapshot.game.endedAt != null) { /* keep showing celebration */ }
                    }
                }
            }
        }
        client = c
        runCatching { c.connect() }
    }

    fun sendClaim(claim: PlayerClaim) {
        val env = Envelope(Envelope.CLAIM, claim = claim)
        runCatching { client?.send(netJson.encodeToString(env)) }
    }

    fun stop() {
        discoveryListener?.let { runCatching { nsd.stopServiceDiscovery(it) } }
        discoveryListener = null
        runCatching { client?.close() }
        client = null
    }

    companion object {
        private const val TAG = "FarkleClient"
    }
}
