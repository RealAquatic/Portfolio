function dropBall(amount) {
  const spawnOffset = PLINKO_CONFIG.spawnOffset || 5;
  const centerX = PLINKO_CONFIG.windowWidth / 2;
  const x = (centerX - spawnOffset) + Math.floor(Math.random() * (2 * spawnOffset));

  const ball = Bodies.circle(x, PLINKO_CONFIG.spawnY, PLINKO_CONFIG.ballRadius || 8, {
    restitution: 0.5,
    render: { fillStyle: "red" },
    collisionFilter: { group: 1 } // negative group: balls won't collide with each other
  });

  ball.label = 'plinkoBall';
  ball.betValue = amount || (window.PLINKO_GAME && PLINKO_GAME.currentBet) || PLINKO_CONFIG.defaultBet;

  World.add(world, ball);
}

// Drop on click (only when clicking on the board, not the sidebar UI)
document.addEventListener('click', function (e) {
  if (e.target && e.target.closest && e.target.closest('#plinko-sidebar')) return; // click on sidebar controls
  if (!e.target || !e.target.closest || !e.target.closest('#plinko-canvas')) return; // only clicks inside the canvas area

  const bet = (window.PLINKO_GAME && PLINKO_GAME.currentBet) || PLINKO_CONFIG.defaultBet;
  if (window.PLINKO_GAME && PLINKO_GAME.balance < bet) {
    // flash balance to indicate not enough funds
    const el = document.getElementById('plinko-balance');
    if (el) {
      el.style.transition = 'color 0.15s';
      el.style.color = 'red';
      setTimeout(() => { el.style.color = ''; }, 300);
    }
    return;
  }

  if (window.PLINKO_GAME) {
    PLINKO_GAME.balance -= bet;
    PLINKO_GAME.updateUI();
  }

  dropBall(bet);
});

// Auto-drop control (start/stop functions)
let __plinkoAutoDropId = null;
window.__plinkoStartAutoDrop = function (intervalMs) {
  window.__plinkoStopAutoDrop();
  const ms = Math.max(50, Math.round(intervalMs || PLINKO_CONFIG.dropIntervalMs || PLINKO_CONFIG.defaultAutoDropInterval || 500));
  __plinkoAutoDropId = setInterval(function () {
    const bet = (window.PLINKO_GAME && PLINKO_GAME.currentBet) || PLINKO_CONFIG.defaultBet;
    if (window.PLINKO_GAME && PLINKO_GAME.balance >= bet) {
      PLINKO_GAME.balance -= bet;
      PLINKO_GAME.updateUI();
      dropBall(bet);
    }
  }, ms);
  PLINKO_CONFIG.autoDrop = true;
  PLINKO_CONFIG.dropIntervalMs = ms;
};
window.__plinkoStopAutoDrop = function () {
  if (__plinkoAutoDropId) {
    clearInterval(__plinkoAutoDropId);
    __plinkoAutoDropId = null;
  }
  PLINKO_CONFIG.autoDrop = false;
};

// Start automatically if config requests it
if (PLINKO_CONFIG.autoDrop) {
  window.__plinkoStartAutoDrop(PLINKO_CONFIG.dropIntervalMs || PLINKO_CONFIG.defaultAutoDropInterval || 500);
}