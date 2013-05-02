--- Core Spriter API.

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
local floor = math.floor
local pairs = pairs
local setmetatable = setmetatable
local type = type

-- Modules --
local entity = require("spriter_imp.entity")
local folder = require("spriter_imp.folder")
local object = require("spriter_imp.object")
local utils = require("spriter_imp.utils")
local xml = require("xml")

-- Corona globals --
local display = display
local system = system

-- Exports --
local M = {}

-- --
local Parser = xml.newParser()

-- --
local TopLevelLoaders = utils.FuncTable()
TopLevelLoaders.entity = entity.LoadPass
TopLevelLoaders.folder = folder.LoadPass

-- Atlas, character map, etc.

-- Entity methods --
local Entity = {}

-- Entity factory methods --
local EntityFactory = {}
EntityFactory.__index = EntityFactory

-- --
local LiveEntities = {}

--- DOCME
-- @string file
-- @param base
function M.NewFactory (file, base)
  -- Add .scml to file name, if missing
	if file:sub(-5) ~= ".scml" then
		file = file .. ".scml"
	end

	-- Parse the xml data
	local t = Parser:loadFile(file, base)

	-- Create the table that will hold all the data for this sprite
	-- Initialize with file, folder and path
	local data = { file = file, base = base or system.ResourceDirectory	}
	data.path = file:gsub("/.*$", "") .. "/"
	data.path = data.path:gsub("\\", "/")

  -- Iterate over top-level tags (folders and entities)
	for _, top_level_obj, tlprops in utils.Children(t) do
	  local obj_type = top_level_obj.name
	  print(obj_type, ":", tlprops.name)
    -- Add blank name if a folder's name is not set (because it's the base folder)
    if obj_type == "folder" and not tlprops.name then
      tlprops.name = ""
    end
    -- Get data for children of this object
    -- This calls LoadPass on either Folder or Entity
    local child_data = TopLevelLoaders(top_level_obj, tlprops)
		if child_data then
		  -- Save child data to the appropriate table (entity or folder list),
			local top_level_table = data[obj_type] or utils.NewLUT()
			utils.AddByID(top_level_table, child_data, tlprops)
			data[obj_type] = top_level_table
		end
	end

	-- Process the data saved above
	-- (mostly making sure correct properties are set on objects)
  entity.Process(data)
	folder.Process(data)
--[[
local path = system.pathForFile( "myfile.txt", system.DocumentsDirectory )
local file = io.open( path, "w" )
require("var_dump").Print(data, function(s, ...)
	file:write(s:format(...), "\n")
end)
io.close( file )
-- Could check for "Corona-fied" file, i.e. already processed as so...
--]]
	return setmetatable(data, EntityFactory)
end

--- DOCME
function Entity:pause ()
	self.isPlaying = false
end

--- DOCME
function Entity:play ()
	if not self.isPlaying and self.m_time < self.m_anim.length then
		self.isPlaying = true

		if self.m_time == 0 then
			self:dispatchEvent{ name = "spriter_event", phase = "began", target = self }
		end
	end
end

--
local function WipeGroup (group)
	for i = group.numChildren, 1, -1 do
		group[i]:removeSelf()
	end
end

--
local function AuxUpdateEntity (entity, from, dt)
	--
	local scale = entity.timeScale or 1

	if scale ~= 1 then
		dt = floor(scale * dt + .5)
	end

	local to = from + dt

	--
	local anim = entity.m_anim
	local mainline = anim.mainline

	local ki = entity.m_index or 1

  -- Find the current key frame index in mainline
	for i = ki, #mainline do
		local key = mainline[i]
		local time = key.time

		if to < time then
			break
		elseif from >= time and entity.m_index ~= ki then
			--
			-- Sounds?
		end

		ki = i
	end

	-- Make all objects invisible
	-- In the interpolation step, those that should be will be set to visible again
	local objects = entity.m_objects
	for i = 1, objects.numChildren do
		objects[i].isVisible = false
	end

	-- Interpolate up to current key
	local key = mainline[ki]
	local bones = key.bone_ref
  for n, bone_data in ipairs(bones) do
    object.Interpolate(entity, bone_data, to)
  end
	local objects = key.object_ref
	for n, object_data in ipairs(objects) do
		if object_data.key then
			object.Interpolate(entity, object_data, to)
		end
	end

	-- If the key switched, remove any transients and add new ones.
	-- TODO: Can these include sounds? Then what?
	if ki ~= entity.m_index then
		local transients = entity.m_transients

		WipeGroup(transients)

		for _, object_data in ipairs(mainline[ki]) do
			if object_data.object_type then
				-- TRANSIENT!
			end
		end
	end

	--
	entity.m_index = ki
	entity.m_time = to

	if to >= anim.length then
		entity:pause()

		entity:dispatchEvent{ name = "spriter_event", phase = "ended", target = entity } -- todo: loop, bounce
	end
end

--
local function Prepare (entity, anim_id)
	local anim = entity.m_animations[anim_id]

	entity.m_anim = anim
	entity.m_index = nil
	entity.m_time = 0

	AuxUpdateEntity(entity, 0, 0)

	entity:pause()
end

--- DOCME
-- @string name
function Entity:setSequence (name)
	self.sequence = name

	-- TODO: Cancel sounds?
	WipeGroup(self.m_objects)
	WipeGroup(self.m_transients)

	Prepare(self, self.m_animations._name[name])
end

--

--- DOCME
-- @pgroup parent
-- @string name
-- @treturn pobject X
function EntityFactory:New (parent, name)
	local entity = display.newGroup()

	--
	if type(parent) == "string" then
		name, parent = parent
	elseif parent then
		parent:insert(entity)
	end

	--
	local id = utils.IDFromNameInLUT(self.entity, name) or 1

	entity.m_animations = self.entity[id]
	entity.m_data = self
	entity.m_objects = display.newGroup()
	entity.m_transients = display.newGroup()

  entity:insert(entity.m_objects)
  entity:insert(entity.m_transients)

	-- Install methods.
	for k, v in pairs(Entity) do
		entity[k] = v
	end

	-- Assign time = 0 properties, using first animation.
	Prepare(entity, 1)

	--
	if #LiveEntities == 0 then
		LiveEntities.time = 0

		Runtime:addEventListener("enterFrame", LiveEntities)
	end

	LiveEntities[#LiveEntities + 1] = entity

	return entity
end

--
function LiveEntities:enterFrame (event)
	local last = self.time or event.time
	local dt = event.time - last

	for i = #self, 1, -1 do
		local entity = self[i]

		--
		if entity.parent then
			if entity.isPlaying then
				local from = entity.m_time

				AuxUpdateEntity(entity, from, dt)
			end

		--
		else
			local n = #self

			self[i] = self[n]
			self[n] = nil
		end
	end

	--
	if #self == 0 then
		Runtime:removeEventListener("enterFrame", self)
	else
		self.time = event.time
	end
end

-- Export the module.
return M