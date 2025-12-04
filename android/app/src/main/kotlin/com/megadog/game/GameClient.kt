package com.megadog.game

import kotlinx.coroutines.*
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.PrintWriter
import java.net.Socket

/**
 * MegaDog Game Client
 *
 * Handles WebSocket communication with Pony game server.
 * Manages local dog state and sync with blockchain.
 *
 * RSR Compliant: Kotlin (Memory-Safe, Type-Safe)
 */
class GameClient(
    private val serverHost: String = "localhost",
    private val serverPort: Int = 8080
) {
    private var socket: Socket? = null
    private var writer: PrintWriter? = null
    private var reader: BufferedReader? = null

    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    // State flows for reactive UI
    private val _connectionState = MutableStateFlow<ConnectionState>(ConnectionState.Disconnected)
    val connectionState: StateFlow<ConnectionState> = _connectionState

    private val _dogs = MutableStateFlow<List<Dog>>(emptyList())
    val dogs: StateFlow<List<Dog>> = _dogs

    private val _pendingActions = MutableStateFlow<Int>(0)
    val pendingActions: StateFlow<Int> = _pendingActions

    // Message queue for outgoing messages
    private val messageQueue = Channel<String>(Channel.BUFFERED)

    // User authentication
    private var userId: String? = null
    private var isAuthenticated = false

    sealed class ConnectionState {
        object Disconnected : ConnectionState()
        object Connecting : ConnectionState()
        object Connected : ConnectionState()
        data class Error(val message: String) : ConnectionState()
    }

    /**
     * Connect to game server
     */
    suspend fun connect(): Result<Unit> = withContext(Dispatchers.IO) {
        try {
            _connectionState.value = ConnectionState.Connecting

            socket = Socket(serverHost, serverPort)
            writer = PrintWriter(socket!!.getOutputStream(), true)
            reader = BufferedReader(InputStreamReader(socket!!.getInputStream()))

            // Start message listener
            scope.launch { listenForMessages() }

            // Start message sender
            scope.launch { sendQueuedMessages() }

            _connectionState.value = ConnectionState.Connected
            Result.success(Unit)
        } catch (e: Exception) {
            _connectionState.value = ConnectionState.Error(e.message ?: "Connection failed")
            Result.failure(e)
        }
    }

    /**
     * Disconnect from server
     */
    fun disconnect() {
        scope.cancel()
        writer?.close()
        reader?.close()
        socket?.close()
        _connectionState.value = ConnectionState.Disconnected
    }

    /**
     * Authenticate with wallet address
     */
    suspend fun authenticate(walletAddress: String): Result<Unit> {
        val message = JSONObject().apply {
            put("type", "auth")
            put("wallet", walletAddress)
        }

        return sendAndWait(message.toString(), "auth_ok")
    }

    /**
     * Mint a new starter dog
     */
    suspend fun mintStarterDog(): Result<Dog> {
        val message = JSONObject().apply {
            put("type", "mint")
        }

        return sendAndWaitForDog(message.toString(), "minted")
    }

    /**
     * Merge two dogs
     */
    suspend fun mergeDogs(dog1Id: Long, dog2Id: Long): Result<Dog> {
        val message = JSONObject().apply {
            put("type", "merge")
            put("dog1_id", dog1Id)
            put("dog2_id", dog2Id)
        }

        return sendAndWaitForDog(message.toString(), "merged")
    }

    /**
     * Prestige reset a dog
     */
    suspend fun prestigeReset(dogId: Long): Result<Long> {
        val message = JSONObject().apply {
            put("type", "prestige")
            put("dog_id", dogId)
        }

        return sendAndWait(message.toString(), "prestiged").map {
            dogId  // Return the dog ID that was prestiged
        }
    }

    /**
     * Fetch all dogs for current user
     */
    suspend fun fetchDogs(): Result<List<Dog>> {
        val message = JSONObject().apply {
            put("type", "get_dogs")
        }

        return sendAndWaitForDogs(message.toString())
    }

    // Private helpers

    private suspend fun listenForMessages() {
        try {
            while (isActive) {
                val line = withContext(Dispatchers.IO) {
                    reader?.readLine()
                } ?: break

                handleMessage(line)
            }
        } catch (e: Exception) {
            _connectionState.value = ConnectionState.Error(e.message ?: "Read error")
        }
    }

    private suspend fun sendQueuedMessages() {
        for (message in messageQueue) {
            try {
                withContext(Dispatchers.IO) {
                    writer?.println(message)
                }
            } catch (e: Exception) {
                // Log error but continue
            }
        }
    }

    private fun handleMessage(message: String) {
        try {
            val json = JSONObject(message)
            when (json.getString("type")) {
                "welcome" -> {
                    // Server acknowledged connection
                }
                "auth_ok" -> {
                    userId = json.getString("user_id")
                    isAuthenticated = true
                }
                "minted", "merged" -> {
                    val dogJson = json.getJSONObject("dog")
                    val dog = parseDog(dogJson)
                    updateDogList(dog)
                }
                "dogs" -> {
                    val dogsJson = json.getJSONArray("dogs")
                    val dogs = (0 until dogsJson.length()).map {
                        parseDog(dogsJson.getJSONObject(it))
                    }
                    _dogs.value = dogs
                }
                "error" -> {
                    // Handle error
                }
            }
        } catch (e: Exception) {
            // Parse error
        }
    }

    private fun parseDog(json: JSONObject): Dog {
        return Dog(
            id = json.getLong("id"),
            owner = userId ?: "",
            level = json.getInt("level"),
            logTreats = json.getLong("log_treats"),
            logMergeCount = json.optLong("log_merge_count", 0),
            fractalSeed = hexToBytes(json.optString("fractal_seed", "")),
            birthBlock = json.optLong("birth_block", 0),
            lastUpdateBlock = json.optLong("last_update_block", 0)
        )
    }

    private fun updateDogList(newDog: Dog) {
        val current = _dogs.value.toMutableList()
        val index = current.indexOfFirst { it.id == newDog.id }
        if (index >= 0) {
            current[index] = newDog
        } else {
            current.add(newDog)
        }
        _dogs.value = current
    }

    private suspend fun sendAndWait(message: String, expectedType: String): Result<Unit> {
        return withContext(Dispatchers.IO) {
            try {
                writer?.println(message)

                // Wait for response (simplified - use proper async handling in production)
                val response = reader?.readLine() ?: return@withContext Result.failure(
                    Exception("No response")
                )

                val json = JSONObject(response)
                if (json.getString("type") == expectedType) {
                    handleMessage(response)
                    Result.success(Unit)
                } else if (json.getString("type") == "error") {
                    Result.failure(Exception(json.getString("message")))
                } else {
                    Result.failure(Exception("Unexpected response"))
                }
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
    }

    private suspend fun sendAndWaitForDog(message: String, expectedType: String): Result<Dog> {
        return withContext(Dispatchers.IO) {
            try {
                writer?.println(message)

                val response = reader?.readLine() ?: return@withContext Result.failure(
                    Exception("No response")
                )

                val json = JSONObject(response)
                if (json.getString("type") == expectedType) {
                    val dog = parseDog(json.getJSONObject("dog"))
                    updateDogList(dog)
                    Result.success(dog)
                } else if (json.getString("type") == "error") {
                    Result.failure(Exception(json.getString("message")))
                } else {
                    Result.failure(Exception("Unexpected response"))
                }
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
    }

    private suspend fun sendAndWaitForDogs(message: String): Result<List<Dog>> {
        return withContext(Dispatchers.IO) {
            try {
                writer?.println(message)

                val response = reader?.readLine() ?: return@withContext Result.failure(
                    Exception("No response")
                )

                val json = JSONObject(response)
                if (json.getString("type") == "dogs") {
                    val dogsJson = json.getJSONArray("dogs")
                    val dogs = (0 until dogsJson.length()).map {
                        parseDog(dogsJson.getJSONObject(it))
                    }
                    _dogs.value = dogs
                    Result.success(dogs)
                } else if (json.getString("type") == "error") {
                    Result.failure(Exception(json.getString("message")))
                } else {
                    Result.failure(Exception("Unexpected response"))
                }
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
    }

    private fun hexToBytes(hex: String): ByteArray {
        if (hex.isEmpty() || hex.length < 2) return ByteArray(32)

        val cleanHex = if (hex.startsWith("0x")) hex.substring(2) else hex
        return ByteArray(cleanHex.length / 2) {
            cleanHex.substring(it * 2, it * 2 + 2).toInt(16).toByte()
        }
    }

    private val isActive: Boolean
        get() = socket?.isConnected == true && !socket!!.isClosed
}
