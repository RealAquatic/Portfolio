// Centralized configuration for the Plinko demo
const PLINKO_CONFIG = {
  // Canvas and world size
  windowWidth: 600,
  windowHeight: 650,

  // Pegs (smaller and denser)
  pegRows: 12,
  pegSpacing: 42,
  pegSize: 3,
  startingPegs: 1,

  // Bins / containers
  binCount: 12,
  binWidth: 5,
  binHeight: 50,
  binYOffset: 35, // distance from bottom

  // Dropper / balls (smaller balls)
  spawnOffset: 5,     // horizontal jitter from center
  spawnY: 50,
  ballRadius: 8,
  dropIntervalMs: 500,
  autoDrop: false,

  // Game
  startBalance: 1,
  defaultBet: 1,
  maxBins: 24,
  defaultAutoDropInterval: 500,

  // Crash game settings
  crash: {
    enabled: true,
    // maximum possible multiplier cap (safety)
    maxMultiplier: 50.0,
    // exponential growth controls: higher -> faster growth (exp(growthRate * seconds))
    growthRate: 0.45,
    // UI update interval while running
    tickIntervalMs: 50,
    // stochastic crash parameters: base crash hazard per second and how it scales with multiplier
    // baseCrashRatePerSecond is the baseline hazard at low multipliers (e.g., 0.02 => 2%/s)
    baseCrashRatePerSecond: 0.02,
    // hazardExponent controls how much the crash chance accelerates as the multiplier grows
    hazardExponent: 2.0,
    // legacy compatibility knobs (kept but not directly used by new model)
    minDurationMs: 1,
    maxDurationMs: 60000
  },

  // Multipliers: deterministic symmetric mapping is used to keep behavior predictable
  // Use `createMultipliers` in container.js to produce patterns like [5,3,1,0,1,3,5] depending on column count
};
