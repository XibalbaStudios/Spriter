--- Spriter entity logic.

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
local Animation = utils.FuncTable()

Animation.mainline = require("spriter_imp.mainline")
Animation.timeline = require("spriter_imp.timeline")

--
return function(entity, data, eprops)
	local entities, entity_data = data._entities or utils.NewLUT(), utils.NewLUT()

	for _, anim, aprops in utils.Children(entity) do
		local anim_data = { _mainline = {}, length = aprops.length, looping = aprops.looping, loop_to = aprops.loop_to or 0 }
--assert(anim.name == "animation") ??
--		Animation(anim, data)

--		utils.Dump("ANIM: ", anim, _)
		for _, aelem in utils.Children(anim) do
--			utils.Dump("AELEM: ", aelem, _)
			Animation(aelem, data, anim_data)
		end
-- assert(anim._timeline)
		utils.AddToLUT(entity_data, anim_data, aprops)
	end

	--
	utils.AddToLUT(entities, entity_data, eprops)

	data._entities = entities
end