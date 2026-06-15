# foyer.nvim 

`foyer.nvim` is a modern, high-performance entrance screen for Neovim. Unlike traditional dashboards that render components sequentially top-to-bottom, `foyer.nvim` utilizes a 2D memory canvas compositor to blend distinct text, logo, and background layers with true character-level transparency.

## ⚡ Features
* **4-Layer Matrix Compositor:** Independent processing for background, header, menu, and footer layers.
* **True Character Transparency:** Background components (like custom starfields) seamlessly peek through empty spacing in foreground elements.
* **Flawless Resizing:** Instant layout grid recalculations on terminal resize without window clipping or race conditions.
* **Isolated Interactivity:** Robust cursor-locking mechanics that restrict navigation strictly to active menu lines.

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

## 🛠️ Architecture Overview

The plugin's directory structure isolates presentation logic from data layout computation:

```text
foyer.nvim/
├── lua/
│   └── foyer/
│       ├── init.lua          -- Public API & configuration merging
│       ├── ui.lua            -- Buffer orchestration & resize tracking
│       ├── canvas.lua        -- The core 2D cell blending & rendering engine
│       ├── interactive.lua   -- Focus management & keymap processing
│       └── layers/           -- Data generators for visual components
│           ├── background.lua
│           ├── header.lua
│           ├── menu.lua
│           └── footer.lua

```

## 📄 License

Distributed under the **MIT License**. See `LICENSE` for more information.
