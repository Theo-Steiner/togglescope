local has_telescope, telescope = pcall(require, 'telescope')
if not has_telescope then
	error 'Could not find telescope.nvim (https://github.com/nvim-telescope/telescope.nvim)'
end

local builtin = require('telescope.builtin')

--- internal for now, might expose later if needed
--- @type {defaults: {[string]: Opts}}
local M = {
	defaults = {},
}

--- Generate a function, that calls a picker alternately with its original or modified opts
--- @param picker_name PickerName
--- @param toggle_opts Opts
M.toggle = function(toggle_opts, picker_name)
	--- @param _opts Opts
	--- @param launch PickerFunction
	return function(_opts, launch)
		--- deepcopy, so telescope internal tables are not modified
		--- @type Opts
		local opts = vim.deepcopy(_opts)
		if not M.defaults[picker_name] then
			--- deepcopy, so defaults are not modified after the fact
			M.defaults[picker_name] = vim.deepcopy(opts)
		end
		if vim.deep_equal(opts, M.defaults[picker_name]) then
			opts['prompt_title'] = toggle_opts['togglescope_title'] or 'toggled'
			opts = vim.tbl_deep_extend('force', opts, toggle_opts)
		else
			opts = M.defaults[picker_name]
		end
		launch(opts, true)
	end
end

--- Generates a "launch" function, that launches a picker with preconfigured keyhandlers
--- @param picker_fn PickerFunction
--- @param toggle_fns {[Keybinding]: Opts}
M.add_action = function(picker_fn, toggle_fns)
	local query = nil
	--- @param opts Opts
	local function launch(opts, is_keymap_invocation)
		opts = opts or {}
		if not is_keymap_invocation then
			--- reset default opts
			M.defaults = {}
		end

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

		--- call the picker function with modified opts
		picker_fn(vim.tbl_extend('force', opts, { default_text = opts.prompt_value }))
	end

	return launch
end

--- Generates a picker based on a builtin picker, with custom attach_mappings
--- @param picker_name PickerName
--- @param attach_config AttachConfig
M.generate_picker = function(picker_name, attach_config)
	local picker_fn = builtin[picker_name]
	if not picker_fn then
		error('Could not find picker ' .. picker_name)
	end
	--- every valid top level entry of the attach_config is a key-combo (eg. '<C-^>')
	--- each key map toggles a certain set of toggle_opts
	local toggle_functions = {}
	for keybinding, toggle_opts in pairs(attach_config) do
		toggle_functions[keybinding] = M.toggle(toggle_opts, picker_name)
	end
	return M.add_action(picker_fn, toggle_functions)
end

--- exposed to the enduser - holds generated pickers
--- @type {config: Config} | TogglescopePickers
local togglescope = {}

--- @see github.com/nvim-telescope/telescope.nvim/blob/master/developers.md#bundling-as-extension
return telescope.register_extension {
	--- is run after telescope setup
	--- @param user_config Config
	setup = function(user_config)
		--- accept user_config
		togglescope.config = user_config or {}
		--- generate a picker with custom attach mappings for every top level entry of the config
		--- currently only "telescope.builtin" pickers are valid top level entries
		for picker_name, picker_config in pairs(togglescope.config) do
			togglescope[picker_name] = M.generate_picker(picker_name, picker_config)
		end
	end,
	--- make generated pickers accessible via
	--- require('telescope').extensions.togglescope[picker_name]
	exports = togglescope,
}

--- TYPES

---@alias PickerName
---| "'{picker_name}'" # currently only telescope builtin pickers are allowed

---@alias Keybinding
---| string # such as '<C-^>'

---@alias Opts
---| {[string]: string | number | {} | fun(number, any): any}

---@alias AttachConfig
---| {[Keybinding]: Opts}

--- @alias Config
---| {[string]: AttachConfig}

--- @alias PickerFunction
---| fun(Opts, is_keymap_invocation?: boolean): nil

--- @alias TogglescopePickers
---| {[PickerName]: PickerFunction}
