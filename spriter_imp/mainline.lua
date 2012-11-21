--- Spriter mainline logic.

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
local MainlineKey = utils.FuncTable()

--
function MainlineKey:object (data, oprops)
-- Err... not in Example.SCML... do timeline first, I guess
--[[
	--
	local folder, file
	local object_type = self.object_type or "sprite"
	local x, y = self.x or 0, self.y or 0
	local xref, yref = self.pivot_x or 0, self.pivot_y or 0 -- or def if sprite
	local angle, xscale, yscale = self.angle or 0, self.scale_x or 1, self.scale_y or 1
	local alpha = self.a or 1
]]
end

--
function MainlineKey:object_ref (data, oprops)
	return {
		key = utils.Index(oprops, "key"),
		timeline = utils.Index(oprops, "timeline"),
		z_index = tonumber(oprops.z_index)
	}
end

--
return function(mainline, data, animation)
--assert(not animation._mainline)
	local mainline_data = {}

	for _, key, kprops in utils.Children(mainline) do
		local key_data = { time = tonumber(kprops.time) or 0 }
--assert(key.id == _ - 1)?
		for _, child, cprops in utils.Children(key) do
			local object_data = MainlineKey(child, data, cprops)

			utils.AddByID(key_data, object_data, cprops)
		end

		utils.AddByID(mainline_data, key_data, kprops)
	end

	animation._mainline = mainline_data
end