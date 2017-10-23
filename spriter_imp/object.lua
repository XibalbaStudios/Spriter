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
local cos = math.cos
local pairs = pairs
local rad = math.rad
local sin = math.sin
local tonumber = tonumber
local type = type

-- Exports --
local M = {}

-- --
local PropsList = {}

-- --
local PropsIndex = 1

--
local function NewProps ()
	local old = PropsList[PropsIndex]
	local props = old or {}

	if old then
		for k in pairs(old) do
			old[k] = nil
		end
	else
		PropsList[PropsIndex] = props
	end

	PropsIndex = PropsIndex + 1

	return props
end

--
function M.Done ()
	PropsIndex = 1
end

-- --
local Interpolate = {}

-- --
local BoneTransforms = {}

--
local function GetGroup (entity, z)
	z = (z or 0) + 1

	for _ = entity.numChildren + 1, z do
		entity:insert(display.newGroup())
	end

	entity[z].isVisible = true

	return entity[z]
end

function Interpolate.box ()
	-- TODO!
end

function Interpolate.point ()
	-- TODO!
end

--
function Interpolate.sprite (entity, z, props)
	local group = GetGroup(entity, z)

	--
	local file = props.file
	local name = props.file.name

	if group.m_name ~= name then
		if group.numChildren ~= 0 then
			group:remove(1)
		end

		local data = entity.m_data

		display.newImage(group, data.path .. name, data.base)

		group.m_name = name
	end

	local image = group[1]

	-- image, atlas_image...
	if image then
		image.alpha = props.a
		image.rotation = 360 - props.angle % 360
		image.anchorX, image.x = props.pivot_x, props.x
		image.anchorY, image.y = 1 - props.pivot_y, -props.y
		image.xScale = props.scale_x or 1
		image.yScale = props.scale_y or 1
	end
end

--
local function RotatePoint (x, y, angle, origin_x, origin_y, flipped)
	if flipped then
		angle = -angle
	end

	angle = rad(angle)

	local s = sin(angle)
	local c = cos(angle)
	local xnew = x * c - y * s
	local ynew = x * s + y * c

	return xnew + origin_x, ynew + origin_y
end

--
local function ApplyParentTransform (props, parent)
	local parent_t = BoneTransforms[parent]
	local sx, sy = parent_t.scale_x or 1, parent_t.scale_y or 1

	props.x = props.x * sx
	props.y = props.y * sy

	local flipped = (sx < 0) ~= (sy < 0)

	props.x, props.y = RotatePoint(props.x, props.y, parent_t.angle, parent_t.x, parent_t.y, flipped)
	props.angle = props.angle + parent_t.angle
	props.scale_x = (props.scale_x or 1) * sx
	props.scale_y = (props.scale_y or 1) * sy
end

--
local function Dup (from)
	local props = NewProps()

	for k, v in pairs(from) do
		props[k] = v
	end
	
	return props
end

--
local function InterpolateProps (p1, p2, to, length)
	local spin, t, props = p1.spin, p1.curve((to - p1.time) / ((length or p2.time) - p1.time)), NewProps()

	for k, v in pairs(p1) do
		if type(v) == "number" then
			local v2 = p2[k]

			--
			if k == "angle" then
				if spin == -1 then
					if v < v2 then
						v = v + 360
					end
				elseif v2 < v then
					v2 = v2 + 360
				end
			end

			--
			props[k] = v + t * (v2 - v)
		end
	end

	return props
end

--- DOCME
-- @pgroup entity
-- @ptable object_data
-- @uint to
-- @int? length
function M.Interpolate (entity, object_data, to, length)
	local anim = entity.m_anim
	local bone_table = anim.bone_table
	local oparent = bone_table and bone_table[object_data.parent]

	-- Find the timeline and key
	local timeline, key = anim[object_data.timeline], object_data.key
	local p1, p2, props = timeline[key], timeline[key + 1]

	--
	local llen

	if not p2 and length and timeline[2] then
		p2, llen = timeline[1], length
	end

	--
	if p1.time >= to or not p2 then
		props = Dup(p1) -- TODO: See if this can still be finessed in the interpolate code?
	elseif to >= p2.time and not llen then
		props = Dup(p2) -- TODO: Ditto
	else
		props = InterpolateProps(p1, p2, to, llen)
		props.file = p1.file
	end

	if oparent then
		ApplyParentTransform(props, oparent)
	end

	local is_bone = not object_data.z_index

	if is_bone then
		BoneTransforms[object_data.timeline] = props
	else
		Interpolate[timeline.object_type](entity, object_data.z_index, props)
	end
end

--- DOCME
-- @ptable oprops
-- @string object_type
-- @treturn OD
function M.Load (oprops, object_type, data)
	local object_data = {}

	--
	if object_type ~= "variable" and object_type ~= "sound" then
		object_data.x = tonumber(oprops.x) or 0
		object_data.y = tonumber(oprops.y) or 0
		object_data.a = tonumber(oprops.a) or 1

		--
		if object_type == "sprite" or object_type == "box" then
			local def = object_type == "box" and 0 or false

			object_data.pivot_x = tonumber(oprops.pivot_x) or def
			object_data.pivot_y = tonumber(oprops.pivot_y) or def
		end

		--
		object_data.angle = tonumber(oprops.angle) or 0
	end

	--
	if object_type == "sprite" or object_type == "bone" or object_type == "entity" or object_type == "sound" then
		if oprops.folder then
			local folder = data.folder[(tonumber(oprops.folder) or 0) + 1]
			local file = folder and folder[(tonumber(oprops.file) or 0) + 1]

			if file then
				object_data.file = file

				if object_data.pivot_x == false then
					object_data.pivot_x = file.pivot_x
				end

				if object_data.pivot_y == false then
					object_data.pivot_y = file.pivot_y
				end
			end
		end

		--
		if object_type ~= "sound" then
			object_data.scale_x	= tonumber(oprops.scale_x) or 1
			object_data.scale_y = tonumber(oprops.scale_y) or 1
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