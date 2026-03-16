import tkinter as Tk
from tkinter import ttk
from PIL import Image, ImageTk, ImageDraw
import keyboard
import pyautogui
import random
import time
import os
import ctypes
import json
from Config import SETTINGS, AGENT_ROLES, POSITIONS, ROLE_BUTTONS


# ================== INSTALOCK CORE ==================
class InstaLocker:
    def __init__(self, agent="Brimstone"):
        self.agent = agent
        self.enabled = True
        self.positions = POSITIONS
        self.lock_button = (805, 718, 1097, 786)
        self.editing_hotkey = False  # Flag to prevent instalock during hotkey editing

    def get_random_position(self, area):
        x1, y1, x2, y2 = area
        return random.randint(x1, x2), random.randint(y1, y2)

    def KeyPress(self):
        if not self.enabled or self.agent not in AGENT_ROLES or self.editing_hotkey:
            return False  # Prevent further processing
        
        # Click role button first
        agent_role = AGENT_ROLES[self.agent]["role"]
        role_coords = ROLE_BUTTONS[agent_role]
        role_x = (role_coords[0] + role_coords[2]) // 2
        role_y = (role_coords[1] + role_coords[3]) // 2
        pyautogui.moveTo(role_x, role_y)
        time.sleep(0.05)
        
        # Then click agent position
        idx = AGENT_ROLES[self.agent]["index"] - 1  # convert 1-based to 0-based
        area = self.positions[idx]
        ax, ay = self.get_random_position(area)
        pyautogui.moveTo(ax, ay)
        time.sleep(0.05)
        
        # Finally click lock button
        lx, ly = self.get_random_position(self.lock_button)
        pyautogui.moveTo(lx, ly)
        time.sleep(0.05)
        
        return False

    def toggle(self):
        self.enabled = not self.enabled
        print(f"Instalock {'ENABLED' if self.enabled else 'DISABLED'}")
    
    def set_agent(self, agent):
        """Switch to a specific agent"""
        if agent in AGENT_ROLES:
            self.agent = agent

# ================== TKINTER UI ==================
class ValorantAssistant:
    def __init__(self, root):
        self.root = root
        ws = SETTINGS["window"]
        root.title(ws["title"])
        root.geometry(f"{ws['width']}x{ws['height']}")
        root.configure(bg=SETTINGS["colors"]["bg"])
        root.resizable(ws["resizable"], ws["resizable"])
        
        self.style = ttk.Style()
        self.style.theme_use("clam")
        self.style.configure("Dark.TFrame", background=SETTINGS["colors"]["bg"])
        self.style.configure(
            "Vertical.TScrollbar",
            background=SETTINGS["colors"]["bg"],
            troughcolor=SETTINGS["colors"]["bg"],
            arrowcolor=SETTINGS["colors"]["bg"],
            width=0
        )

        self.locker = InstaLocker("Brimstone")
        kb = SETTINGS["keybinds"]
        keyboard.add_hotkey(kb["instalock"], self.locker.KeyPress)
        keyboard.add_hotkey(kb["toggle"], self.toggle_ui)

        # Register agent hotkeys
        self.agent_hotkeys = {}  # {hotkey: agent}
        self.load_config()  # Load saved config first
        self.load_agent_hotkeys()

        self.agent_images = {}
        self.role_images = {}
        self.agent_buttons = {}
        self.role_buttons = {}
        self.load_images()
        self.build_ui()

    def get_config_path(self):
        """Get the path to the config file"""
        return os.path.join(os.path.dirname(__file__), "config_save.json")
    
    def save_config(self):
        """Save current config to file"""
        try:
            config_data = {
                "agent_hotkeys": SETTINGS.get("agent_hotkeys", []),
                "selected_agent": self.locker.agent,
                "selected_role": self.current_role if hasattr(self, 'current_role') else "Controller"
            }
            with open(self.get_config_path(), "w") as f:
                json.dump(config_data, f, indent=2)
        except Exception as e:
            print(f"Error saving config: {e}")
    
    def load_config(self):
        """Load config from file"""
        try:
            config_path = self.get_config_path()
            if os.path.exists(config_path):
                with open(config_path, "r") as f:
                    config_data = json.load(f)
                    hotkeys = config_data.get("agent_hotkeys", [])
                    SETTINGS["agent_hotkeys"] = hotkeys
                    
                    # Load saved agent and role
                    saved_agent = config_data.get("selected_agent", "Brimstone")
                    saved_role = config_data.get("selected_role", "Controller")
                    
                    # Temporarily store for later use
                    self.saved_agent = saved_agent if saved_agent in AGENT_ROLES else "Brimstone"
                    self.saved_role = saved_role if saved_role in ["Controller", "Duelist", "Initiator", "Sentinel"] else "Controller"
        except Exception as e:
            print(f"Error loading config: {e}")
            self.saved_agent = "Brimstone"
            self.saved_role = "Controller"

    def load_images(self):
        agent_btn_w, agent_btn_h = 120, 120
        role_btn_w, role_btn_h = 70, 70
        
        # Load agent images
        for agent in AGENT_ROLES.keys():
            path = os.path.join("images", f"{agent}.png")
            if not os.path.exists(path):
                continue
            img = Image.open(path).convert("RGBA").resize((agent_btn_w, agent_btn_h))
            overlay = Image.new("RGBA", (agent_btn_w, 25), SETTINGS["colors"]["text_overlay"])
            img.paste(overlay, (0, agent_btn_h - 25), overlay)
            draw = ImageDraw.Draw(img)
            draw.text((8, agent_btn_h - 23), agent, fill=SETTINGS["colors"]["text"], font=None)
            self.agent_images[agent] = ImageTk.PhotoImage(img)
        
        # Load role images
        roles = ["Controller", "Duelist", "Initiator", "Sentinel"]
        for role in roles:
            path = os.path.join("images", f"{role}.png")
            if os.path.exists(path):
                img = Image.open(path).convert("RGBA").resize((role_btn_w, role_btn_h))
                self.role_images[role] = ImageTk.PhotoImage(img)
            else:
                # Create placeholder if image doesn't exist
                img = Image.new("RGBA", (role_btn_w, role_btn_h), (50, 50, 50, 255))
                draw = ImageDraw.Draw(img)
                draw.text((20, 40), role[:3].upper(), fill=(255, 255, 255, 255))
                self.role_images[role] = ImageTk.PhotoImage(img)

    def load_agent_hotkeys(self):
        """Load agent hotkeys from config and register them"""
        hotkeys = SETTINGS.get("agent_hotkeys", [])
        for hotkey_config in hotkeys:
            hotkey = hotkey_config.get("hotkey")
            agent = hotkey_config.get("agent")
            if hotkey and agent and agent in AGENT_ROLES:
                self.agent_hotkeys[hotkey] = agent
                # Register the hotkey
                keyboard.add_hotkey(hotkey, lambda a=agent: self.switch_agent_from_hotkey(a))
    
    def switch_agent_from_hotkey(self, agent):
        """Switch to agent when hotkey is pressed"""
        if not self.locker.editing_hotkey:
            self.locker.set_agent(agent)
            # Update UI if window is still open
            if hasattr(self, 'selected_label'):
                self.selected_label.config(text=f"Currently selecting {agent}")
                self.preview.config(image=self.agent_images.get(agent))
                self.highlight_selected_agent(agent)
            
            # If instalock is enabled, perform the lock
            if self.locker.enabled:
                time.sleep(0.1)  # Brief delay to ensure agent is set
                self.locker.KeyPress()

    def build_ui(self):
        colors = SETTINGS["colors"]
        fonts = SETTINGS["fonts"]

        # Title and preview section
        title_frame = Tk.Frame(self.root, bg=colors["bg"])
        title_frame.pack(pady=15)

        self.selected_label = Tk.Label(title_frame, text="Currently selecting Brimstone",
                                       font=(fonts["selected_label"][0], fonts["selected_label"][1], fonts["selected_label"][2]),
                                       bg=colors["bg"], fg=colors["text_primary"])
        self.selected_label.pack()

        # Preview with border
        preview_frame = Tk.Frame(self.root, bg=colors["selection"], width=130, height=130, highlightthickness=2, highlightbackground=colors["accent_bright"])
        preview_frame.pack(pady=10, padx=10)
        self.preview = Tk.Label(preview_frame, image=self.agent_images.get("Brimstone"), bg=colors["bg"], bd=0)
        self.preview.pack(padx=4, pady=4)

        # Status and notice section
        info_frame = Tk.Frame(self.root, bg=colors["bg"])
        info_frame.pack(pady=10)

        self.status_label = Tk.Label(info_frame, text="Status: ENABLED",
                                     fg=colors["status_enabled"], bg=colors["bg"],
                                     font=(fonts["status"][0], fonts["status"][1], fonts["status"][2]))
        self.status_label.pack()

        notice = Tk.Label(info_frame, text="K = Instalock  |  F6 = Toggle",
                          fg=colors["text_secondary"], bg=colors["bg"], font=(fonts["notice"][0], fonts["notice"][1]))
        notice.pack(pady=3)

        warning = Tk.Label(info_frame, text="Manually spam click - Dont move your mouse!",
                          fg=colors["notice"], bg=colors["bg"], font=(fonts["notice"][0], fonts["notice"][1]))
        warning.pack(pady=2)

        # Separator
        sep = Tk.Frame(self.root, bg=colors["separator"], height=2)
        sep.pack(fill="x", padx=15, pady=8)

        # Role buttons frame with better styling
        role_frame = Tk.Frame(self.root, bg=colors["bg"])
        role_frame.pack(pady=15)
        
        role_label = Tk.Label(role_frame, text="Select Role", font=("Segoe UI", 11, "bold"),
                              bg=colors["bg"], fg=colors["text_primary"])
        role_label.pack(pady=(0, 10))

        buttons_frame = Tk.Frame(role_frame, bg=colors["bg"])
        buttons_frame.pack()

        for role in ["Controller", "Duelist", "Initiator", "Sentinel"]:
            img = self.role_images.get(role)
            if img:
                btn = Tk.Button(buttons_frame, image=img, command=lambda r=role: self.select_role(r),
                                relief="raised", bd=0, bg=colors["accent"], activebackground=colors["selection"],
                                highlightthickness=0, cursor="hand2", padx=2, pady=2)
                btn.grid(row=0, column=["Controller", "Duelist", "Initiator", "Sentinel"].index(role), padx=8, pady=6)
                self.role_buttons[role] = btn

        # Separator
        sep2 = Tk.Frame(self.root, bg=colors["separator"], height=2)
        sep2.pack(fill="x", padx=15, pady=8)

        # Agent Hotkeys section
        hotkeys_label = Tk.Label(self.root, text="Agent Hotkeys", font=("Segoe UI", 11, "bold"),
                                 bg=colors["bg"], fg=colors["text_primary"])
        hotkeys_label.pack(pady=(10, 8))

        self.hotkeys_frame = Tk.Frame(self.root, bg=colors["bg"])
        self.hotkeys_frame.pack(padx=8, pady=5, fill="x")

        self.hotkey_widgets = []  # Store widgets for each hotkey
        self.load_hotkey_ui()

        # Add hotkey button
        add_hotkey_btn = Tk.Button(self.root, text="+ Add Hotkey", command=self.add_new_hotkey,
                                   relief="raised", bd=0, bg=colors["selection"], fg=colors["text_primary"],
                                   font=("Segoe UI", 10, "bold"), cursor="hand2", activebackground=colors["accent_bright"],
                                   padx=20, pady=6, highlightthickness=0)
        add_hotkey_btn.pack(pady=8)

        # Separator
        sep3 = Tk.Frame(self.root, bg=colors["separator"], height=2)
        sep3.pack(fill="x", padx=15, pady=8)

        # Scrollable canvas for agents
        canvas_label = Tk.Label(self.root, text="Select Agent", font=("Segoe UI", 11, "bold"),
                                bg=colors["bg"], fg=colors["text_primary"])
        canvas_label.pack(pady=(10, 5))

        self.canvas = Tk.Canvas(self.root, bg=colors["bg"], highlightthickness=0, height=280)
        self.scrollbar = ttk.Scrollbar(self.root, orient="vertical", command=self.canvas.yview)
        self.scroll_frame = ttk.Frame(self.canvas, style="Dark.TFrame")
        self.scroll_frame.bind("<Configure>", lambda e: self.canvas.configure(scrollregion=self.canvas.bbox("all")))
        self.canvas.create_window((0, 0), window=self.scroll_frame, anchor="nw")
        self.canvas.configure(yscrollcommand=self.scrollbar.set)
        self.canvas.pack(side="left", fill="both", expand=True, padx=5, pady=5)
        self.canvas.bind_all("<MouseWheel>", self._on_mousewheel)

        self.current_role = self.saved_role if hasattr(self, 'saved_role') else "Controller"
        saved_agent = self.saved_agent if hasattr(self, 'saved_agent') else "Brimstone"
        self.locker.agent = saved_agent
        
        self.update_agent_grid(self.current_role)
        self.highlight_selected_role(self.current_role)
        self.highlight_selected_agent(saved_agent)
        
        # Update preview and label with saved agent
        self.selected_label.config(text=f"Currently selecting {saved_agent}")
        self.preview.config(image=self.agent_images.get(saved_agent))

    def _on_mousewheel(self, event):
        self.canvas.yview_scroll(int(-1*(event.delta/120)), "units")

    def get_grouped_agents(self, filter_role="All"):
        grouped = {"Controller": [], "Duelist": [], "Initiator": [], "Sentinel": []}
        for agent in self.agent_images:
            role = AGENT_ROLES[agent]["role"]
            if filter_role != "All" and role != filter_role:
                continue
            grouped[role].append(agent)
        for role in grouped:
            grouped[role].sort(key=lambda x: AGENT_ROLES[x]["index"])
        ordered_roles = ["Controller", "Duelist", "Initiator", "Sentinel"]
        ordered_agents = []
        for role in ordered_roles:
            ordered_agents.extend(grouped[role])
        return ordered_agents

    def update_agent_grid(self, role):
        for btn in self.agent_buttons.values():
            btn.destroy()
        self.agent_buttons.clear()

        agents_for_role = [agent for agent in self.agent_images if AGENT_ROLES[agent]["role"] == role]

        cols = 3
        padx = 10
        pady = 10
        row = col = 0

        for agent in agents_for_role:
            img = self.agent_images[agent]
            btn = Tk.Button(self.scroll_frame, image=img, command=lambda a=agent: self.select_agent(a),
                            relief="flat", bd=0, bg=SETTINGS["colors"]["accent"], activebackground=SETTINGS["colors"]["button_hover"],
                            highlightthickness=0, cursor="hand2")
            btn.grid(row=row, column=col, padx=padx, pady=pady, sticky="nsew")
            self.agent_buttons[agent] = btn
            col += 1
            if col >= cols:
                col = 0
                row += 1

        if self.locker.agent in self.agent_buttons:
            self.highlight_selected_agent(self.locker.agent)

    def update_grid(self, event=None):
        selected_role = self.role_var.get()
        agents_to_show = self.get_grouped_agents(selected_role)

        cols = SETTINGS["agent_grid"]["columns"]
        padx = SETTINGS["agent_grid"]["padx"]
        pady = SETTINGS["agent_grid"]["pady"]
        row = col = 0

        for agent in agents_to_show:
            img = self.agent_images[agent]
            btn = Tk.Button(self.scroll_frame, image=img, command=lambda a=agent: self.select_agent(a),
                            relief="flat", bd=2, bg=SETTINGS["colors"]["bg"], activebackground=SETTINGS["colors"]["bg"])
            btn.grid(row=row, column=col, padx=padx, pady=pady, sticky="nsew")
            self.agent_buttons[agent] = btn
            col += 1
            if col >= cols:
                col = 0
                row += 1

        if self.locker.agent in self.agent_buttons:
            self.highlight_selected(self.locker.agent)

    def select_agent(self, agent):
        self.locker.agent = agent
        self.selected_label.config(text=f"Currently selecting {agent}")
        self.preview.config(image=self.agent_images[agent])
        self.highlight_selected_agent(agent)
        self.save_config()  # Save when agent is selected

    def select_role(self, role):
        self.current_role = role
        self.update_agent_grid(role)
        self.highlight_selected_role(role)
        self.save_config()  # Save when role is selected

    def highlight_selected_agent(self, agent):
        selection_color = SETTINGS["colors"]["selection"]
        for btn in self.agent_buttons.values():
            btn.config(relief="flat", bd=0, bg=SETTINGS["colors"]["accent"])
        if agent in self.agent_buttons:
            self.agent_buttons[agent].config(relief="flat", bd=2, bg=selection_color, highlightthickness=0)

    def highlight_selected(self, agent):
        selection_color = SETTINGS["colors"]["selection"]
        for btn in self.agent_buttons.values():
            btn.config(relief="flat", bd=2, highlightthickness=0)
        if agent in self.agent_buttons:
            self.agent_buttons[agent].config(relief="solid", bd=2,
                                             highlightbackground=selection_color,
                                             highlightcolor=selection_color, highlightthickness=2)

    def highlight_selected_role(self, role):
        selection_color = SETTINGS["colors"]["selection"]
        for btn in self.role_buttons.values():
            btn.config(relief="flat", bd=0, bg=SETTINGS["colors"]["accent"])
        if role in self.role_buttons:
            self.role_buttons[role].config(relief="flat", bd=2, bg=selection_color, highlightthickness=0)

    def load_hotkey_ui(self):
        """Load and display all configured hotkeys"""
        # Clear all widgets from hotkeys frame
        for widget in self.hotkeys_frame.winfo_children():
            widget.destroy()
        self.hotkey_widgets.clear()

        # Display each hotkey
        hotkeys = SETTINGS.get("agent_hotkeys", [])
        for idx, hotkey_config in enumerate(hotkeys):
            if idx >= 4:  # Max 4 hotkeys
                break
            self.create_hotkey_entry(idx, hotkey_config.get("hotkey", ""), hotkey_config.get("agent", ""))

    def create_hotkey_entry(self, idx, hotkey="", agent=""):
        """Create a single hotkey entry widget"""
        colors = SETTINGS["colors"]
        
        entry_frame = Tk.Frame(self.hotkeys_frame, bg=colors["bg"], relief="flat", bd=0, highlightthickness=0)
        entry_frame.pack(fill="x", pady=2, padx=0)

        # Hotkey display
        hotkey_label = Tk.Label(entry_frame, text=hotkey if hotkey else "[Set]", 
                               bg=colors["secondary_bg"], fg=colors["text_primary"], width=5, font=("Segoe UI", 8, "bold"),
                               relief="flat", bd=0)
        hotkey_label.pack(side="left", padx=3, pady=3)

        # Agent selection
        agent_var = Tk.StringVar(value=agent)
        agent_dropdown = ttk.Combobox(entry_frame, textvariable=agent_var, 
                                     values=list(AGENT_ROLES.keys()), state="readonly",
                                     width=12, font=("Segoe UI", 8))
        agent_dropdown.pack(side="left", padx=2, pady=3, fill="x", expand=True)

        # Edit hotkey button
        def edit_hotkey():
            self.locker.editing_hotkey = True
            hotkey_label.config(text="Key?", bg=colors["accent_bright"], fg=colors["text_primary"])
            self.root.update()
            
            # Listen for key press
            try:
                event = keyboard.read_event()
                new_hotkey = event.name
                
                # Validate hotkey
                if new_hotkey == SETTINGS["keybinds"]["instalock"]:
                    hotkey_label.config(text="Bad", bg=colors["accent_bright"])
                    self.locker.editing_hotkey = False
                    current_text = hotkey if hotkey else "[Set]"
                    self.root.after(1500, lambda h=current_text: hotkey_label.config(text=h, bg=colors["secondary_bg"]))
                    return
                
                # Update hotkey label
                hotkey_label.config(text=new_hotkey, bg=colors["secondary_bg"])
                # Save to config with current agent value
                current_agent = agent_var.get()
                self.save_hotkey_to_config(idx, new_hotkey, current_agent)
            except Exception as e:
                hotkey_label.config(text="Err", bg=colors["accent_bright"])
                current_text = hotkey if hotkey else "[Set]"
                self.root.after(1500, lambda h=current_text: hotkey_label.config(text=h, bg=colors["secondary_bg"]))
            finally:
                self.locker.editing_hotkey = False

        edit_btn = Tk.Button(entry_frame, text="Edit", command=edit_hotkey,
                            relief="flat", bd=0, bg=colors["accent_bright"], fg=colors["text_primary"],
                            font=("Segoe UI", 7, "bold"), cursor="hand2", width=4, activebackground=colors["selection"],
                            highlightthickness=0, padx=2, pady=1)
        edit_btn.pack(side="left", padx=1, pady=3)

        # Agent change handler
        def on_agent_change(event=None):
            new_agent = agent_var.get()
            # Get current hotkey from label
            current_hotkey_text = hotkey_label.cget("text")
            if current_hotkey_text and current_hotkey_text not in ["[Set]", "Bad", "Err", "Key?"]:
                self.save_hotkey_to_config(idx, current_hotkey_text, new_agent)

        agent_dropdown.bind("<<ComboboxSelected>>", on_agent_change)

        # Delete button
        def delete_hotkey():
            self.delete_hotkey_from_config(idx)
            self.load_hotkey_ui()

        delete_btn = Tk.Button(entry_frame, text="✕", command=delete_hotkey,
                              relief="flat", bd=0, bg=colors["accent_bright"], fg=colors["text_primary"],
                              font=("Segoe UI", 8, "bold"), cursor="hand2", width=2, activebackground="#ff6b7a",
                              highlightthickness=0, padx=1, pady=1)
        delete_btn.pack(side="right", padx=3, pady=3)

        # Store reference to widgets for later cleanup
        self.hotkey_widgets.append([entry_frame, hotkey_label, agent_dropdown, edit_btn, delete_btn])

    def add_new_hotkey(self):
        """Add a new hotkey slot (up to 4 max)"""
        hotkeys = SETTINGS.get("agent_hotkeys", [])
        if len(hotkeys) < 4:
            hotkeys.append({"hotkey": "", "agent": ""})
            SETTINGS["agent_hotkeys"] = hotkeys
            self.save_config()  # Save to file
            self.load_hotkey_ui()

    def save_hotkey_to_config(self, idx, hotkey, agent):
        """Save or update a hotkey in the config"""
        hotkeys = SETTINGS.get("agent_hotkeys", [])
        if idx < len(hotkeys):
            hotkeys[idx]["hotkey"] = hotkey
            hotkeys[idx]["agent"] = agent
            SETTINGS["agent_hotkeys"] = hotkeys
            self.save_config()  # Save to file
            
            # Re-register the hotkey
            self.reload_hotkeys()

    def delete_hotkey_from_config(self, idx):
        """Delete a hotkey from config"""
        hotkeys = SETTINGS.get("agent_hotkeys", [])
        if idx < len(hotkeys):
            del hotkeys[idx]
            SETTINGS["agent_hotkeys"] = hotkeys
            self.save_config()  # Save to file
            self.reload_hotkeys()

    def reload_hotkeys(self):
        """Reload all hotkeys after configuration changes"""
        # Remove old hotkeys
        old_hotkeys = self.agent_hotkeys.copy()
        for hotkey in old_hotkeys:
            try:
                keyboard.remove_hotkey(hotkey)
            except:
                pass
        
        self.agent_hotkeys.clear()
        self.load_agent_hotkeys()

    def toggle_ui(self):
        self.locker.toggle()
        if self.locker.enabled:
            self.status_label.config(text="Status: ENABLED", fg=SETTINGS["colors"]["status_enabled"])
        else:
            self.status_label.config(text="Status: DISABLED", fg=SETTINGS["colors"]["status_disabled"])
if __name__ == "__main__":
    root = Tk.Tk()

    icon_path = os.path.abspath(os.path.join("images", "Logo.ico"))
    if os.path.exists(icon_path):
        try:
            root.iconbitmap(icon_path)
            try:
                ctypes.windll.shell32.SetCurrentProcessExplicitAppUserModelID("ValorantInstalocker")
            except:
                pass
        except:
            pass

    app = ValorantAssistant(root)
    root.mainloop()