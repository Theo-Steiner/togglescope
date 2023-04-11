local has_telescope, telescope = pcall(require, 'telescope')
if not has_telescope then
	error 'Could not find telescope.nvim (https://github.com/nvim-telescope/telescope.nvim)'
end

local builtin = require 'telescope.builtin'

-- internal
local M = {
	defaults = {},
}

M.toggle = function(toggle_opts, picker_name)
	return function(_opts, callback)
		-- deepcopy, so telescope internal tables are not modified
		local opts = vim.deepcopy(_opts)
		if not M.defaults[picker_name] then
			-- deepcopy, so defaults are not modified after the fact
			M.defaults[picker_name] = vim.deepcopy(opts)
		end
		if vim.deep_equal(opts, M.defaults[picker_name]) then
			opts['prompt_title'] = toggle_opts['togglescope_title'] or 'toggled'
			opts = vim.tbl_deep_extend('force', opts, toggle_opts)
		else
			opts = M.defaults[picker_name]
		end
		callback(opts)
	end
end

M.add_action = function(picker_fn, toggle_fns)
	local query = nil
	local function launch(opts)
		opts = opts or {}

		opts.attach_mappings = function(new_bufnr, map)
			-- restore previous query if exists
			if query then
				local picker = require('telescope.actions.state').get_current_picker(new_bufnr)
				picker:set_prompt(query)
				-- delete saved query
				query = nil
			end
			for keybinding, toggle_fn in pairs(toggle_fns) do
				map({ "n", "i" }, keybinding, function(current_bufnr)
					local picker = require('telescope.actions.state').get_current_picker(current_bufnr)
					-- save current query
					query = picker:_get_prompt()
					toggle_fn(opts, launch)
				end)
			end
			return true
		end

		picker_fn(vim.tbl_extend('force', opts, { default_text = opts.prompt_value }))
	end

	return launch
end

-- generate a picker based on a builtin picker, with custom attach_mappings
M.generate_picker = function(picker_name, attach_config)
	local picker_fn = builtin[picker_name]
	if not picker_fn then
		print(('telescope.builtin.' .. picker_name))
		error('Could not find picker ' .. picker_name)
	end
	-- every valid top level entry of the attach_config is a key-combo (eg. '<C-^>')
	-- each key map toggles a certain set of toggle_opts
	local toggle_functions = {}
	for keybinding, toggle_opts in pairs(attach_config) do
		toggle_functions[keybinding] = M.toggle(toggle_opts, picker_name)
	end
	return M.add_action(picker_fn, toggle_functions)
end

-- exposed to the enduser - holds generated pickers
local togglescope = {}

-- see https://github.com/nvim-telescope/telescope.nvim/blob/master/developers.md#bundling-as-extension
return telescope.register_extension {
	-- is run after telescope setup
	setup = function(user_config)
		-- accept user_config
		-- TODO: add default config (with my preferences)
		togglescope.config = user_config or {}
		-- generate a picker with custom attach mappings for every top level entry of the config
		-- currently only "telescope.builtin" pickers are valid top level entries
		for picker_name, picker_config in pairs(togglescope.config) do
			togglescope[picker_name] = M.generate_picker(picker_name, picker_config)
		end
	end,
	-- make generated pickers accessible via require('telescope').extensions.togglescope[picker_name]
	exports = togglescope,
}
