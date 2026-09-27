-- utils/gpu_adapter.lua — pick the best WebGPU adapter for this platform.
--
-- Lazy enumeration: `wezterm.gui.enumerate_gpus()` is deferred into `build()`
-- which runs once per `pick_best()` call.
--
-- Usage: require("utils.gpu_adapter"):pick_best() -- returns adapter or nil

local wezterm = require("wezterm")
local platform = require("utils.platform")()

-- See https://github.com/gfx-rs/wgpu#supported-platforms for available backends.
local AVAILABLE_BACKENDS = {
	windows = { "Dx12", "Vulkan", "Gl" },
	linux   = { "Vulkan", "Gl" },
	mac     = { "Metal" },
}

local M = {}
M.__index = M

local function build()
	local backends = AVAILABLE_BACKENDS[platform.os]
	local self = setmetatable({
		__preferred_backend = backends[1],
		DiscreteGpu = nil, IntegratedGpu = nil, Cpu = nil, Other = nil,
	}, M)
	for _, adapter in ipairs(wezterm.gui.enumerate_gpus()) do
		self[adapter.device_type] = self[adapter.device_type] or {}
		self[adapter.device_type][adapter.backend] = adapter
	end
	return self
end

-- Fallback chain: discrete > integrated > other > cpu. Each tier may be empty.
local function first_available(self)
	return self.DiscreteGpu or self.IntegratedGpu or self.Other or self.Cpu
end

function M:pick_best()
	local instance = build()
	local options = first_available(instance)
	if not options then
		wezterm.log_error("No GPU adapters found. Using default adapter.")
		return nil
	end
	-- `options` is a { [backend_name] = adapter } table. Prefer this
	-- platform's first-listed backend (e.g. Vulkan on Linux, Dx12 on
	-- Windows); fall back to whatever adapter is available.
	local by_backend = options[instance.__preferred_backend]
	if by_backend then return by_backend end
	-- `next(options)` would return the KEY (a backend string), not the
	-- adapter object — use pairs() to grab the actual adapter value.
	for _, adapter in pairs(options) do return adapter end
	return nil
end

return M