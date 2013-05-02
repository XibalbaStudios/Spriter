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
local type = type

-- Modules --
local utils = require("spriter_imp.utils")

-- Exports --
local M = {}

-- --
local Props = {}

-- --
local Interpolate = {}

-- --

local BoneTransforms = {}

--
local function GetGroup (entity, z)
  if (not z) then
    z = 0
  end
	z = z + 1

	local objects = entity.m_objects

	for _ = objects.numChildren + 1, z do
		objects:insert(display.newGroup())
	end

	objects[z].isVisible = true

	return objects[z]
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
-- if not image...
	-- image, atlas_image...
	if image then
  	image.alpha = props.a
  	image.rotation = 360 - props.angle % 360

  	image.xScale = props.scale_x
  	image.yScale = props.scale_y

  	local xref = (props.pivot_x - .5) * image.width
  	local yref = (.5 - props.pivot_y) * image.height

  	image.xOrigin = -xref + props.x
  	image.yOrigin = -yref - props.y
  	image.xReference = xref
  	image.yReference = yref
	end
end

function M.interpolate_props(p1, p2, to)
  local props = {}
  local spin, t = p1.spin, (to - p1.time) / (p2.time - p1.time)

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

function M.rotate_point(x, y, angle, origin_x, origin_y, flipped)
  if(flipped) then
    angle = -angle
  end

  s = math.sin(angle * math.pi/180)
  c = math.cos(angle * math.pi/180)
  xnew = (x * c) - (y * s)
  ynew = (x * s) + (y * c)
  xnew = xnew + origin_x
  ynew = ynew + origin_y
  x = xnew
  y = ynew
  return x, y
end

function M.apply_parent_transform(props, parent)
  if not parent then
    return props
  end

  local parent_t = BoneTransforms[parent]

  props.x = props.x * parent_t.scale_x
  props.y = props.y * parent_t.scale_y
  local flipped = ((parent_t.scale_x < 0) ~= (parent_t.scale_y < 0))
  props.x, props.y = M.rotate_point(props.x, props.y, parent_t.angle, parent_t.x, parent_t.y, flipped)

  props.angle = props.angle + parent_t.angle
  props.scale_x = props.scale_x * parent_t.scale_x;
  props.scale_y = props.scale_y * parent_t.scale_y;
  return props
end

--- DOCME
-- @pgroup entity
-- @ptable object_data
-- @uint to
function M.Interpolate (entity, object_data, to)
	local anim = entity.m_anim

  local bone_table = anim.bone_table
  local oparent = bone_table[object_data.parent]

  -- Find the timeline and key
	local timeline, key = anim[object_data.timeline], object_data.key
  -- if not timeline then
  --   return
  --   end

	local p1, p2 = timeline[key], timeline[key + 1]
	local props = {}

	--
	if p1.time >= to or not p2 then
		props = p1
	elseif to >= p2.time then
		props = p2
	else
    props = M.interpolate_props(p1, p2, to)
		props.file = p1.file
	end
  props = M.apply_parent_transform(props, oparent)

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
function M.LoadPass (oprops, object_type)
	local object_data = {}
	--
	if object_type == "sprite" or object_type == "entity" or object_type == "sound" then
    if oprops["folder"] then
		  object_data.folder = utils.Index(oprops, "folder")
		  object_data.file = utils.Index(oprops, "file")
    end

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
		object_data.a = tonumber(oprops.a) or 1

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