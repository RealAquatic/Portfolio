const { Engine, Render, Runner, World, Bodies } = Matter;

const engine = Engine.create();
const world = engine.world;

// Create wrapper with canvas area and sidebar for UI (keeps UI outside the rendered world)
let plinkoWrap = document.getElementById('plinko-wrap');
if (!plinkoWrap) {
  plinkoWrap = document.createElement('div');
  plinkoWrap.id = 'plinko-wrap';
  plinkoWrap.style.cssText = 'display:flex; gap:12px; align-items:flex-start; padding:12px; font-family:Arial,Helvetica,sans-serif;';
  document.body.appendChild(plinkoWrap);

  const canvasContainer = document.createElement('div');
  canvasContainer.id = 'plinko-canvas';
  canvasContainer.style.cssText = `width:${PLINKO_CONFIG.windowWidth}px; height:${PLINKO_CONFIG.windowHeight}px; position:relative;`;
  plinkoWrap.appendChild(canvasContainer);

  const sidebar = document.createElement('div');
  sidebar.id = 'plinko-sidebar';
  sidebar.style.cssText = 'width:260px; min-height:50px;';
  plinkoWrap.appendChild(sidebar);

  // small default styles for UI elements; game.js will add more
  const style = document.createElement('style');
  style.textContent = `
    /* Sidebar layout */
    #plinko-sidebar { display:flex; align-items:flex-start; }

    /* Panels and sections */
    #plinko-ui, .plinko-section { width:100%; background:#fff; border:1px solid #e9eef1; padding:12px; border-radius:8px; box-shadow:0 6px 20px rgba(18,25,35,0.06); box-sizing:border-box; }
    .plinko-section { display:flex; flex-direction:column; gap:8px }

    .plinko-heading { font-weight:800; font-size:14px; margin-bottom:6px; color:#111 }

    /* Controls */
    input[type="number"], input[type="range"], select { padding:8px; border:1px solid #e6eef3; border-radius:6px; background:#fff; }

    /* Buttons */
    .btn { cursor:pointer; padding:8px 10px; border-radius:6px; border:1px solid #e6eef8; background:#f8fafc; color:#0f172a; font-weight:600 }
    .btn:hover { filter:brightness(0.98); }
    .btn-primary { background:#2563eb; color:#fff; border-color:transparent }
    .btn-ghost { background:transparent; border-color:#dbeafe; color:#2563eb }

    /* Crash panel */
    .plinko-crash { padding:10px; background:linear-gradient(180deg,#ffffff, #fbfbfe); }
    .plinko-crash .btn { min-width:80px }

    /* Canvas styles */
    #plinko-canvas { background:#fbfdff; border-radius:6px; box-shadow:inset 0 0 0 1px rgba(2,6,23,0.03); }

    /* Multiplier labels */
    #plinko-mult-labels .plinko-label { position:absolute; transform:translate(-50%,-50%); padding:6px 8px; border-radius:6px; font-weight:700; box-shadow:0 2px 8px rgba(0,0,0,0.12); pointer-events:none }
  `;
  document.head.appendChild(style);
}

const render = Render.create({
  element: document.getElementById('plinko-canvas'),
  engine: engine,
  options: {
    width: PLINKO_CONFIG.windowWidth,
    height: PLINKO_CONFIG.windowHeight,
    wireframes: false
  }
});

Render.run(render);
Runner.run(Runner.create(), engine);

// Forward collisions to the game handler if available
Matter.Events.on(engine, 'collisionStart', function(event) {
  if (window.PLINKO_GAME && typeof window.PLINKO_GAME.onCollision === 'function') {
    window.PLINKO_GAME.onCollision(event);
  }
});
