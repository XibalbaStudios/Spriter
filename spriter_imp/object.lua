--- Spriter object logic.

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
local assert = assert
local pairs = pairs
local tonumber = tonumber

-- Modules --
local utils = require("spriter_imp.utils")

-- Exports --
local M = {}

-- --
local Props = {}

-- --
local Interpolate = {}

--
function Interpolate.sprite (entity, object_data, props)
	local group = entity.m_objects[object_data.timeline]

	object_data = object_data[1] -- TODO: Flatten, I think...

	--
	local name = object_data.file.name

	if group.m_name ~= name then
		if group.numChildren ~= 0 then
			group:remove(1)
		end

		local data = entity.m_data

		display.newImage(group, file, data.base)

		group.m_name = name
	end

	local image = group[1]

	-- image, atlas_image...
	image.alpha = props.a
	image.x = props.x
	image.y = props.y
	image.xReference = image.width * (props.pivot_x - .5)
	image.yReference = image.height * (props.pivot_y - .5)
	image.rotation = props.angle
	image.xScale = props.scale_x
	image.yScale = props.scale_y
end

--- DOCME
-- @pgroup entity
-- @ptable object_data
-- @uint to
function M.Interpolate (entity, object_data, to)
	local anim = entity.m_anim
	local timeline, key = anim[object_data.timeline], object_data.key
	local p1, p2, props = timeline[key], timeline[key + 1], Props

	--
	if p1.time == to or not p2 then
		props = p1
	elseif to >= p2.time then
		props = p2
	else
		local t = (to - p1.time) / (p2.time - p1.time)

		for k, v in pairs(p1) do
			if k ~= "object_type" then
				Props[k] = v + t * (p2[k] - v)
			end
		end
	end

	--
	Interpolate[object_data.object_type](entity, object_data, props)
end

--- DOCME
-- @ptable oprops
-- @string object_type
-- @treturn OD
function M.LoadPass (oprops, object_type)
	local object_data = { object_type = object_type }

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

--- DOCME
-- @ptable data
-- @ptable object
function M.Process (data, object)
	local folder = data.folder[object.folder]
	local file = folder and folder[object.file]

	if file then
		object.file, object.folder = file

		if object.pivot_x == false then
			object.pivot_x = file.pivot_x
		end

		if object.pivot_y == false then
			object.pivot_y = file.pivot_y
		end
	end
end

-- Export the module.
return M