let blockCount = 0;
let blocksPerClick = 1.0;

const upgrades = {
  villager: {
    owned: 0,
    costBase: 10,
    cost: 10,
    baseEffect: 0.5, // base block/click per villager
  },
  house: {
    owned: 0,
    costVillagers: 5,
  },
  village: {
    owned: 0,
    costHouses: 10,
    effectPerVillager: 10,
  },
};

const passives = {
  WoodenPickaxe: {
    owned: 0,
    costBase: 10,
    cost: 10,
    baseEffect: 1,
  }
}

function formatNumber(number) {
  return new Intl.NumberFormat('en', {
    notation: 'compact',
    compactDisplay: 'short',
    maximumFractionDigits: 1,
  }).format(number);
}


function calculateVillagerCost() {
  let baseCost = upgrades.villager.costBase * Math.pow(1.15, upgrades.villager.owned);
  let houseDiscount = Math.min(upgrades.house.owned * 0.05, 0.5);
  return Math.ceil(baseCost * (1 - houseDiscount));
}

function calculatePickaxePrice(pickaxe) {
  if (pickaxe === "Wooden") {
    let baseCost = passives.WoodenPickaxe.costBase * Math.pow(1.05, passives.WoodenPickaxe.owned);
    return Math.ceil(baseCost);
  }
}


function recalcBlocksPerClick() {
  const villagerCount = upgrades.villager.owned;
  const houseCount = upgrades.house.owned;
  const villageCount = upgrades.village.owned;

  let villagerEffect = upgrades.villager.baseEffect;
  villagerEffect += houseCount * 0.5;
  villagerEffect += villageCount * upgrades.village.effectPerVillager;

  blocksPerClick = 1 + villagerCount * villagerEffect;
}

function updateDisplay() {
  document.getElementById('blockCount').textContent = `Blocks: ${formatNumber(blockCount)}`;
  
  const villagerEffect = 0.5 * (1 + upgrades.house.owned) + (upgrades.village.owned * 5);
  document.getElementById('VillagerGive').innerText = `+${formatNumber(villagerEffect.toFixed(2))} base block/click`;

  document.getElementById('villagerOwned').textContent = formatNumber(upgrades.villager.owned);
  document.getElementById('villagerCost').textContent = formatNumber(upgrades.villager.cost);
  document.getElementById('houseOwned').textContent = formatNumber(upgrades.house.owned);
  document.getElementById('villageOwned').textContent = formatNumber(upgrades.village.owned);
  document.getElementById('blocksPerClickDisplay').textContent = `Blocks per click: ${blocksPerClick.toFixed(2)}`;
}


function updatePickaxeDisplay() {
  document.getElementById('woodenPickaxeOwned').textContent = formatNumber(passives.WoodenPickaxe.owned);
  document.getElementById('woodenPickaxeCost').textContent = formatNumber(passives.WoodenPickaxe.cost);
  document.getElementById('PassiveIncomeDisplay').textContent = "Passive Income: " + formatNumber(passives.WoodenPickaxe.owned * passives.WoodenPickaxe.baseEffect);
}



function handleClick() {
  blockCount += blocksPerClick;
  updateDisplay();
}

function showNotification(text, color = '#4caf50', duration = 3000) {
  const container = document.getElementById('notification-container');
  const notif = document.createElement('div');
  notif.classList.add('notification');
  notif.style.backgroundColor = color;
  notif.textContent = text;
  container.appendChild(notif);

  setTimeout(() => {
    notif.style.transition = 'opacity 0.5s ease';
    notif.style.opacity = '0';
  }, duration);

  setTimeout(() => {
    notif.remove();
  }, duration + 500);
}

function buyUpgrade(key, quantity = 1, event) {
  event.stopPropagation();
  if (key === 'villager') {  // Villager Upgade Level 1
    if (quantity === 'max') {
      let affordable = 0;
      while (blockCount >= upgrades.villager.cost) {
        blockCount -= upgrades.villager.cost;
        upgrades.villager.owned++;
        upgrades.villager.cost = calculateVillagerCost();
        affordable++;
      }
      if (affordable > 0) {
        recalcBlocksPerClick();
        updateDisplay();
        showNotification(`Bought ${affordable} villagers!`, "#4caf50", 3000);
      } else {
        showNotification("Not enough blocks!", "#b33939", 3000);
      }
    } else {
      if (blockCount >= upgrades.villager.cost) {
        blockCount -= upgrades.villager.cost;
        upgrades.villager.owned++;
        upgrades.villager.cost = calculateVillagerCost();
        recalcBlocksPerClick();
        updateDisplay();
        showNotification("Bought 1 villager!", "#4caf50", 3000);
      } else {
        showNotification("Not enough blocks!", "#b33939", 3000);
      }
    }
  } else if (key === 'house') {  // House Upgade Level 1
    if (quantity === 'max') {
      let maxAffordable = Math.floor(upgrades.villager.owned / upgrades.house.costVillagers);
      if (maxAffordable < 1) {
        showNotification("Not enough villagers!", "#b33939", 3000);
        return;
      }

      upgrades.villager.owned -= maxAffordable * upgrades.house.costVillagers;
      upgrades.house.owned += maxAffordable;
      upgrades.villager.cost = calculateVillagerCost();
      recalcBlocksPerClick();
      updateDisplay();
      showNotification(`Bought ${maxAffordable} houses!`, "#4caf50", 3000);
    } else {
      if (upgrades.villager.owned >= upgrades.house.costVillagers) {
        upgrades.villager.owned -= upgrades.house.costVillagers;
        upgrades.house.owned++;
        upgrades.villager.cost = calculateVillagerCost();
        recalcBlocksPerClick();
        updateDisplay();
        showNotification("Bought 1 house!", "#4caf50", 3000);
      } else {
        showNotification("Not enough villagers!", "#b33939", 3000);
      }
    }
  } else if (key === 'village') {
    if (quantity === 'max') {
      // Max villages based on houses (10 houses per village)
      let maxAffordable = Math.floor(upgrades.house.owned / upgrades.village.costHouses);
      if (maxAffordable < 1) {
        showNotification("Not enough houses!", "#b33939", 3000);
        return;
      }

      upgrades.house.owned -= maxAffordable * upgrades.village.costHouses;
      upgrades.village.owned += maxAffordable;
      recalcBlocksPerClick();
      updateDisplay();
      showNotification(`Bought ${maxAffordable} villages!`, "#4caf50", 3000);
    } else {
      if (upgrades.house.owned >= upgrades.village.costHouses) {
        upgrades.house.owned -= upgrades.village.costHouses;
        upgrades.village.owned++;
        recalcBlocksPerClick();
        updateDisplay();
        showNotification("Bought 1 village!", "#4caf50", 3000);
      } else {
        showNotification("Not enough houses!", "#b33939", 3000);
      }
    }
  } else if (key === 'WoodenPickaxe') {
    if (quantity === 'max') {
      let affordable = 0;
      while (blockCount >= passives.WoodenPickaxe.cost) {
        blockCount -= passives.WoodenPickaxe.cost;
        passives.WoodenPickaxe.owned++;
        passives.WoodenPickaxe.cost = calculatePickaxePrice("Wooden");
        affordable++;
      }
      if (affordable > 0) {
        recalcBlocksPerClick();
        updateDisplay();
        updatePickaxeDisplay();
        showNotification(`Bought ${affordable} Wooden Pickaxe(s)!`, "#4caf50", 3000);
      } else {
        showNotification("Not enough Blocks!", "#b33939", 3000);
      }
    } else {
      if (blockCount >= passives.WoodenPickaxe.cost) {
        blockCount -= passives.WoodenPickaxe.cost;
        passives.WoodenPickaxe.owned++;
        passives.WoodenPickaxe.cost = calculatePickaxePrice("Wooden");
        recalcBlocksPerClick();
        updateDisplay();
        updatePickaxeDisplay();
        showNotification("Bought 1 Wooden Pickaxe!", "#4caf50", 3000);
      } else {
        showNotification("Not enough Blocks!", "#b33939", 3000);
      }
    }
  }
  
}

function showTab(tabId) {
  document.querySelectorAll('.tab-content').forEach(tc => {
    tc.style.display = 'none';
  });

  document.querySelectorAll('.tab-button').forEach(btn => {
    btn.classList.remove('active');
  });

  const selectedTab = document.getElementById(tabId);
  if (selectedTab) {
    selectedTab.style.display = 'block';
  } else {
    console.warn(`Tab with id '${tabId}' not found.`);
    return;
  }

  document.querySelectorAll('.tab-button').forEach(btn => {
    if (btn.getAttribute('onclick')?.includes(`showTab('${tabId}')`)) {
      btn.classList.add('active');
    }
  });
}

function passiveIncome() {
  // Add blocks based on pickaxe owned * baseEffect (1 block per second each)
  const income = passives.WoodenPickaxe.owned * passives.WoodenPickaxe.baseEffect;
  if (income > 0) {
    blockCount += income;
    updateDisplay();
  }
}


// Initialize display and values on page load
window.onload = () => {
  upgrades.villager.cost = calculateVillagerCost();
  passives.WoodenPickaxe.cost = calculatePickaxePrice("Wooden");
  recalcBlocksPerClick();
  updateDisplay();
  updatePickaxeDisplay();

  // Start passive income loop
  setInterval(passiveIncome, 1000);
};
;
