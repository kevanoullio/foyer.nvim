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

To replace the default dashboard in LazyVim, disable the `snacks.nvim` dashboard module and configure `foyer.nvim`.

Create `lua/plugins/dashboard.lua` to disable the default dashboard:

```lua
return {
  "folke/snacks.nvim",
  opts = {
    dashboard = { enabled = false },
  },
}
```

Create `lua/plugins/foyer.lua` to load and configure foyer:

```lua
return {
  "kevanoullio/foyer.nvim",
  lazy = false,
  priority = 1000,
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("foyer").setup({
      -- Your custom options here
    })
  end,
}
```

### Option B: Standalone Neovim (No Distro)

If you manage your configuration from scratch using a plugin manager like `lazy.nvim`, declare the plugin and set it to initialize on startup:

```lua
require("lazy").setup({
  {
    "kevanoullio/foyer.nvim",
    lazy = false,
    priority = 1000,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("foyer").setup({
        -- Your custom options here
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

    position = {
      row = "center",
      col = "center",
    },

    zone = {
      percentage = 0.30,
      padding = { top = 2, bot = 2, left = 2, right = 2 },
      margin = { top = 0, bot = 0, left = 0, right = 0 },
    },
  },

  menu = {
    items = {
      { icon = " ", key = "f", desc = "Find File",       action = function() require("foyer").pick("files") end },
      { icon = " ", key = "n", desc = "New File",        action = ":ene | startinsert" },
      { icon = " ", key = "p", desc = "Projects",        action = function() require("foyer").pick("projects") end },
      { icon = " ", key = "g", desc = "Find Text",       action = function() require("foyer").pick("live_grep") end },
      { icon = " ", key = "r", desc = "Recent Files",    action = function() require("foyer").pick("oldfiles") end },
      { icon = " ", key = "c", desc = "Config",          action = ":e $MYVIMRC" },
      { icon = "󰒲 ", key = "l", desc = "Lazy",            action = ":Lazy" },
      { icon = " ", key = "q", desc = "Quit",            action = ":qa" },
    },

    position = {
      row = "center",
      col = "center",
    },

    zone = {
      percentage = 0.40,
      padding = { top = 2, bot = 2, left = 2, right = 2 },
      margin = { top = 0, bot = 0, left = 0, right = 0 },
    },

    hl_icon = "Special",
    hl_desc = "Normal",
    hl_key = "Keyword",
  },

  stats = {
    show = {
      plugins_loaded = true,
      plugin_load_time = true,
      folders = false,
      files = false,
    },
    depth = 3,
    max_entries = 5000,
    batch_size = 50,
    use_gitignore = true,
    ignore_patterns = {},
    skip_dirs = {
      "node_modules", ".git", ".cache", "__pycache__",
      ".venv", "vendor", ".next", "target", "build", "dist",
    },
    position = {
      row = "center",
      col = "center",
    },
    zone = {
      percentage = 0.15,
      padding = { top = 2, bot = 2, left = 2, right = 2 },
      margin = { top = 0, bot = 0, left = 0, right = 0 },
    },
    hl_text = "Comment",
  },

  footer = {
    text = "Welcome back. Time to build.",
    hl = "Comment",

    position = {
      row = "center",
      col = "center",
    },

    zone = {
      percentage = 0.15,
      padding = { top = 2, bot = 2, left = 2, right = 2 },
      margin = { top = 0, bot = 0, left = 0, right = 0 },
    },
  },

  -- Visual debug overlays (zone boundary drawing on the buffer).
  -- Disabled by default. Set debug.enabled = true and debug.zones = true
  -- to see colored zone borders.
  debug = {
    enabled = false,
    zones = false,
  },

  -- File logging of computed zone measurements.
  -- Set log.enabled = true and log.zones = true to log measurements
  -- on every render cycle.
  log = {
    enabled = false,
    zones = false,
    file = "./foyer-debug.log",
  },
})
```

### Zone Layout

Each layer is allocated a zone as a percentage of the usable screen height:

| Layer | Default Zone | Description |
|---|---|---|
| `background` | `1.0` (100%) | Full usable screen |
| `header` | `0.30` (30%) | Upper portion for logo/art |
| `menu`  | `0.40` (40%) | Largest zone for menu items |
| `stats` | `0.15` (15%) | Project/file statistics |
| `footer` | `0.15` (15%) | Bottom portion for status text |

When zone percentages total less than 1.0 (100%), the remaining space is evenly distributed as equal top and bottom **margin** to every zone.

**Padding** (`zone.padding`) is inner spacing — the gap between the zone boundary and where content begins. **Margin** (`zone.margin`) is outer spacing — the gap outside the zone. This follows the same model as CSS.

Each layer also has a `position` object with `row` and `col` options:
* `row`: `"top"`, `"center"`, or `"bottom"` — vertical alignment within the padded zone
* `col`: `"left"`, `"center"`, or `"right"` — horizontal alignment within the padded zone

All layers default to `"center"` for both axes.

---

## 🐛 Debugging

foyer.nvim provides two independent debug features for diagnosing layout issues:
**visual zone overlays** (buffer highlights) and **file logging** (zone measurements
to disk). Each has its own toggle, so you can use them separately or together.

### Enabling Debug + Log

```lua
require("foyer").setup({
  -- Visual: draw colored zone boundaries on the buffer
  debug = {
    enabled = true,
    zones = true,
  },

  -- File: log zone measurements on every render cycle
  log = {
    enabled = true,
    zones = true,
    file = "./foyer-debug.log",  -- optional, default shown
  },
})
```

| Feature | Requires | Effect |
|---|---|---|
| Visual overlays | `debug.enabled = true` + `debug.zones = true` | Colored borders on each zone |
| File logging | `log.enabled = true` + `log.zones = true` | Zone measurements written to `log.file` |
| Both | All four true | Overlays + logging on every render |

### 1. Visual Zone Overlays

Colored horizontal lines are drawn on the buffer showing each zone's boundaries:

| Color | Layer |
|---|---|
| Peach | `header` |
| Mint | `menu` |
| Sky Blue | `stats` |
| Lavender | `footer` |

Each boundary line is labeled at the left margin with `name(h=<height>,r=<row>)`.
This lets you visually confirm zones are positioned where you expect.

### 2. Zone Log File

When `log.enabled` and `log.zones` are both true, every render appends zone
measurements to the file. The format uses a timestamp header, one indented line
per zone, and a separator between render cycles:

```
2026-06-17 16:20:46
  [header] row=1 h=6 pad={t=2,b=2,l=2,r=2} margin={t=0,b=0,l=0,r=0}
  [menu] row=7 h=9 pad={t=2,b=2,l=2,r=2} margin={t=0,b=0,l=0,r=0}
  [stats] row=16 h=3 pad={t=2,b=2,l=2,r=2} margin={t=0,b=0,l=0,r=0}
  [footer] row=19 h=3 pad={t=2,b=2,l=2,r=2} margin={t=0,b=0,l=0,r=0}

----------------------
```

This is useful for tracking how zones change across terminal resizes or config edits.

### 3. `:FoyerDebug` Command

Run `:FoyerDebug` to get a notification with a complete layout report:

```
## Foyer Debug
Canvas: 120x40
Total zone pct: 0.90
Debug enabled: true
Debug zones: true
Log enabled: true
Log zones: true
Log file: ./foyer-debug.log

=== Zone Configs ===
header: pct=0.30 pad={t=2,b=2,l=2,r=2} margin={t=0,b=0,l=0,r=0}
menu:   pct=0.40 pad={t=2,b=2,l=2,r=2} margin={t=0,b=0,l=0,r=0}
stats:  pct=0.15 pad={t=2,b=2,l=2,r=2} margin={t=0,b=0,l=0,r=0}
footer: pct=0.15 pad={t=2,b=2,l=2,r=2} margin={t=0,b=0,l=0,r=0}

=== Computed Zones ===
header: row=1 height=25 (row+height=26)
menu:   row=29 height=40 (row+height=69)
stats:  row=71 height=15 (row+height=86)
footer: row=88 height=10 (row+height=98)

Next after footer: row 98 (canvas height: 98)
```

The command also detects overflow and shows warnings:

```
OVERFLOW: content extends 3 lines past canvas
WARNING: footer zone extends 3 lines beyond canvas
```

### Debugging Common Issues

**Footer not visible:** Run `:FoyerDebug` and check for the overflow warning.
If the footer zone extends past `canvas height`, its content is silently clipped.
Reduce zone percentages or padding to fix.

**Content offset by a few columns:** Verify `zone.padding.left` values match
across layers. A mismatch between the header's centering and other layers causes
horizontal drift.

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
│           ├── log.lua         -- Pure file I/O for zone measurement logging
│           └── debug.lua       -- Visual zone boundary overlays on the buffer
```

All layers use the centralized `align` module for consistent horizontal and vertical positioning, and `screen.usable()` for accurate viewport dimensions that account for vim's reserved UI space (statusline, cmdheight, tabline).

Debug features are independently toggled:
* `debug.enabled + debug.zones` draws colored zone boundary overlays via `debug.draw_zones()`
* `log.enabled + log.zones` writes zone measurements to a log file via `log.log()` / `log.sep()`

## Deployment Strategy & Branch Management

We use a three-tier branch model to ensure stable production deployments and robust testing. All new developers must run the following command to enable the production release alias:
`git config --local include.path ../.gitconfig`

### Branches

1. `main` (Production)

* Public-facing, stable version of the plugin.
* Managed via `git release` (fast-forward merge from `staging`).

1. `staging` (Integration Lane)

* The "source of truth" for the next release.
* Accepts **squash merges** from `dev` (or `feature/*`/`hotfix/*` in emergencies).
* Triggers automated testing and build checks on Pull Request.

1. `dev` (Testing Lane)

* Protected branch for final pre-production validation.
* Requires a Pull Request; triggers all automated tests and build checks.
* Can be hard reset to `staging` to maintain perfect synchronization.

1. `feature/*` and `hotfix/*` (Work Branches)

* Always spawned from `staging`.
* Short-lived branches for new features or urgent fixes.

### Release Flow

1. **Development:** Spawn `feature/*` or `hotfix/*` branches from `staging`.
2. **Validation:** Open a PR from your work branch to `dev`. Validate via automated tests.
3. **Integration:** Once `dev` is flawless, open a PR from `dev` to `staging`. This performs a **squash merge** into `staging`.
4. **Production Release:** When `staging` is ready for production, run `git release` to perform a fast-forward merge into `main`.

## 📄 License

Distributed under the **MIT License**. See `LICENSE` for more information.
