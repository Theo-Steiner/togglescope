# Togglescope

**Togglescope** is an extension for [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim#pickers) that allows you to toggle between two picker configurations with just one keypress.

## Example Use Case

By default, telescope's live_grep or find_files pickers do not search through hidden or gitignored files. I sometimes find myself grepping for a string, only to then remember that the string I'm looking for is in some random file inside an ignored directory.
Now if you're like me, and you struggle to remember how to launch a picker with a configuration that doesn't ignore the file you're looking for, **togglescope** is the tool for you!
Just hit the keymap you configured, and like magic your picker's configuration is swapped with a config more suitable to the special job you're trying to do.
If you change your mind and want your default config back, just hit the same keymap again and everything returns to the way it was.

## Installation

You can install & configure togglescope with any package manager. 
There's three steps to the process: 

1. Install the package as a dependency to `"nvim-telescope/telescope.nvim"`
2. Add your togglescope configuration under `extensions.togglescope` to your telescope config
3. Set up keymaps for your modified pickers

### With Lazy.nvim

```lua
{
    -- 1. Register "Theo-Steiner/togglescope" as a dependency to telescope
	"nvim-telescope/telescope.nvim",
	dependencies = { 
      "Theo-Steiner/togglescope"
    },
    -- 2. Configure togglescope in the extensions setting of your telescope config
	config = function()
		require("telescope").setup({
			extensions = {
				togglescope = {
					find_files = {
                                            ['<C-^>'] = {
                                                hidden = true,
                                            }
					}
				}
			},
		})
	end,
    -- 3. Configure a keymap to launch the togglescope picker
	keys = {
		{
			"<leader>ff",
			function()
				require('telescope').extensions.togglescope.find_files()
			end
		},
	},
}
```

## Configuration

Togglescope is configured via `extensions.togglescope` of your telescope config. 
A valid `extensions.togglescope` config is structured as `picker_name > keymap > picker_config`.
```lua
--- A picker that you want to add a toggleable config to.
--- All builtin pickers of telescope are valid as picker_name.
--- @type 'find_files' | 'live_grep' | 'grep_string' ...and so on
--- @see github.com/nvim-telescope/telescope.nvim#pickers
local picker_name = 'find_files'

--- The keymap that toggles between the toggleable config and the default config.
--- For now the keymap will always be set in insert and normal mode. If necessary I might make this configurable at a later point.
--- @type '<C-^>' | '<C-f>' | '<C-y>' ...whatever you want!
local keymap = '<C-^>'

--- The toggleable_config you want to switch to when you hit your keybinding.
--- 'togglescope_title' is a special property that allows you to set a title for the picker when your toggleable config is active.
--- @type {[string]: any, togglescope_title: string} ...any valid config for a specific builtin picker!
local toggleable_config = {
    no_ignore = true,
    togglescope_title = "Find Files (hidden)"
}

--- @type {[picker_name]: {[keymap]: toggleable_config}}
local togglescope_config = {[picker_name]: {[keymap]: toggleable_config}}

require("telescope").setup({
    extensions = {
        togglescope = togglescope_config
    },
})
```

## Usage

For every `picker_name` you add as a top level key to your `togglescope_config`, togglescope will generate a modified picker that has a keymapping to toggle between your toggleable config and the picker's default config (the config you originially launched the picker with).
These modified pickers are accessible from `require('telescope').extensions.togglescope` and can be used as you would use builtin telescope pickers.

```lua
-- old keymap
{
    "<leader>ff",
    function()
        require('telescope.builtin').find_files()
    end
}
-- simply becomes
{
    "<leader>ff",
    function()
        require('telescope').extensions.togglescope.find_files()
    end
}
```

## Togglescope Recipies

I thought it might be useful to collect a few useful togglescope configs, so that users can just copy/paste a config they are interested in!

### How I (Author) Use Togglescope

For now I use togglescope to toggle between searching through hidden files using the find_files and live_grep pickers with BurntSushi/ripgrep as a search engine.

```lua
local togglescope_config = {
    -- configure find_files as a togglescope picker
    find_files = { 
        -- on alternate file hotkey <C-^> toggle to the below config
        ['<C-^>'] = {
            -- search through hidden files/directories
            hidden = true,
            -- search through ignored directories/files (I occasionally want to look into node_modules)
            no_ignore = true,
            -- when this config is active, set the title to this
            togglescope_title = "Find Files (hidden)"
        }
    },
    -- configure find_files as a togglescope picker
    live_grep = {
        -- on alternate file hotkey <C-^> toggle to the below config
        ['<C-^>'] = {
            -- with the live_grep picker args/flags are passed to ripgrep using "additional_args"
            additional_args = {
                -- search through hidden files/directories
                '--hidden',
                -- search through ignored directories/files (I occasionally want to look into node_modules)
                '--no-ignore',
                -- specify a glob for the search
                "-g",
                -- ignore the glob of "package-lock.json" (mostly no useful info in there)
                "!package-lock.json",
            },
            -- when this config is active, set the title to this
            togglescope_title = "Live Grep (hidden)"
        }
    }
} 
require('telescope').setup({
    extensions = {
        -- configure togglescope with the above config
        togglescope = togglescope_config
    },
    defaults = {
        -- set an ignore pattern to always ignore files in the .git directory
        file_ignore_patterns = { "^.git/" },
    }
})
```
