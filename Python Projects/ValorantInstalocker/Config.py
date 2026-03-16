# ================== SETTINGS ==================
SETTINGS = {
    "window": {"width": 500, "height": 850, "title": "Valorant Assistant", "resizable": False},
    "agent_grid": {"columns": 3, "button_size": (120, 120), "padx": 10, "pady": 10},
    "fonts": {"selected_label": ("Segoe UI", 16, "bold"), "notice": ("Segoe UI", 9), "status": ("Segoe UI", 12, "bold")},
    "colors": {
        "bg": "#1a1a2e",
        "secondary_bg": "#16213e",
        "accent": "#0f3460",
        "accent_bright": "#e94560",
        "text_primary": "#ffffff",
        "text_secondary": "#b8b8b8",
        "scrollbar_bg": "#2a2a2a00",
        "scrollbar_trough": "#1a1a1a00",
        "scrollbar_arrow": "white",
        "text_overlay": (0, 0, 0, 120),
        "text": (255, 255, 255, 255),
        "status_enabled": "#00d084",
        "status_disabled": "#e94560",
        "notice": "#ffa500",
        "selection": "#e94560",
        "button_hover": "#e94560",
        "separator": "#0f3460"
    },
    "keybinds": {"instalock": "k", "toggle": "f6"},
    "agent_hotkeys": [
        # {"hotkey": "1", "agent": "Jett"},
        # {"hotkey": "2", "agent": "Reyna"},
        # {"hotkey": "3", "agent": "Raze"},
        # {"hotkey": "4", "agent": "Sage"},
    ]
}

# ================== AGENT ROLES & INDEX ==================
AGENT_ROLES = {
    # Initiators
    "Breach": {"role": "Initiator", "index": 1},
    "Fade": {"role": "Initiator", "index": 2},
    "Gekko": {"role": "Initiator", "index": 3},
    "Kayo": {"role": "Initiator", "index": 4},
    "Skye": {"role": "Initiator", "index": 5},
    "Sova": {"role": "Initiator", "index": 6},
    "Tejo": {"role": "Initiator", "index": 7},
    # Controllers
    "Brimstone": {"role": "Controller", "index": 1},
    "Clove": {"role": "Controller", "index": 2},
    "Harbour": {"role": "Controller", "index": 3},
    "Omen": {"role": "Controller", "index": 4},
    "Viper": {"role": "Controller", "index": 5},
    "Astra": {"role": "Controller", "index": 6},
    # Sentinels
    "Chamber": {"role": "Sentinel", "index": 1},
    "Cypher": {"role": "Sentinel", "index": 2},
    "Deadlock": {"role": "Sentinel", "index": 3},
    "Killjoy": {"role": "Sentinel", "index": 4},
    "Sage": {"role": "Sentinel", "index": 5},
    "Veto": {"role": "Sentinel", "index": 6},
    "Vyse": {"role": "Sentinel", "index": 7},
    # Duelists
    "Iso": {"role": "Duelist", "index": 1},
    "Jett": {"role": "Duelist", "index": 2},
    "Neon": {"role": "Duelist", "index": 3},
    "Pheonix": {"role": "Duelist", "index": 4},
    "Raze": {"role": "Duelist", "index": 5},
    "Reyna": {"role": "Duelist", "index": 6},
    "Waylay": {"role": "Duelist", "index": 7},
    "Yoru": {"role": "Duelist", "index": 8},
}

# Positions in order (index 1 → first coordinate)
POSITIONS = [
    (41, 303, 124, 386),   # 1
    (140, 303, 221, 386),  # 2
    (239, 303, 321, 386),  # 3
    (339, 303, 418, 386),  # 4
    (41, 402, 124, 484),   # 5
    (140, 402, 221, 484),  # 6
    (239, 402, 321, 484),  # 7
    (339, 402, 418, 484),  # 8
    (41, 502, 124, 584),   # 9
    (140, 502, 221, 584),  # 10
    (239, 502, 321, 584),  # 11
    (339, 502, 418, 584),  # 12
    (41, 600, 124, 683),   # 13
    (140, 600, 221, 683),  # 14
    (239, 600, 321, 683),  # 15
    (339, 600, 418, 683),  # 16
    (41, 699, 124, 781),   # 17
    (140, 699, 221, 781),  # 18
    (239, 699, 321, 781),  # 19
    (339, 699, 418, 781),  # 20
]

# Role buttons coordinates in Valorant UI
ROLE_BUTTONS = {
    "Initiator": (125, 220, 181, 278),
    "Duelist": (203, 219, 261, 279),
    "Sentinel": (282, 219, 341, 276),
    "Controller": (363, 221, 422, 277),
}