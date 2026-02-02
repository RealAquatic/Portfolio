const W = PLINKO_CONFIG.windowWidth;
const H = PLINKO_CONFIG.windowHeight;

const wallThickness = 10;
const halfT = wallThickness / 2;

const walls = [
  Bodies.rectangle(W / 2, halfT, W, wallThickness, { isStatic: true }),     // top
  Bodies.rectangle(W / 2, H - halfT, W, wallThickness, { isStatic: true }),   // bottom
  Bodies.rectangle(halfT, H / 2, wallThickness, H, { isStatic: true }),      // left
  Bodies.rectangle(W - halfT, H / 2, wallThickness, H, { isStatic: true })   // right
];

World.add(world, walls);