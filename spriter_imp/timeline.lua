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

-- Modules --
local utils = require("spriter_imp.utils")

-- --
local TimelineKey = utils.FuncTable()

--
function TimelineKey:object (data, key)
	--
	local folder, file
	local x, y = self.x or 0, self.y or 0
	local xref, yref = self.pivot_x or 0, self.pivot_y or 0 -- or def if sprite
	local angle, xscale, yscale = self.angle or 0, self.scale_x or 1, self.scale_y or 1
	local alpha = self.a or 1
end

-- --
local UsageDefs = { box = "collision", point = "neither", entity = "display", sprite = "display" }

--
return function(timeline, data, animation)
	local id, object_type, usage = timeline.id, timeline.object_type or "sprite"
	local name, usage

	if object_type ~= "sound" then
		if object_type ~= "variable" then
			usage = timeline.usage or UsageDefs[object_type]
		end

		if object_type ~= "sprite" or (usage == "collision" or usage == "both") then
			name = timeline.name
		end

		if object_type == "variable" then
			-- SOMETHING = timeline.variable_type or "string"
		end
	end

	--
	for _, key, kprops in utils.Children(timeline) do
		local id, time, curve_type, spin = key.id, key.time or 0, key.curve_type or "linear", key.spin or 1
--assert(key.id == _ - 1)?
		for _, child, cprops in utils.Children(key) do
			--
			TimelineKey(child, data, key)
		end
	end
end