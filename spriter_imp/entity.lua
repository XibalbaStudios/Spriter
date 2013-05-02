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

-- Standard library imports --
local ipairs = ipairs
local tonumber = tonumber

-- Modules --
local mainline = require("spriter_imp.mainline")
local timeline = require("spriter_imp.timeline")
local utils = require("spriter_imp.utils")

-- Exports --
local M = {}

--- DOCME
-- @ptable entity
function M.LoadPass (entity)
	local entity_data = utils.NewLUT()

  -- Extract data for animations (only type of child for entities)
	for _, anim, aprops in utils.Children(entity) do
	  -- Set properties from xml attributes: looping, loop_to, length
		local anim_data = {
			looping = aprops.looping, loop_to = aprops.loop_to or 0,
			length = tonumber(aprops.length)
		}
    -- Iterate over children (one mainline, zero or many timelines)
		for _, timeline_data in utils.Children(anim) do
  		local anim_type = timeline_data.name
      if (anim_type == 'mainline') then
			  anim_data.mainline = mainline.LoadPass(timeline_data)
		  elseif (anim_type == 'timeline') then
		    local tl = timeline.LoadPass(timeline_data)
      	utils.AddByID(anim_data, tl, timeline_data.properties)
	    end
		end

		utils.AddToLUT(entity_data, anim_data, aprops)
	end

	return entity_data
end

--- DOCME
-- @ptable data
function M.Process (data)
	for _, entity_data in ipairs(data.entity) do
		for _, anim_data in ipairs(entity_data) do

		  local bone_refs = anim_data.mainline[1].bone_ref
      local bone_table = {}
    	for idx, bone_data in ipairs(bone_refs) do
    	  bone_table[idx] = bone_data.timeline
      end
      anim_data.bone_table = bone_table

			mainline.Process(data, anim_data)
			timeline.Process(data, anim_data)
		end
	end
end

-- Export the module.
return M