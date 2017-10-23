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
local ipairs = ipairs
local tonumber = tonumber

-- Modules --
local object = require("spriter_imp.object")

-- Exports --
local M = {}

--
local function Ref (ref)
	local parent = ref.parent

	if parent then
		parent = parent + 1
	end

	return {
		key = (tonumber(ref.key) or 0) + 1,
		parent = parent,
		timeline = (tonumber(ref.timeline) or 0) + 1
	}
end

--- DOCME
-- @ptable mainline
-- @ptable animation
function M.Load (mainline)
	local mainline_data = {}

	for _, key in ipairs(mainline) do
		local key_data = {
			time = tonumber(key.time) or 0
		}

		for _, child in ipairs(key) do
			local label, ref = child.label
			local into = key_data[label] or {}

			if label == "bone_ref" or label == "object_ref" then
				ref = Ref(child)

				if label == "object_ref" then
					ref.z_index = tonumber(child.z_index)
				end
			end

			key_data[label], into[#into + 1] = into, ref
		end

		mainline_data[#mainline_data + 1] = key_data
	end
	
	return mainline_data
end

-- Export the module.
return M