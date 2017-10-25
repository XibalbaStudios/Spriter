--- Spriter timeline logic.

--
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
--
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--
-- [ MIT license: http://www.opensource.org/licenses/mit-license.php ]
--

-- Standard library imports --
local ipairs = ipairs
local tonumber = tonumber

-- Modules --
local object = require("spriter_imp.object")

-- Exports --
local M = {}

--
local function Identity (t)
	return t
end

--
local function Instant (t)
	return t < 1 and 0 or 1
end

local function Linear (a, b, t)
	return (1 - t) * a + t * b
end

local function Quadratic (a, b, c, t)
	return Linear(Linear(a, b, t), Linear(b, c, t), t)
end

local function Cubic (a, b, c, d, t)
	return Linear(Quadratic(a, b, c, t), Quadratic(b, c, d, t), t)
end

local function Quartic (a, b, c, d, e, t)
	return Linear(Cubic(a, b, c, d, t), Cubic(b, c, d, e, t), t)
end

local function Quintic (a, b, c, d, e, f, t)
	return Linear(Quartic(a, b, c, d, e, t), Quartic(b, c, d, e, f, t), t)
end

--
local function MakeCurve (entry, def)
	local ctype, c1, c2, c3, c4 = entry.curve_type or def or "linear", entry.c1, entry.c2, entry.c3, entry.c4

	if ctype == "linear" then
		return Identity
	elseif ctype == "quadratic" then
		return function(t)
			return Quadratic(0, c1, 1, t)
		end
	elseif ctype == "cubic" then
		return function(t)
			return Cubic(0, c1, c2, 1, t)
		end
	elseif ctype == "quartic" then
		return function(t)
			return Quartic(0, c1, c2, c3, 1, t)
		end
	elseif ctype == "quintic" then
		return function(t)
			return Quintic(0, c1, c2, c3, c4, 1, t)
		end
	elseif ctype == "instant" then
		return Instant
	elseif ctype == "bezier" then
		return Linear
	--[[
		return function(v1, v2, t)
			local c = 3 * v1
			local b = (v2 - v1) - c
			local a = 1 - c - b

			return ((a * t + b) * t + c) * t -- TODO: find s
		end]]
	end
end

--- DOCME
-- @ptable timeline
-- @ptable animation
function M.Load (timeline, data)
	local object_type = timeline.object_type or "sprite"
	local timeline_data = { name = timeline.name, object_type = object_type }

	-- Get the keys in this timeline
	for _, timeline_entry in ipairs(timeline) do
		local label = timeline_entry.label

		--
		if label == "key" then
			for _, child in ipairs(timeline_entry) do
				local key_data = object.Load(child, object_type, data)

				key_data.spin = tonumber(timeline_entry.spin) or 1
				key_data.time = tonumber(timeline_entry.time) or 0
				key_data.curve = MakeCurve(timeline_entry)

				timeline_data[#timeline_data + 1] = key_data
			end

		--
		elseif label == "meta" then
			local obj = tonumber(timeline.obj) + 1

			for _, child in ipairs(timeline_entry) do
				local md_label = child.label

				if md_label == "tagline" then
					def_curve = Instant
					-- Can this use variables logic? (just with Instant as default)

					for _, tag_data in ipairs(child) do
						for _, tag in ipairs(tag_data) do
							local t = tonumber(tag.t) + 1
							-- hook into it
						end
					end

					local tdata = {} -- TODO!

					tdata.curve = MakeCurve(child, Instant)

				--
				elseif md_label == "varline" then
					local def = tonumber(child.def) + 1

					for _, var_data in ipairs(child) do
						-- hook into variable (should these all be a flat list up front?)
					end
					-- Add to timeline_data?
					-- Add first entry if no def at time = 0?
					-- TODO: could patch these into timeline...?

					local vdata = {} -- TODO!

					vdata.curve = MakeCurve(child)
				end
			end
		end
	end

	return timeline_data
end

-- Export the module.
return M