(function () {
  const pegRows = PLINKO_CONFIG.pegRows;        // number of rows
  const pegSpacing = PLINKO_CONFIG.pegSpacing;     // distance between pegs
  const pegSize = PLINKO_CONFIG.pegSize;           // radius of each peg
  const windowWidth = PLINKO_CONFIG.windowWidth;
  const windowHeight = PLINKO_CONFIG.windowHeight;

  const startingPegs = PLINKO_CONFIG.startingPegs;

  for (let row = 0; row < pegRows; row++) {
    const pegsInRow = row + startingPegs;

    const totalWidth = (pegsInRow - 1) * pegSpacing;

    for (let col = 0; col < pegsInRow; col++) {
      const x = windowWidth / 2 - totalWidth / 2 + col * pegSpacing;

      const y = 100 + row * pegSpacing;

      const peg = Bodies.circle(x, y, pegSize, {
        isStatic: true,
        render: { fillStyle: "#888" }
      });

      World.add(world, peg);
    }
  }
})();