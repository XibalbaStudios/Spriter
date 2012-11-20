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

-- Modules --
local utils = require("spriter_imp.utils")

-- --
local MainlineKey = utils.FuncTable()

--
function MainlineKey:object (data, key)
	--
	local folder, file
	local object_type = self.object_type or "sprite"
	local x, y = self.x or 0, self.y or 0
	local xref, yref = self.pivot_x or 0, self.pivot_y or 0 -- or def if sprite
	local angle, xscale, yscale = self.angle or 0, self.scale_x or 1, self.scale_y or 1
	local alpha = self.a or 1
end

--
function MainlineKey:object_ref ()
	local id, timeline, key, z_index
end

--
return function(mainline, data, animation)
	for _, key, kprops in utils.Children(mainline) do
		local id, time = key.id, key.time or 0
--assert(key.id == _ - 1)?
		for _, child, cprops in utils.Children(key) do
			--
			MainlineKey(child, data, key)
		end
	end
end