# foyer.nvim 

`foyer.nvim` is a modern, high-performance entrance screen for Neovim. Unlike traditional dashboards that render components sequentially top-to-bottom, `foyer.nvim` utilizes a 2D memory canvas compositor to blend distinct text, logo, and background layers with true character-level transparency.

## ⚡ Features
* **4-Layer Matrix Compositor:** Independent processing for background, header, menu, and footer layers.
* **True Character Transparency:** Background components (like custom starfields) seamlessly peek through empty spacing in foreground elements.
* **Flawless Resizing:** Instant layout grid recalculations on terminal resize without window clipping or race conditions.
* **Isolated Interactivity:** Robust cursor-locking mechanics that restrict navigation strictly to active menu lines.
* **Three Background Modes:** Static file (centered .txt), procedural generation (theme-based), or blank.
* **Pluggable Generators:** Drop-in Lua modules under `lua/foyer/generators/` for custom background themes.
* **Configurable Zone Layout:** Each layer has a dedicated screen area defined as a percentage, with independent row/col alignment (`"top"`/`"center"`/`"bottom"`, `"left"`/`"center"`/`"right"`).
* **Precise Screen Sizing:** Accurately calculates usable terminal dimensions, accounting for `cmdheight`, statusline, and tabline.

---

## 📦 Installation & Setup

### Option A: Integration with LazyVim
To replace the default dashboard in LazyVim, disable the `snacks.nvim` dashboard module and load `foyer.nvim` early in your plugin startup.

Create `lua/plugins/dashboard.lua` and add:

```lua
return {
  -- 1. Disable the default Snacks dashboard module
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = { enabled = false },
    },
  },

  -- 2. Load and configure foyer.nvim
  {
    "kevanoullio/foyer.nvim",
    lazy = false, -- Load immediately on startup
    priority = 1000, -- Initialize before other plugins
    dependencies = { "nvim-tree/nvim-web-devicons" }, -- Optional: for menu icons
    config = function()
      require("foyer").setup({
        -- Your custom setup configuration parameters
      })
    end,
  },
}

```

### Option B: Standalone Neovim (No Distro)

If you manage your configuration from scratch using a plugin manager like `lazy.nvim`, declare the plugin and ensure it is set to initialize on startup.

Add this entry to your plugin specifications:

```lua
require("lazy").setup({
  {
    "kevanoullio/foyer.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("foyer").setup({
        -- Your custom setup configuration parameters
      })
    end,
  },
})

```

---

## ⚙️ Configuration

All options are passed to `require("foyer").setup({ ... })`.

```lua
require("foyer").setup({
  background = {
    -- "file"      Load a static .txt file, centered on screen.
    --               Falls back to "blank" if path is missing or unreadable.
    -- "generated" Procedurally generated art from a built-in theme.
    -- "blank"     No background (default).
    type = "blank",

    -- Path to a .txt file (only for type = "file").
    path = nil,

    -- Theme name (only for type = "generated").
    -- Available: "stars", "waves"
    theme = "stars",

    -- Highlight group applied to every background cell.
    hl = "Comment",

    -- Position of content within the allocated zone.
    position = {
      row = "center",  -- "top" | "center" | "bottom"
      col = "center",  -- "left" | "center" | "right"
    },

    -- Zone definition: percentage of screen height and spacing.
    zone = {
      percentage = 1.0,  -- 1.0 = full usable screen height
      padding = { top = 0, bot = 0, left = 0, right = 0 },  -- inner spacing
      margin = { top = 0, bot = 0, left = 0, right = 0 },   -- outer spacing
    },
  },

  header = {
    art = {
      " ██╗      █████╗ ███████╗██╗   ██╗██╗   ██╗██╗███╗   ███╗          Z ",
      " ██║     ██╔══██╗╚══███╔╝╚██╗ ██╔╝██║   ██║██║████╗ ████║      Z     ",
      " ██║     ███████║  ███╔╝  ╚████╔╝ ██║   ██║██║██╔████╔██║   z        ",
      " ██║     ██╔══██║ ███╔╝    ╚██╔╝  ╚██╗ ██╔╝██║██║╚██╔╝██║ z          ",
      " ███████╗██║  ██║███████╗   ██║    ╚████╔╝ ██║██║ ╚═╝ ██║            ",
      " ╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝     ╚═══╝  ╚═╝╚═╝     ╚═╝            ",
    },
    hl = "Title",

    -- Position of art within the 25% header zone.
    position = {
      row = "center",  -- "top" | "center" | "bottom"
      col = "center",  -- "left" | "center" | "right"
    },

    -- Header zone: ~25% of screen height.
    zone = {
      percentage = 0.25,
      padding = { top = 2, bot = 2, left = 2, right = 2 },
      margin = { top = 0, bot = 0, left = 0, right = 0 },
    },
  },

  menu = {
    items = {
      { icon = " ", key = "f", desc = "Find File",       action = function() require("foyer").pick("files") end },
      { icon = " ", key = "n", desc = "New File",        action = ":ene | startinsert" },
      { icon = " ", key = "g", desc = "Find Text",       action = function() require("foyer").pick("live_grep") end },
      { icon = " ", key = "r", desc = "Recent Files",    action = function() require("foyer").pick("oldfiles") end },
      { icon = " ", key = "c", desc = "Config",          action = ":e $MYVIMRC" },
      { icon = "󰒲 ", key = "l", desc = "Lazy",            action = ":Lazy" },
      { icon = " ", key = "q", desc = "Quit",            action = ":qa" },
    },

    -- Position of menu items within the 40% menu zone.
    position = {
      row = "center",  -- "top" | "center" | "bottom"
      col = "center",  -- "left" | "center" | "right"
    },

    -- Menu zone: ~40% of screen height (largest = most flexibility).
    zone = {
      percentage = 0.40,
      padding = { top = 2, bot = 2, left = 2, right = 2 },
      margin = { top = 0, bot = 0, left = 0, right = 0 },
    },

    hl_icon = "Special",
    hl_desc = "Normal",
    hl_key = "Keyword",
  },

  footer = {
    text = "Welcome back. Time to build.",
    hl = "Comment",

    -- Position of text within the 10% footer zone.
    position = {
      row = "center",  -- "top" | "center" | "bottom"
      col = "center",  -- "left" | "center" | "right"
    },

    -- Footer zone: ~10% of screen height.
    zone = {
      percentage = 0.10,
      padding = { top = 2, bot = 2, left = 2, right = 2 },
      margin = { top = 0, bot = 0, left = 0, right = 0 },
    },
  },
})
```

### Zone Layout

Each layer is allocated a zone as a percentage of the usable screen height:

| Layer | Default Zone | Description |
|---|---|---|
| `background` | `1.0` (100%) | Full usable screen |
| `header` | `0.25` (25%) | Upper portion for logo/art |
| `menu` | `0.40` (40%) | Largest zone for menu items |
| `footer` | `0.10` (10%) | Bottom portion for status text |

When zone percentages total less than 1.0 (100%), the remaining space is evenly distributed as equal top and bottom **margin** to every zone.

**Padding** (`zone.padding`) is inner spacing — the gap between the zone boundary and where content begins. **Margin** (`zone.margin`) is outer spacing — the gap outside the zone. This follows the same model as CSS.

Each layer also has a `position` object with `row` and `col` options:
- `row`: `"top"`, `"center"`, or `"bottom"` — vertical alignment within the padded zone
- `col`: `"left"`, `"center"`, or `"right"` — horizontal alignment within the padded zone

All layers default to `"center"` for both axes.

---

## 🐛 Debugging

foyer.nvim includes a built-in debug system for diagnosing layout issues such as misaligned content or layers that are not rendering. Inspired by `Snacks.debug`, it provides three levels of visibility.

### Enabling Debug

Set `debug.enabled = true` in your setup options:

```lua
require("foyer").setup({
  debug = {
    enabled = true,
    log_file = "./foyer-debug.log",  -- optional, default is ./foyer-debug.log
  },
})
```

### 1. Visual Zone Overlays

With debug enabled, colored horizontal lines are drawn on the buffer showing each zone's boundaries:

| Color | Layer |
|---|---|
| Red | `header` |
| Green | `menu` |
| Blue | `stats` |
| Magenta | `footer` |

Each boundary line is labeled at the left margin with `name(h=<height>,r=<row>)`. This lets you visually confirm that zones are positioned where you expect relative to your terminal dimensions.

### 2. Debug Log File

Every render writes the computed zones to `./foyer-debug.log` (path configurable via `debug.log_file`). Each entry is timestamped and contains a `vim.inspect` dump of the zone table:

```
2026-01-15 10:30:42  zones {
  header = {
    height = 25,
    row = 1
  },
  menu = {
    height = 40,
    row = 29
  },
  stats = {
    height = 15,
    row = 71
  },
  footer = {
    height = 10,
    row = 88
  }
}
```

This is useful for tracking how zones change across terminal resizes or config edits.

### 3. `:FoyerDebug` Command

Run `:FoyerDebug` to get a notification with a complete layout report:

```
## Foyer Debug
Canvas: 120x40
Total zone pct: 0.90
Debug enabled: true

=== Zone Configs ===
header: pct=0.25 pad={t=2,b=2,l=2,r=2} margin={t=0,b=0,l=0,r=0}
menu:   pct=0.40 pad={t=2,b=2,l=2,r=2} margin={t=0,b=0,l=0,r=0}
stats:  pct=0.15 pad={t=2,b=2,l=2,r=2} margin={t=0,b=0,l=0,r=0}
footer: pct=0.10 pad={t=2,b=2,l=2,r=2} margin={t=0,b=0,l=0,r=0}

=== Computed Zones ===
header: row=1 height=25 (row+height=26)
menu:   row=29 height=40 (row+height=69)
stats:  row=71 height=15 (row+height=86)
footer: row=88 height=10 (row+height=98)

Next after footer: row 98 (canvas height: 98)
```

The command also detects and reports overflow — if the total content extends past the canvas height, a warning is shown:

```
OVERFLOW: content extends 3 lines past canvas
WARNING: footer zone extends 3 lines beyond canvas
```

This helps when your zone percentages + padding push content beyond the available terminal rows.

### Debugging Common Issues

**Header not centered:** Check that `zone.padding.left` is accounted for. The header now uses `pad.left` in its column offset calculation, matching menu/stats/footer.

**Footer not visible:** Run `:FoyerDebug` and check for the overflow warning. If the footer zone extends past `canvas height`, its content is silently clipped by the canvas bounds check. Reduce zone percentages or padding to fix.

**Content offset by a few columns:** Verify `zone.padding.left` values match across layers. A mismatch between the header's centering calculation and other layers causes horizontal drift.

---

## 🛠️ Architecture Overview

The plugin's directory structure isolates presentation logic from data layout computation:

```text
foyer.nvim/
├── lua/
│   └── foyer/
│       ├── init.lua            -- Public API & configuration merging
│       ├── ui.lua              -- Buffer orchestration & resize tracking
│       ├── canvas.lua          -- The core 2D cell blending & rendering engine
│       ├── interactive.lua     -- Focus management & keymap processing
│       ├── loader.lua          -- File I/O utility (reads .txt files)
│       ├── generators/         -- Procedural background themes
│       │   ├── init.lua        -- Theme registry & dispatch
│       │   ├── stars.lua       -- Starfield theme
│       │   └── waves.lua       -- Wave theme
│       ├── layers/             -- Data generators for visual components
│       │   ├── background.lua
│       │   ├── header.lua
│       │   ├── menu.lua
│       │   └── footer.lua
│       └── lib/                -- Shared utilities
│           ├── screen.lua      -- Usable terminal dimension calculation
│           ├── align.lua       -- Row/column alignment helpers
│           └── debug.lua       -- Debug logging & visual zone overlays
```

All layers use the centralized `align` module for consistent horizontal and vertical positioning, and `screen.usable()` for accurate viewport dimensions that account for vim's reserved UI space (statusline, cmdheight, tabline).

When `debug.enabled` is set, `debug.log()` writes timestamped render state to a file and `debug.draw_zones()` overlays colored boundary lines on the buffer for visual layout inspection.

## 📄 License

Distributed under the **MIT License**. See `LICENSE` for more information.
