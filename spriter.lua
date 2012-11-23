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
local TopLevel = utils.FuncTable()

TopLevel.entity = entity.LoadPass
TopLevel.folder = folder.LoadPass

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
	if file:sub(-5) ~= ".scml" then
		file = file .. ".scml"
	end

	--
	local t = Parser:loadFile(file, base)
	local data = { file = file, base = base or system.ResourceDirectory	}

	for _, child, cprops in utils.Children(t) do
		local cdata = TopLevel(child, cprops, data[child.name])

		if cdata then
			local ctable = data[child.name] or utils.NewLUT()

			utils.AddToLUT(ctable, cdata, cprops)

			data[child.name] = ctable
		end
	end

	--
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
	self.m_paused = true
end

--- DOCME
function Entity:play ()
	if self.m_time < self.m_anim.length then
		self.m_paused = false
	end
end

--
local function WipeGroup (group)
	for i = group.numChildren, 1, -1 do
		group:removeSelf()
	end
end

--
local function AuxUpdateEntity (entity, from, to)
	local anim = entity.m_anim
	local mainline = anim.mainline
	local ki = entity.m_index or 1

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

	--
	-- Interpolate up to current key
	for _, key in ipairs(mainline[ki]) do
		for _, object_data in ipairs(key) do
			if object_data.key then
				object.Interpolate(entity, object_data, to)
			end
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

	--
	if to >= anim.length then
		entity:pause()
	end
end

--
local function Prepare (entity, anim_id)
	local anim = entity.m_data[anim_id]

	entity.m_anim = anim
	entity.m_index = nil
	entity.m_time = 0

	local objects = entity.m_objects

	for _ = 1, #anim do
		objects:insert(display.newGroup())
	end

	AuxUpdateEntity(entity, 0, -1)

	entity:pause()
end

--- DOCME
-- @string name
function Entity:setSequence (name)
	-- TODO: Cancel sounds?
	WipeGroup(self.m_objects)
	WipeGroup(self.m_transients)

	Prepare(self, self._name[name])
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
	local data = self.entity[id]

	-- Load up images.

	--
	entity.m_data = data
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

	return entity
end

--
function LiveEntities:UpdateEntities (event)
	local last = self.time or event.time
	local dt = event.time - last

	for i = #self, 1, -1 do
		local entity = self[i]

		--
		if entity.parent then
			if not entity.m_paused then -- CONSIDER: if not entity.isVisible?
				local from = entity.m_time

				AuxUpdateEntity(entity, from, from + dt)
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