(function () {
  const binCount = PLINKO_CONFIG.binCount;       // number of boxes (try 5, 10, 20…)
  const windowWidth = PLINKO_CONFIG.windowWidth;
  const windowHeight = PLINKO_CONFIG.windowHeight;
  const binWidth = PLINKO_CONFIG.binWidth;
  const binHeight = PLINKO_CONFIG.binHeight;
  const binYOffset = PLINKO_CONFIG.binYOffset;

  // Support dynamic rebuild of bins and sensors
  let bins = [];

  function computeSpacing() {
    const bc = PLINKO_CONFIG.binCount || binCount;
    return bc > 1 ? windowWidth / (bc + 1) : windowWidth / 2;
  }

  function buildBins() {
    // remove old bins
    if (bins && bins.length) {
      bins.forEach(b => { try { World.remove(world, b); } catch (err) {} });
    }

    bins = [];
    const bc = Math.min(Math.max(1, Math.round(PLINKO_CONFIG.binCount || binCount)), PLINKO_CONFIG.maxBins || 24);
    const sp = bc > 1 ? windowWidth / (bc + 1) : windowWidth / 2;

    for (let i = 0; i < bc; i++) {
      const x = sp * (i + 1);
      const bin = Bodies.rectangle(x, windowHeight - binYOffset, binWidth, binHeight, {
        isStatic: true,
        render: { fillStyle: "#444" }
      });
      World.add(world, bin);
      bins.push(bin);
    }

    // make available
    window.__plinkoBins = bins;
  }

  // Create sensors (columns) between bins and attach multipliers
  function buildSensors() {
    // remove old sensors if any
    if (window.__plinkoSensors && window.__plinkoSensors.length) {
      window.__plinkoSensors.forEach(s => {
        try { World.remove(world, s); } catch (err) {}
      });
    }

    const bc = Math.min(Math.max(1, Math.round(PLINKO_CONFIG.binCount || binCount)), PLINKO_CONFIG.maxBins || 24);
    const columns = bc + 1;
    const sp = computeSpacing();

    const sensorsLocal = [];
    const multipliers = createMultipliers(columns);

    for (let j = 0; j < columns; j++) {
      const x = sp * (j + 0.5);
      const sensorWidth = Math.max(10, sp - binWidth);

      const sensor = Bodies.rectangle(x, windowHeight - 10, sensorWidth, 40, {
        isStatic: true,
        isSensor: true,
        render: { visible: false }
      });

      sensor.label = 'plinkoSensor';
      sensor.columnIndex = j;
      sensor.multiplier = multipliers[j];

      World.add(world, sensor);
      sensorsLocal.push(sensor);
    }

    // Make sensors accessible to UI/other scripts
    window.__plinkoSensors = sensorsLocal;
  }

  // helper to set bin count and rebuild
  window.__plinkoSetBinCount = function (newCount) {
    const n = Math.min(Math.max(1, Math.round(newCount)), PLINKO_CONFIG.maxBins || 24);
    PLINKO_CONFIG.binCount = n;
    buildBins();
    buildSensors();
    if (window.PLINKO_GAME && typeof window.PLINKO_GAME.renderMultipliers === 'function') PLINKO_GAME.renderMultipliers();
  };

  // Expose a rebuild function so UI/code can refresh multipliers on the fly
  window.__plinkoRebuildSensors = function () {
    buildSensors();
    if (window.PLINKO_GAME && typeof window.PLINKO_GAME.renderMultipliers === 'function') {
      PLINKO_GAME.renderMultipliers();
    }
  };

  // initial build
  buildBins();
  buildSensors();

  // Deterministic symmetric multipliers function (size-sensitive tiers)
  function createMultipliers(columns) {
    const result = new Array(columns);
    const center = (columns - 1) / 2;

    // Special-case: when there is only one bin (2 columns), use high-risk pattern (0,2)
    if (columns === 2) {
      result[0] = 0; result[1] = 2;
      return result;
    }

    // Choose tiers based on board width: further reduce player win probability
    // Mostly zeros and very few high multipliers
    let tiers;
    if (columns >= 20) {
      // Ultra-large boards: one rare jackpot, many zeros
      tiers = [8, 2, 1, 0.5, 0.2, 0, 0, 0];
    } else if (columns >= 16) {
      tiers = [6, 2, 1, 0.5, 0.2, 0, 0];
    } else if (columns >= 10) {
      tiers = [4, 1.5, 0.5, 0.2, 0, 0];
    } else {
      tiers = [2, 0.5, 0, 0];
    }

    const L = tiers.length;

    for (let i = 0; i < columns; i++) {
      const dist = Math.abs(i - center);
      const frac = center === 0 ? 1 : dist / center; // 0 = center, 1 = outermost

      // Map fraction to tier index (center -> highest tier)
      const tierIndex = Math.round(frac * (L - 1));
      const mult = tiers[tierIndex];

      // store multiplier (no need to randomize)
      result[i] = mult;
    }

    // Enforce caps for top tiers so there are very few high rewards
    const caps = {};
    if (columns >= 16) {
      // only one 10x, one 4x, one 2x
      Object.assign(caps, {10:1, 4:1, 2:1});
    } else if (columns >= 10) {
      // only one 4x, one 2x
      Object.assign(caps, {4:1, 2:1});
    } else {
      // only one 3x
      Object.assign(caps, {3:1});
    }

    Object.keys(caps).forEach(k => {
      const cap = caps[k];
      const keyNum = parseFloat(k);
      let indices = [];
      for (let idx = 0; idx < result.length; idx++) if (result[idx] === keyNum) indices.push(idx);
      if (indices.length > cap) {
        // keep the central ones, demote extras to next lower tier
        indices.sort((a,b)=> Math.abs(a-center)-Math.abs(b-center)); // closest to center first
        const keep = indices.slice(0, cap);
        const extras = indices.slice(cap);
        // find tier order (tiers array is descending in value)
        extras.forEach(ei => {
          const pos = tiers.indexOf(result[ei]);
          const newPos = Math.min(L-1, pos+1);
          result[ei] = tiers[newPos];
        });
      }
    });

    // Small-case for 4 columns / 3 bins to match the example [2,0,0,2]
    if (columns === 4) {
      result[0] = 2; result[1] = 0; result[2] = 0; result[3] = 2;
    }

    return result;
  }
})();