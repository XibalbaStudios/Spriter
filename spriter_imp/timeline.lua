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
local tonumber = tonumber

-- Modules --
local object = require("spriter_imp.object")
local utils = require("spriter_imp.utils")

-- Exports --
local M = {}

-- --
local TimelineKey = utils.FuncTable()

--
function TimelineKey:bone (bprops)
end

--
function TimelineKey:object (oprops, object_type)
	return object.LoadPass(oprops, object_type)
end

-- --
local UsageDefs = { box = "collision", point = "neither", entity = "display", sprite = "display" }

--- DOCME
-- @ptable timeline
-- @ptable animation
function M.LoadPass (timeline, animation)
	local timeline_data, tprops = {}, timeline.properties

	--
	local object_type, usage = tprops.object_type or "sprite"

	if object_type ~= "sound" then
		if object_type ~= "variable" then
			usage = tprops.usage or UsageDefs[object_type]
		end

		if object_type ~= "sprite" or (usage == "collision" or usage == "both") then
			timeline_data.name = tprops.name
		end

		if object_type == "variable" then
			timeline_data.variable_type = tprops.variable_type or "string"
		end
	end

	timeline_data.usage = usage

	--
	for _, key, kprops in utils.Children(timeline) do
		local key_data = {
			curve_type = kprops.curve_type or "linear",
			spin = tonumber(kprops.spin) or 1,
			time = tonumber(kprops.time) or 0
		}
--assert(key.id == _ - 1)?
		for _, child, cprops in utils.Children(key) do
			key_data[#key_data + 1] = TimelineKey(child, cprops, object_type)
		end
-- ^^^ sounds like key will always be one-element and I could flatten it and object / bone together? 
		utils.AddByID(timeline_data, key_data, kprops)
	end

	utils.AddByID(animation, timeline_data, tprops)
end	

--- DOCME
-- @ptable data
-- @ptable animation
function M.Process (data, animation)
	for _, timeline_data in ipairs(animation) do
		for _, key_data in ipairs(timeline_data) do
			for _, object_data in ipairs(key_data) do
				-- Resolve object properties (file, default values), discard intermediates
				if object_data.object_type then
					object.Process(data, object_data)

				-- TODO: bone, variable?
				else
					-- ??
				end
			end
		end
	end
end

-- Export the module.
return M