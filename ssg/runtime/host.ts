// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
/**
 * hackenbush-ssg Host Runtime
 *
 * This host provides ONLY:
 *   - Load and parse RLE pattern files
 *   - Run the Game of Life simulation
 *   - Read output cells at designated locations
 *   - Write resulting bytes to files
 *
 * The host does NOT contain any SSG logic.
 * ALL SSG logic is encoded in the Life pattern.
 */

// Constants for the simulation
const OUTPUT_REGION_X = 1000;
const OUTPUT_REGION_Y = 0;
const OUTPUT_WIDTH = 128;
const OUTPUT_HEIGHT = 32;
const DEFAULT_GENERATIONS = 10000;

type Grid = Set<string>;

// Parse RLE (Run Length Encoded) pattern format
function parseRLE(content: string): { width: number; height: number; cells: Grid } {
  const lines = content.split("\n");
  const cells: Grid = new Set();

  let width = 0;
  let height = 0;
  let x = 0;
  let y = 0;
  let patternStarted = false;

  for (const line of lines) {
    // Skip comments
    if (line.startsWith("#")) continue;

    // Parse header
    if (line.startsWith("x")) {
      const match = line.match(/x\s*=\s*(\d+).*y\s*=\s*(\d+)/);
      if (match) {
        width = parseInt(match[1]);
        height = parseInt(match[2]);
      }
      patternStarted = true;
      continue;
    }

    if (!patternStarted) continue;

    // Parse pattern data
    let count = 0;
    for (const char of line) {
      if (char >= "0" && char <= "9") {
        count = count * 10 + parseInt(char);
      } else if (char === "b") {
        // Dead cells
        x += count || 1;
        count = 0;
      } else if (char === "o") {
        // Live cells
        const n = count || 1;
        for (let i = 0; i < n; i++) {
          cells.add(`${x},${y}`);
          x++;
        }
        count = 0;
      } else if (char === "$") {
        // End of row
        y += count || 1;
        x = 0;
        count = 0;
      } else if (char === "!") {
        // End of pattern
        break;
      }
    }
  }

  return { width, height, cells };
}

// Get cell state
function isAlive(grid: Grid, x: number, y: number): boolean {
  return grid.has(`${x},${y}`);
}

// Count live neighbors
function countNeighbors(grid: Grid, x: number, y: number): number {
  let count = 0;
  for (let dy = -1; dy <= 1; dy++) {
    for (let dx = -1; dx <= 1; dx++) {
      if (dx === 0 && dy === 0) continue;
      if (isAlive(grid, x + dx, y + dy)) count++;
    }
  }
  return count;
}

// Run one generation
function evolve(grid: Grid): Grid {
  const newGrid: Grid = new Set();
  const candidates: Set<string> = new Set();

  // Collect all cells to check (alive cells + their neighbors)
  for (const cell of grid) {
    const [x, y] = cell.split(",").map(Number);
    for (let dy = -1; dy <= 1; dy++) {
      for (let dx = -1; dx <= 1; dx++) {
        candidates.add(`${x + dx},${y + dy}`);
      }
    }
  }

  // Apply rules
  for (const cell of candidates) {
    const [x, y] = cell.split(",").map(Number);
    const alive = isAlive(grid, x, y);
    const neighbors = countNeighbors(grid, x, y);

    // B3/S23 rules
    if (alive && (neighbors === 2 || neighbors === 3)) {
      newGrid.add(cell);
    } else if (!alive && neighbors === 3) {
      newGrid.add(cell);
    }
  }

  return newGrid;
}

// Read output region as bytes
function readOutput(grid: Grid): Uint8Array {
  const bytes: number[] = [];

  for (let row = 0; row < OUTPUT_HEIGHT; row++) {
    let byte = 0;
    for (let bit = 0; bit < 8; bit++) {
      const x = OUTPUT_REGION_X + (row * 8) + bit;
      const y = OUTPUT_REGION_Y;
      if (isAlive(grid, x, y)) {
        byte |= 1 << (7 - bit);
      }
    }
    if (byte > 0) bytes.push(byte);
  }

  return new Uint8Array(bytes);
}

// Main entry point
async function main() {
  const args = Deno.args;
  const patternFile = args[0] || "src/hackenbush.rle";
  const generations = parseInt(args[1]) || DEFAULT_GENERATIONS;
  const outputFile = args[2] || "_site/index.html";

  console.log("[LIFE HOST] hackenbush-ssg runtime");
  console.log(`[LIFE HOST] Pattern: ${patternFile}`);
  console.log(`[LIFE HOST] Generations: ${generations}`);

  // Load pattern
  const content = await Deno.readTextFile(patternFile);
  let { cells: grid } = parseRLE(content);

  console.log(`[LIFE HOST] Initial population: ${grid.size}`);

  // Run simulation
  for (let gen = 0; gen < generations; gen++) {
    grid = evolve(grid);

    if (gen % 1000 === 0) {
      console.log(`[LIFE HOST] Generation ${gen}, population: ${grid.size}`);
    }
  }

  console.log(`[LIFE HOST] Final population: ${grid.size}`);

  // Read output
  const output = readOutput(grid);

  // Ensure output directory exists
  try {
    await Deno.mkdir("_site", { recursive: true });
  } catch {
    // Directory exists
  }

  // Write output
  await Deno.writeFile(outputFile, output);

  console.log(`[LIFE HOST] Output written to: ${outputFile}`);
  console.log(`[LIFE HOST] Output size: ${output.length} bytes`);

  // Also show what was generated (for debugging)
  const text = new TextDecoder().decode(output);
  if (text.length > 0) {
    console.log("[LIFE HOST] Output preview:");
    console.log(text.slice(0, 200));
  } else {
    console.log("[LIFE HOST] No output generated (pattern needs more generations or different setup)");
  }
}

main();
