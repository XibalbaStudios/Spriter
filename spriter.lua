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
local error = error
local floor = math.floor
local find = string.find
local ipairs = ipairs
local open = io.open
local pairs = pairs
local setmetatable = setmetatable
local tostring = tostring
local type = type

-- Modules --
local entity = require("spriter_imp.entity")
local folder = require("spriter_imp.folder")
local object = require("spriter_imp.object")
local xml = require("xml")

-- Corona globals --
local display = display
local system = system

-- Exports --
local M = {}

-- --
local Parser = xml.newParser()

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
-- TODO: opts? (sound policies, install shaders, etc.)
	-- Parse the xml data
	local t = Parser:loadFile(file, base)
--[[
print("STRUCTURE #1")
vdump(t)
print("")
--]]
	-- Create the table that will hold all the data for this sprite
	-- Initialize with file, folder and path
	local data = { file = file, folder = {}, base = base or system.ResourceDirectory	}

	if file:find("/") then
		data.path = file:gsub("/.*$", "") .. "/"
		data.path = data.path:gsub("\\", "/")
	else
		data.path = ""
	end

	-- Iterate over top-level tags (folders and entities)
	local folders

	for _, top_level_obj in ipairs(t) do
		local label = top_level_obj.label

		if label == "entity" then
			data[#data + 1] = entity.Load(top_level_obj, data)
		elseif label == "folder" then
			data.folder[#data.folder + 1] = folder.Load(top_level_obj)
		elseif label == "tag_list" then
			local tag_data = {}

			for _, tag in ipairs(top_level_obj) do
				tag_data[#tag_data + 1] = { name = tag.name, value = false }
			end

			data.tags = tag_data
		end
	end
--[[
print("STRUCTURE 2")
vdump(data)
print("")
--]]
	return setmetatable(data, EntityFactory)
end

--- DOCME
function Entity:enumObjects (func)
	--
end

--- DOCME
function Entity:getBox (name)
	--
end

--- DOCME
function Entity:getPoint (name)
	--
end

--- DOCME
function Entity:getSound (name)
	--
end

--- DOCME
function Entity:getSprite (name)
	--
end

--- DOCME
function Entity:getVariableValue (name, object)
	--
end

-- DOCME
function Entity:isTagSet (name)
	--
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
local function AuxUpdateEntity (entity, from, dt)
	--
	local scale = entity.timeScale or 1

	if scale ~= 1 then
		dt = floor(scale * dt + .5)
	end

	local to = from + dt

	--
	local anim = entity.m_anim
	local ki, length, looping = entity.m_index or 1, anim.length, anim.looping
	local mainline = anim.mainline

	-- Find the current key frame index in mainline
	repeat
		local loop_again

		for i = ki, #mainline do
			local key = mainline[i]
			local time = key.time

			if to < time then
				loop_again = false

				break
			elseif from >= time and entity.m_index ~= ki then
				--
				-- Sounds?
				-- Events, variables, tags
			end

			ki = i
		end

		if looping then
			if to < length then
				loop_again = false
			else
				ki, loop_again, to = 1, to > length, to - length
			end
		end
	until not loop_again
	-- TODO: make this a series of such loops, mainline being first
	-- Each with m_index inside (set to 1 on setting animation?)
	-- These will be varline, eventline, etc.
	-- TODO: eventlines might need special attention, if vars etc. need to be in sync?

	-- Make all objects invisible
	-- In the interpolation step, those that should be will be set to visible again
	for i = 1, entity.numChildren do
		entity[i].isVisible = false
	end

	-- Interpolate up to current key
	local key = mainline[ki]
	local bones = key.bone_ref
	local llen = looping and length

	for i = 1, #(bones or "") do
		object.Interpolate(entity, bones[i], to, llen)
	end

	local objects = key.object_ref

	for i = 1, #(objects or "") do
		object.Interpolate(entity, objects[i], to, llen)
	end

	--
	entity.m_index = ki
	entity.m_time = to

	if to >= length then -- TODO: might be looping but land exactly...
		entity:pause()

		entity:dispatchEvent{ name = "spriter_event", phase = "ended", target = entity }
	end

	object.Done()
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
	local names = self.m_data[1].names
	local anim = names and names[name] or 1--self.m_animations[names and names[name]]

	if anim then
		self.sequence = name

		-- TODO: Cancel sounds?
		for i = self.numChildren, 1, -1 do
			self[i]:removeSelf()
		end

		Prepare(self, anim)
	else
		error(("Entity has no such sequence: `%s`"):format(tostring(name)))
	end
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
	entity.m_animations = self[1]
	entity.m_data = self

	-- Install methods.
	for k, v in pairs(Entity) do
		entity[k] = v
	end

	-- Assign time = 0 properties, using first animation.
	Prepare(entity, 1)

	--
	if #LiveEntities == 0 then
		LiveEntities.time = nil

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