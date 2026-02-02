(function () {
  // Initialize game state
  const startBalance = PLINKO_CONFIG.startBalance || 100;

  window.PLINKO_GAME = {
    balance: startBalance,
    currentBet: PLINKO_CONFIG.defaultBet || 1,
    onCollision: onCollision
  };

  // Create UI container and place it in the sidebar (outside the rendered world)
  const ui = document.createElement('div');
  ui.id = 'plinko-ui';
  ui.style.cssText = 'display:flex; flex-direction:column; gap:8px; z-index:9999; color:#111; font-family:Inter, Arial, Helvetica, sans-serif;';
  ui.innerHTML = `
    <div style="font-weight:800; font-size:16px">Balance: £<span id="plinko-balance">${PLINKO_GAME.balance.toFixed(2)}</span></div>
    <div style="display:flex; gap:8px; align-items:center;">
      <label style="font-size:13px">Bet: £<input id="plinko-bet" type="number" value="${PLINKO_GAME.currentBet}" min="0.01" step="0.01" style="width:90px; margin-left:6px"></label>
      <div style="display:flex; gap:6px;">
        <button id="plinko-bet-1" class="btn btn-ghost">£1</button>
        <button id="plinko-bet-5" class="btn btn-ghost">£5</button>
        <button id="plinko-bet-10" class="btn btn-ghost">£10</button>
        <button id="plinko-bet-100" class="btn btn-ghost">£100</button>
      </div>
    </div>
    <div style="font-size:12px; color:#666">Click the board to drop (bet deducted on drop). Multipliers are shown on the board.</div>
  `;
  const sidebar = document.getElementById('plinko-sidebar') || document.body;
  sidebar.appendChild(ui);

  // Bin count control
  const binWrapper = document.createElement('div');
  binWrapper.style.cssText = 'margin-top:10px; display:flex; gap:8px; align-items:center;';
  binWrapper.innerHTML = `
    <label style="font-weight:700; width:80px">Bins</label>
    <input id="plinko-bin-slider" type="range" min="1" max="${PLINKO_CONFIG.maxBins}" value="${PLINKO_CONFIG.binCount}" style="flex:1">
    <div style="width:36px; text-align:center" id="plinko-bin-count">${PLINKO_CONFIG.binCount}</div>
  `;
  // Group modifiers
  const modifiers = document.createElement('div');
  modifiers.id = 'plinko-modifiers';
  modifiers.className = 'plinko-section';

  // Auto-drop control
  const autoWrapper = document.createElement('div');
  autoWrapper.className = 'plinko-section';
  autoWrapper.style.cssText = 'display:flex; gap:8px; align-items:center;';
  autoWrapper.innerHTML = `
    <div style="display:flex; gap:8px; align-items:center; width:100%">
      <label style="font-weight:700; width:80px">Auto Drop</label>
      <input id="plinko-autodrop" type="checkbox" ${PLINKO_CONFIG.autoDrop ? 'checked' : ''}>
      <label style="font-size:12px; color:#666">Interval (ms)</label>
      <input id="plinko-auto-interval" type="number" value="${PLINKO_CONFIG.dropIntervalMs || PLINKO_CONFIG.defaultAutoDropInterval}" min="50" step="50" style="width:82px">
      <button id="plinko-auto-toggle" class="btn">${PLINKO_CONFIG.autoDrop ? 'Stop' : 'Start'}</button>
    </div>
  `;

  // assemble modifiers
  modifiers.appendChild(binWrapper);
  modifiers.appendChild(autoWrapper);
  sidebar.appendChild(modifiers);



  // wire up controls
  const betInput = document.getElementById('plinko-bet');
  betInput.addEventListener('change', function (e) {
    const v = parseFloat(e.target.value);
    if (!isNaN(v) && v >= 0) {
      PLINKO_GAME.currentBet = v;
    }
  });

  // bin slider
  const binSlider = document.getElementById('plinko-bin-slider');
  const binCountLabel = document.getElementById('plinko-bin-count');
  const MAX_BINS = PLINKO_CONFIG.maxBins || 24;
  binSlider.addEventListener('input', function (e) {
    const v = Math.max(1, Math.min(MAX_BINS, Math.round(e.target.value)));
    binCountLabel.textContent = v;
  });
  binSlider.addEventListener('change', function (e) {
    const v = Math.max(1, Math.min(MAX_BINS, Math.round(e.target.value)));
    if (window.__plinkoSetBinCount) window.__plinkoSetBinCount(v);
    // ensure labels update
    if (window.PLINKO_GAME && typeof window.PLINKO_GAME.renderMultipliers === 'function') PLINKO_GAME.renderMultipliers();
  });

  // auto-drop handlers
  const autoCheckbox = document.getElementById('plinko-autodrop');
  const autoIntervalInput = document.getElementById('plinko-auto-interval');
  const autoToggleBtn = document.getElementById('plinko-auto-toggle');

  function updateAutoUI(running) {
    autoCheckbox.checked = !!running;
    autoToggleBtn.textContent = running ? 'Stop' : 'Start';
  }

  const DEFAULT_AUTO_MS = PLINKO_CONFIG.defaultAutoDropInterval || 500;
  autoCheckbox.addEventListener('change', function (e) {
    const ms = Math.max(50, Math.round(parseInt(autoIntervalInput.value) || DEFAULT_AUTO_MS));
    if (e.target.checked) {
      if (window.__plinkoStartAutoDrop) window.__plinkoStartAutoDrop(ms);
      updateAutoUI(true);
    } else {
      if (window.__plinkoStopAutoDrop) window.__plinkoStopAutoDrop();
      updateAutoUI(false);
    }
  });

  autoToggleBtn.addEventListener('click', function () {
    if (autoCheckbox.checked) {
      if (window.__plinkoStopAutoDrop) window.__plinkoStopAutoDrop();
      updateAutoUI(false);
      autoCheckbox.checked = false;
    } else {
      const ms = Math.max(50, Math.round(parseInt(autoIntervalInput.value) || DEFAULT_AUTO_MS));
      if (window.__plinkoStartAutoDrop) window.__plinkoStartAutoDrop(ms);
      updateAutoUI(true);
      autoCheckbox.checked = true;
    }
  });

  // ensure toggle matches initial state
  updateAutoUI(!!PLINKO_CONFIG.autoDrop);

  // --- Crash mode UI ---
  const crashWrapper = document.createElement('div');
  crashWrapper.style.cssText = 'margin-top:12px; padding-top:8px; border-top:1px dashed #eee; display:flex; flex-direction:column; gap:8px';
  crashWrapper.className = 'plinko-crash plinko-section';
  crashWrapper.innerHTML = `
    <div class="plinko-heading">Crash Mode</div>
    <div style="display:flex; gap:8px; align-items:center;">
      <label>Bet: £<input id="crash-bet" type="number" min="0.01" step="0.01" value="${PLINKO_GAME.currentBet}" style="width:90px"></label>
      <button id="crash-start" class="btn btn-primary">Start</button>
      <button id="crash-cashout" class="btn" disabled>Cash Out</button>
    </div>
    <div style="font-weight:700">Multiplier: <span id="crash-mult">1.00x</span></div>
    <div id="crash-status" style="font-size:12px;color:#666">Idle</div>
  `;

  // append Crash panel under modifiers (after creation to avoid reference errors)
  sidebar.appendChild(crashWrapper);

  // Crash state
  let crashState = { running: false, current: 1, target: 1, startTime: 0, duration: 0, bet: 0, intervalId: null };

  const crashStartBtn = document.getElementById('crash-start');
  const crashCashBtn = document.getElementById('crash-cashout');
  const crashMultEl = document.getElementById('crash-mult');
  const crashStatusEl = document.getElementById('crash-status');
  const crashBetInput = document.getElementById('crash-bet');

  function updateCrashUI() {
    crashMultEl.textContent = `${crashState.current.toFixed(2)}x`;
    crashStatusEl.textContent = crashState.running ? 'Running' : 'Idle';
    crashStartBtn.disabled = crashState.running;
    crashCashBtn.disabled = !crashState.running;
  }

  function endCrash(crashed) {
    if (crashState.intervalId) clearInterval(crashState.intervalId);
    crashState.intervalId = null;
    crashState.running = false;
    if (crashed) {
      crashStatusEl.textContent = `Crashed at ${crashState.current.toFixed(2)}x`;
    } else {
      crashStatusEl.textContent = `Cashed out ${crashState.current.toFixed(2)}x`;
    }
    updateCrashUI();
    setTimeout(() => { crashState.current = 1; crashMultEl.textContent = `1.00x`; crashStatusEl.textContent = 'Idle'; }, 1200);
  }

  function startCrash() {
    if (crashState.running) return;
    const bet = parseFloat(crashBetInput.value) || 0;
    if (!bet || bet <= 0) return;
    if (PLINKO_GAME.balance < bet) {
      const el = document.getElementById('plinko-balance'); if (el) { el.style.color = 'red'; setTimeout(()=>el.style.color=''); }
      return;
    }

    // Deduct bet
    PLINKO_GAME.balance -= bet; PLINKO_GAME.updateUI();

    crashState.bet = bet;
    crashState.running = true;
    crashState.current = 1;
    crashState.startTime = Date.now();

    // exponential growth + stochastic crash model
    crashState.current = 1;
    const tickMs = PLINKO_CONFIG.crash.tickIntervalMs || 50;
    const growthRate = PLINKO_CONFIG.crash.growthRate || 0.45;
    const baseRate = PLINKO_CONFIG.crash.baseCrashRatePerSecond || 0.02;
    const hazardExp = PLINKO_CONFIG.crash.hazardExponent || 2.0;
    const max = PLINKO_CONFIG.crash.maxMultiplier || 50;

    crashState.intervalId = setInterval(() => {
      const elapsed = Date.now() - crashState.startTime;

      // exponential growth (starts slow, accelerates): multiplier = exp(growthRate * seconds)
      let m = Math.exp(growthRate * (elapsed / 1000));
      if (m > max) m = max;
      crashState.current = m;

      // compute per-tick crash probability (increases with multiplier)
      // convert per-second hazard to per-tick probability: 1 - exp(-rate * dt)
      const perSecond = baseRate * Math.pow(crashState.current, hazardExp);
      const crashProb = 1 - Math.exp(-perSecond * (tickMs / 1000));

      updateCrashUI();

      // decide if a crash happens at this tick
      if (Math.random() < crashProb) {
        endCrash(true);
        return;
      }

      // if we've reached the safety cap, force a crash
      if (crashState.current >= max) {
        endCrash(true);
      }
    }, tickMs);
  }

  function cashOutCrash() {
    if (!crashState.running) return;
    const payout = crashState.bet * crashState.current;
    PLINKO_GAME.balance += payout;
    PLINKO_GAME.updateUI();
    endCrash(false);
  }

  crashStartBtn.addEventListener('click', startCrash);
  crashCashBtn.addEventListener('click', cashOutCrash);

  // wire quick bet buttons to crash input
  document.getElementById('plinko-bet-1').addEventListener('click', () => { PLINKO_GAME.currentBet = 1; betInput.value = 1; crashBetInput.value = 1; });
  document.getElementById('plinko-bet-5').addEventListener('click', () => { PLINKO_GAME.currentBet = 5; betInput.value = 5; crashBetInput.value = 5; });
  document.getElementById('plinko-bet-10').addEventListener('click', () => { PLINKO_GAME.currentBet = 10; betInput.value = 10; crashBetInput.value = 10; });
  document.getElementById('plinko-bet-100').addEventListener('click', () => { PLINKO_GAME.currentBet = 100; betInput.value = 100; crashBetInput.value = 100; });

  // End Crash UI

  document.getElementById('plinko-bet-1').addEventListener('click', () => { PLINKO_GAME.currentBet = 1; betInput.value = 1; });
  document.getElementById('plinko-bet-5').addEventListener('click', () => { PLINKO_GAME.currentBet = 5; betInput.value = 5; });
  document.getElementById('plinko-bet-10').addEventListener('click', () => { PLINKO_GAME.currentBet = 10; betInput.value = 10; });
  document.getElementById('plinko-bet-100').addEventListener('click', () => { PLINKO_GAME.currentBet = 100; betInput.value = 100; });

  // update UI helper
  function updateUI() {
    const b = document.getElementById('plinko-balance');
    if (b) b.textContent = PLINKO_GAME.balance.toFixed(2);
  }
  PLINKO_GAME.updateUI = updateUI;

  // Render multiplier labels above the canvas using sensors created in container.js
  function renderMultipliers() {
    const canvas = document.querySelector('#plinko-canvas canvas');
    if (!canvas) return;
    const rect = canvas.getBoundingClientRect();

    // remove existing labels
    let labels = document.getElementById('plinko-mult-labels');
    if (labels) labels.remove();

    labels = document.createElement('div');
    labels.id = 'plinko-mult-labels';
    labels.style.cssText = `position:absolute; left:0; top:0; width:${rect.width}px; height:${rect.height}px; pointer-events:none; z-index:9998;`;

    const sensors = window.__plinkoSensors || [];
    sensors.forEach(sensor => {
      const relX = (sensor.position.x / PLINKO_CONFIG.windowWidth) * rect.width;
      const y = rect.height - PLINKO_CONFIG.binYOffset - 40; // position above bins

      const label = document.createElement('div');
      label.className = 'plinko-label';
      // color by multiplier (including fractional values)
      let bg = '#f8f8f8';
      if (sensor.multiplier >= 10) bg = '#7c3aed'; // purple for top jackpot (now 10x)
      else if (sensor.multiplier >= 4) bg = '#ffd700'; // gold
      else if (sensor.multiplier >= 2) bg = '#ffa94d'; // orange
      else if (sensor.multiplier >= 1) bg = '#9be564'; // green
      else if (sensor.multiplier >= 0.5) bg = '#a5d8ff'; // blue-ish for 0.5x
      else bg = '#f8f8f8';

      label.style.cssText = `left:${relX}px; top:${y}px; background:${bg};`;
      label.textContent = `${sensor.multiplier}x`;
      labels.appendChild(label);
    });

    // append to the canvas container so it's visually over the board
    const canvasContainer = document.getElementById('plinko-canvas');
    if (canvasContainer) canvasContainer.appendChild(labels);
  }

  // update labels on resize or after a short delay
  window.addEventListener('resize', renderMultipliers);
  setTimeout(renderMultipliers, 300);
  PLINKO_GAME.renderMultipliers = renderMultipliers;

  // Collision handler that awards payouts when a ball hits a sensor (column)
  function onCollision(event) {
    const pairs = event.pairs || [];
    pairs.forEach(pair => {
      const bodies = [pair.bodyA, pair.bodyB];
      const sensor = bodies.find(b => b.label === 'plinkoSensor' && b.isSensor);
      const ball = bodies.find(b => b.label === 'plinkoBall');

      if (sensor && ball && !ball._collected) {
        ball._collected = true; // ensure we only collect once

        const bet = parseFloat(ball.betValue) || 0;
        const multiplier = parseFloat(sensor.multiplier) || 0;
        const payout = bet * multiplier;

        if (payout !== 0) {
          PLINKO_GAME.balance += payout;
          updateUI();
          showFloatingText(`+£${payout.toFixed(2)}`, sensor.position, true);
        } else {
          showFloatingText(`£0`, sensor.position, false);
        }

        // Remove the ball from the physics world so it no longer accumulates
        try {
          World.remove(world, ball);
        } catch (err) {
          // ignore if removal fails for any reason
        }
      }
    });
  }

  // small helper to show floating text near the bin
  function showFloatingText(text, position, positive) {
    const canvas = document.querySelector('#plinko-canvas canvas');
    if (!canvas) return;
    const rect = canvas.getBoundingClientRect();

    const x = (position.x / PLINKO_CONFIG.windowWidth) * rect.width;
    const y = (position.y / PLINKO_CONFIG.windowHeight) * rect.height - 10;

    const el = document.createElement('div');
    el.textContent = text;
    el.style.cssText = `position:absolute; left:${x}px; top:${y}px; transform:translate(-50%,-100%); background:${positive ? '#e6ffed' : '#f5f5f5'}; color:${positive ? '#1b7f3a' : '#444'}; padding:6px 8px; border-radius:6px; font-weight:700; z-index:10000; box-shadow:0 2px 10px rgba(0,0,0,0.12);`;

    const canvasContainer = document.getElementById('plinko-canvas');
    if (canvasContainer) canvasContainer.appendChild(el);
    setTimeout(() => el.remove(), 1400);
  }

  // Expose a small API in case other code wants it
  PLINKO_GAME.setBet = function (value) { PLINKO_GAME.currentBet = value; betInput.value = value; };

  // initial UI render
  updateUI();
})();