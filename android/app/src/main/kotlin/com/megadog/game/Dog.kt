package com.megadog.game

import kotlin.math.exp
import kotlin.math.ln
import kotlin.math.pow

/**
 * MegaDog Dog Entity
 *
 * Represents a dog with logarithmic storage values.
 * All economic values stored as ln(x) * PRECISION for efficiency.
 *
 * RSR Compliant: Kotlin (Memory-Safe, Type-Safe)
 */
data class Dog(
    val id: Long,
    val owner: String,  // Wallet address
    val level: Int,
    val logTreats: Long,       // ln(treats) * PRECISION
    val logMergeCount: Long,   // ln(merges) * PRECISION
    val fractalSeed: ByteArray,  // 32 bytes for Mandelbrot
    val birthBlock: Long,
    val lastUpdateBlock: Long
) {
    companion object {
        const val PRECISION = 1_000_000L
        const val STARTER_LOG_TREATS = 4_605_170L  // ln(100) * 10^6
        const val MAX_LEVEL = 255

        /**
         * Create a new starter dog (level 1)
         */
        fun createStarter(id: Long, owner: String, seed: ByteArray, block: Long): Dog {
            return Dog(
                id = id,
                owner = owner,
                level = 1,
                logTreats = STARTER_LOG_TREATS,
                logMergeCount = 0,
                fractalSeed = seed,
                birthBlock = block,
                lastUpdateBlock = block
            )
        }

        /**
         * Merge two dogs into a higher-level dog
         */
        fun merge(dog1: Dog, dog2: Dog, newId: Long, newSeed: ByteArray, block: Long): Dog? {
            // Validation
            if (dog1.owner != dog2.owner) return null
            if (dog1.level != dog2.level) return null
            if (dog1.level >= MAX_LEVEL) return null

            // Combine treats logarithmically
            val combinedLogTreats = LogMath.addLogs(dog1.logTreats, dog2.logTreats)

            // Combine merge counts + 1
            val combinedLogMerges = LogMath.addLogs(
                dog1.logMergeCount,
                dog2.logMergeCount
            ) + 693147  // +ln(2) for doubling

            return Dog(
                id = newId,
                owner = dog1.owner,
                level = dog1.level + 1,
                logTreats = combinedLogTreats,
                logMergeCount = combinedLogMerges,
                fractalSeed = newSeed,
                birthBlock = block,
                lastUpdateBlock = block
            )
        }
    }

    /**
     * Get actual treat count (converted from log)
     */
    val actualTreats: Long
        get() = LogMath.expApprox(logTreats)

    /**
     * Get actual merge count
     */
    val actualMergeCount: Long
        get() = LogMath.expApprox(logMergeCount)

    /**
     * Calculate prestige bonus if this dog were prestiged
     * Bonus = ln(e^(level/10)) = level/10 * PRECISION
     */
    val potentialPrestigeBonus: Long
        get() = (level.toLong() * PRECISION) / 10

    /**
     * Check if dog can prestige (level >= 50)
     */
    val canPrestige: Boolean
        get() = level >= 50

    /**
     * Get fractal complexity based on level and merges
     */
    val fractalComplexity: Int
        get() = minOf(8 + level / 5, 16)

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as Dog
        return id == other.id
    }

    override fun hashCode(): Int = id.hashCode()
}

/**
 * Logarithmic math utilities
 * Mirrors the Pony and Vyper implementations
 */
object LogMath {
    private const val PRECISION = Dog.PRECISION

    /**
     * Approximate natural log using bit operations
     * Returns ln(x) * PRECISION
     */
    fun lnApprox(x: Long): Long {
        if (x <= 0) return Long.MIN_VALUE

        var bitLength = 0
        var temp = x
        while (temp > 0) {
            temp = temp shr 1
            bitLength++
        }

        // ln(2) * 10^6 ≈ 693147
        return bitLength.toLong() * 693147
    }

    /**
     * Approximate e^x from ln(x)
     * Input: logX is ln(x) * PRECISION
     * Returns: x
     */
    fun expApprox(logX: Long): Long {
        if (logX <= 0) return 1

        // e^x ≈ 2^(x/ln(2))
        val powerOf2 = (logX * PRECISION) / 693147
        val exponent = (powerOf2 / PRECISION).toInt()

        if (exponent > 62) return Long.MAX_VALUE

        return 1L shl exponent
    }

    /**
     * Compute ln(a + b) from ln(a) and ln(b)
     * Uses: ln(a + b) ≈ max(ln(a), ln(b)) + ln(2) when values are similar
     */
    fun addLogs(logA: Long, logB: Long): Long {
        val diff = kotlin.math.abs(logA - logB)

        // If one is much larger, return the larger
        if (diff > 10 * PRECISION) {
            return maxOf(logA, logB)
        }

        // Otherwise approximately double
        return maxOf(logA, logB) + 693147
    }

    /**
     * Precise conversion for UI display
     */
    fun toActualValue(logValue: Long): Double {
        return exp(logValue.toDouble() / PRECISION)
    }

    /**
     * Precise conversion from actual to log
     */
    fun fromActualValue(value: Double): Long {
        return (ln(value) * PRECISION).toLong()
    }
}

/**
 * Differential update for batch commits
 */
data class DogDiff(
    val dogId: Long,
    val deltaLevel: Int,
    val deltaLogTreats: Long,
    val newFractalSeed: ByteArray?
)
