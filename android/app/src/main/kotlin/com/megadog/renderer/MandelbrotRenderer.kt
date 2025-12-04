package com.megadog.renderer

import android.content.Context
import android.graphics.Bitmap
import android.opengl.GLES30
import android.opengl.GLSurfaceView
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import javax.microedition.khronos.egl.EGLConfig
import javax.microedition.khronos.opengles.GL10

/**
 * MegaDog Mandelbrot DogTag Renderer
 *
 * GPU-accelerated 3D Mandelbulb raymarching for unique dog fractals.
 * Each dog's fractalSeed generates a deterministic, beautiful fractal.
 *
 * RSR Compliant: Kotlin (Memory-Safe, Type-Safe)
 */
class MandelbrotRenderer(
    private val context: Context
) : GLSurfaceView.Renderer {

    // Shader program
    private var programId: Int = 0

    // Uniform locations
    private var uResolutionLoc: Int = 0
    private var uSeedLoc: Int = 0
    private var uLevelLoc: Int = 0
    private var uIterationsLoc: Int = 0
    private var uPowerLoc: Int = 0
    private var uTimeLoc: Int = 0

    // Rendering state
    private var width: Int = 1080
    private var height: Int = 1920
    private var startTime: Long = System.currentTimeMillis()

    // Current dog parameters
    private var currentSeed: FloatArray = floatArrayOf(0f, 0f, 0f, 0f)
    private var currentLevel: Int = 1
    private var currentIterations: Int = 12
    private var currentPower: Float = 8f

    // Fullscreen quad
    private lateinit var quadVertices: FloatBuffer

    companion object {
        private const val TAG = "MandelbrotRenderer"

        // Vertex shader - simple fullscreen quad
        private const val VERTEX_SHADER = """
            #version 300 es
            precision highp float;

            in vec2 aPosition;
            out vec2 vUV;

            void main() {
                vUV = aPosition * 0.5 + 0.5;
                gl_Position = vec4(aPosition, 0.0, 1.0);
            }
        """

        // Fragment shader - Mandelbulb raymarching
        private const val FRAGMENT_SHADER = """
            #version 300 es
            precision highp float;

            in vec2 vUV;
            out vec4 fragColor;

            uniform vec2 uResolution;
            uniform vec4 uSeed;        // 32-byte seed packed into 4 floats
            uniform int uLevel;        // Dog level (affects complexity)
            uniform int uIterations;   // Fractal iterations
            uniform float uPower;      // Mandelbulb power (8 = classic)
            uniform float uTime;       // Animation time

            const int MAX_STEPS = 128;
            const float MIN_DIST = 0.001;
            const float MAX_DIST = 100.0;
            const float BAILOUT = 2.0;

            // Signed Distance Function for Mandelbulb
            float mandelbulbSDF(vec3 pos) {
                vec3 z = pos;
                float dr = 1.0;
                float r = 0.0;

                // Seed-based rotation
                float seedRotX = uSeed.x * 6.28318;
                float seedRotY = uSeed.y * 6.28318;
                float seedRotZ = uSeed.z * 6.28318;

                // Apply seed rotation
                mat3 rotX = mat3(
                    1.0, 0.0, 0.0,
                    0.0, cos(seedRotX), -sin(seedRotX),
                    0.0, sin(seedRotX), cos(seedRotX)
                );
                mat3 rotY = mat3(
                    cos(seedRotY), 0.0, sin(seedRotY),
                    0.0, 1.0, 0.0,
                    -sin(seedRotY), 0.0, cos(seedRotY)
                );

                z = rotX * rotY * z;

                for (int i = 0; i < 16; i++) {
                    if (i >= uIterations) break;

                    r = length(z);
                    if (r > BAILOUT) break;

                    // Convert to spherical coordinates
                    float theta = acos(z.z / r);
                    float phi = atan(z.y, z.x);
                    dr = pow(r, uPower - 1.0) * uPower * dr + 1.0;

                    // Scale and rotate the point
                    float zr = pow(r, uPower);
                    theta *= uPower;
                    phi *= uPower;

                    // Add seed variation
                    theta += uSeed.w * 0.5;
                    phi += (uSeed.x + uSeed.y) * 0.3;

                    // Convert back to Cartesian
                    z = zr * vec3(
                        sin(theta) * cos(phi),
                        sin(phi) * sin(theta),
                        cos(theta)
                    ) + pos;
                }

                return 0.5 * log(r) * r / dr;
            }

            // Raymarching
            float raymarch(vec3 ro, vec3 rd) {
                float t = 0.0;

                for (int i = 0; i < MAX_STEPS; i++) {
                    vec3 p = ro + rd * t;
                    float d = mandelbulbSDF(p);

                    if (d < MIN_DIST) return t;
                    if (t > MAX_DIST) break;

                    t += d * 0.5;  // Slower step for quality
                }

                return -1.0;
            }

            // Calculate normal via gradient
            vec3 calcNormal(vec3 p) {
                vec2 e = vec2(0.001, 0.0);
                return normalize(vec3(
                    mandelbulbSDF(p + e.xyy) - mandelbulbSDF(p - e.xyy),
                    mandelbulbSDF(p + e.yxy) - mandelbulbSDF(p - e.yxy),
                    mandelbulbSDF(p + e.yyx) - mandelbulbSDF(p - e.yyx)
                ));
            }

            // Level-based color palette
            vec3 getColor(float t, int level) {
                // Higher level = more complex colors
                float complexity = float(level) / 50.0;

                vec3 a = vec3(0.5, 0.5, 0.5);
                vec3 b = vec3(0.5, 0.5, 0.5);
                vec3 c = vec3(1.0 + complexity, 1.0, 1.0 - complexity * 0.5);
                vec3 d = vec3(
                    uSeed.x * 0.5 + 0.25,
                    uSeed.y * 0.5 + 0.25,
                    uSeed.z * 0.5 + 0.25
                );

                return a + b * cos(6.28318 * (c * t + d));
            }

            void main() {
                vec2 uv = (gl_FragCoord.xy - 0.5 * uResolution) / min(uResolution.x, uResolution.y);

                // Camera setup (seed-based position)
                float camDist = 2.5 - float(uLevel) * 0.01;
                float camAngle = uTime * 0.1 + uSeed.w * 6.28318;

                vec3 ro = vec3(
                    sin(camAngle) * camDist,
                    uSeed.z * 0.5,
                    cos(camAngle) * camDist
                );
                vec3 target = vec3(0.0);
                vec3 forward = normalize(target - ro);
                vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), forward));
                vec3 up = cross(forward, right);

                vec3 rd = normalize(forward + uv.x * right + uv.y * up);

                // Raymarch
                float t = raymarch(ro, rd);

                vec3 col;
                if (t > 0.0) {
                    vec3 p = ro + rd * t;
                    vec3 n = calcNormal(p);

                    // Lighting
                    vec3 lightDir = normalize(vec3(1.0, 1.0, -1.0));
                    float diff = max(dot(n, lightDir), 0.0);
                    float amb = 0.2;

                    // Distance-based coloring
                    float orbit = length(p) * 0.5;
                    col = getColor(orbit, uLevel) * (diff + amb);

                    // Rim lighting
                    float rim = pow(1.0 - max(dot(-rd, n), 0.0), 3.0);
                    col += vec3(0.2, 0.3, 0.5) * rim;

                    // Level glow (higher level = more glow)
                    col += vec3(0.1, 0.05, 0.15) * float(uLevel) / 100.0;
                } else {
                    // Background gradient
                    col = mix(
                        vec3(0.02, 0.02, 0.05),
                        vec3(0.1, 0.05, 0.15),
                        uv.y + 0.5
                    );

                    // Stars based on seed
                    float stars = fract(sin(dot(uv * 100.0, vec2(uSeed.x, uSeed.y))) * 43758.5453);
                    if (stars > 0.998) {
                        col += vec3(0.8);
                    }
                }

                // Vignette
                float vignette = 1.0 - length(uv) * 0.5;
                col *= vignette;

                // Gamma correction
                col = pow(col, vec3(0.4545));

                fragColor = vec4(col, 1.0);
            }
        """
    }

    override fun onSurfaceCreated(gl: GL10?, config: EGLConfig?) {
        GLES30.glClearColor(0.02f, 0.02f, 0.05f, 1.0f)

        // Create fullscreen quad
        val vertices = floatArrayOf(
            -1f, -1f,
            1f, -1f,
            -1f, 1f,
            1f, 1f
        )
        quadVertices = ByteBuffer.allocateDirect(vertices.size * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()
            .put(vertices)
        quadVertices.position(0)

        // Compile shaders
        val vertexShader = compileShader(GLES30.GL_VERTEX_SHADER, VERTEX_SHADER)
        val fragmentShader = compileShader(GLES30.GL_FRAGMENT_SHADER, FRAGMENT_SHADER)

        // Link program
        programId = GLES30.glCreateProgram()
        GLES30.glAttachShader(programId, vertexShader)
        GLES30.glAttachShader(programId, fragmentShader)
        GLES30.glLinkProgram(programId)

        // Get uniform locations
        uResolutionLoc = GLES30.glGetUniformLocation(programId, "uResolution")
        uSeedLoc = GLES30.glGetUniformLocation(programId, "uSeed")
        uLevelLoc = GLES30.glGetUniformLocation(programId, "uLevel")
        uIterationsLoc = GLES30.glGetUniformLocation(programId, "uIterations")
        uPowerLoc = GLES30.glGetUniformLocation(programId, "uPower")
        uTimeLoc = GLES30.glGetUniformLocation(programId, "uTime")

        startTime = System.currentTimeMillis()
    }

    override fun onSurfaceChanged(gl: GL10?, width: Int, height: Int) {
        this.width = width
        this.height = height
        GLES30.glViewport(0, 0, width, height)
    }

    override fun onDrawFrame(gl: GL10?) {
        GLES30.glClear(GLES30.GL_COLOR_BUFFER_BIT)

        GLES30.glUseProgram(programId)

        // Set uniforms
        GLES30.glUniform2f(uResolutionLoc, width.toFloat(), height.toFloat())
        GLES30.glUniform4fv(uSeedLoc, 1, currentSeed, 0)
        GLES30.glUniform1i(uLevelLoc, currentLevel)
        GLES30.glUniform1i(uIterationsLoc, currentIterations)
        GLES30.glUniform1f(uPowerLoc, currentPower)

        val time = (System.currentTimeMillis() - startTime) / 1000f
        GLES30.glUniform1f(uTimeLoc, time)

        // Draw fullscreen quad
        val positionLoc = GLES30.glGetAttribLocation(programId, "aPosition")
        GLES30.glEnableVertexAttribArray(positionLoc)
        GLES30.glVertexAttribPointer(positionLoc, 2, GLES30.GL_FLOAT, false, 0, quadVertices)

        GLES30.glDrawArrays(GLES30.GL_TRIANGLE_STRIP, 0, 4)

        GLES30.glDisableVertexAttribArray(positionLoc)
    }

    /**
     * Update the fractal with new dog parameters
     */
    fun setDogParams(seed: ByteArray, level: Int, mergeCount: Int) {
        // Convert 32-byte seed to 4 floats
        currentSeed = seedToFloats(seed)
        currentLevel = level

        // Higher level = more iterations (more complex fractal)
        currentIterations = minOf(8 + level / 5, 16)

        // Vary power slightly based on merge count
        currentPower = 8f + (mergeCount % 10) * 0.1f
    }

    /**
     * Export current frame as high-resolution bitmap for wallpaper/NFT
     */
    fun exportToBitmap(width: Int, height: Int): Bitmap {
        // Create framebuffer at target resolution
        val framebuffer = IntArray(1)
        GLES30.glGenFramebuffers(1, framebuffer, 0)
        GLES30.glBindFramebuffer(GLES30.GL_FRAMEBUFFER, framebuffer[0])

        // Create texture for rendering
        val texture = IntArray(1)
        GLES30.glGenTextures(1, texture, 0)
        GLES30.glBindTexture(GLES30.GL_TEXTURE_2D, texture[0])
        GLES30.glTexImage2D(
            GLES30.GL_TEXTURE_2D, 0, GLES30.GL_RGBA,
            width, height, 0,
            GLES30.GL_RGBA, GLES30.GL_UNSIGNED_BYTE, null
        )
        GLES30.glFramebufferTexture2D(
            GLES30.GL_FRAMEBUFFER, GLES30.GL_COLOR_ATTACHMENT0,
            GLES30.GL_TEXTURE_2D, texture[0], 0
        )

        // Render at high resolution
        val oldWidth = this.width
        val oldHeight = this.height
        this.width = width
        this.height = height
        GLES30.glViewport(0, 0, width, height)

        onDrawFrame(null)

        // Read pixels
        val buffer = ByteBuffer.allocateDirect(width * height * 4)
        buffer.order(ByteOrder.nativeOrder())
        GLES30.glReadPixels(0, 0, width, height, GLES30.GL_RGBA, GLES30.GL_UNSIGNED_BYTE, buffer)
        buffer.rewind()

        // Create bitmap
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        bitmap.copyPixelsFromBuffer(buffer)

        // Cleanup
        GLES30.glBindFramebuffer(GLES30.GL_FRAMEBUFFER, 0)
        GLES30.glDeleteFramebuffers(1, framebuffer, 0)
        GLES30.glDeleteTextures(1, texture, 0)

        // Restore viewport
        this.width = oldWidth
        this.height = oldHeight
        GLES30.glViewport(0, 0, oldWidth, oldHeight)

        // Flip vertically (OpenGL origin is bottom-left)
        return flipBitmapVertically(bitmap)
    }

    private fun compileShader(type: Int, source: String): Int {
        val shader = GLES30.glCreateShader(type)
        GLES30.glShaderSource(shader, source)
        GLES30.glCompileShader(shader)

        val compiled = IntArray(1)
        GLES30.glGetShaderiv(shader, GLES30.GL_COMPILE_STATUS, compiled, 0)
        if (compiled[0] == 0) {
            val error = GLES30.glGetShaderInfoLog(shader)
            GLES30.glDeleteShader(shader)
            throw RuntimeException("Shader compilation failed: $error")
        }

        return shader
    }

    private fun seedToFloats(seed: ByteArray): FloatArray {
        // Convert 32-byte seed to 4 normalised floats
        val result = FloatArray(4)
        for (i in 0 until 4) {
            var value = 0
            for (j in 0 until 8) {
                val idx = i * 8 + j
                if (idx < seed.size) {
                    value = value xor (seed[idx].toInt() and 0xFF shl (j * 4 % 32))
                }
            }
            result[i] = (value.toFloat() / Int.MAX_VALUE.toFloat() + 1f) / 2f
        }
        return result
    }

    private fun flipBitmapVertically(source: Bitmap): Bitmap {
        val matrix = android.graphics.Matrix()
        matrix.preScale(1f, -1f)
        return Bitmap.createBitmap(source, 0, 0, source.width, source.height, matrix, true)
    }
}
