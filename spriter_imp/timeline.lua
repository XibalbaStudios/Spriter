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
local utils = require("spriter_imp.utils")

-- --
local TimelineKey = utils.FuncTable()

--
function TimelineKey:bone (data, bprops)
end

--
function TimelineKey:object (data, oprops, object_type)
	local object_data = {}

	--
	if object_type == "sprite" or object_type == "entity" or object_type == "sound" then
		object_data.folder = utils.Index(oprops, "folder")
		object_data.file = utils.Index(oprops, "file")

		--
		if object_type ~= "sound" then
			object_data.scale_x = tonumber(oprops.scale_x) or 1
			object_data.scale_y = tonumber(oprops.scale_y) or 1
		end
	end

	--
	if object_type ~= "variable" and object_type ~= "sound" then
		object_data.x = tonumber(oprops.x) or 0
		object_data.y = tonumber(oprops.y) or 0
		object_data.a = tonumber(oprops.a) or 0

		--
		if object_type == "sprite" or object_type == "box" then
			local def = object_type == "box" and 0 or false

			object_data.pivot_x = tonumber(oprops.pivot_x) or def
			object_data.pivot_y = tonumber(oprops.pivot_y) or def
		end

		--
		if object_type ~= "point" then
			object_data.angle = tonumber(oprops.angle) or 0
		end
	end

	return object_data
end

-- --
local UsageDefs = { box = "collision", point = "neither", entity = "display", sprite = "display" }

--
return function(timeline, data, animation)
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
			key_data[#key_data + 1] = TimelineKey(child, data, cprops, object_type)
		end

		utils.AddByID(timeline_data, key_data, kprops)
	end

	utils.AddByID(animation, timeline_data, tprops)
end