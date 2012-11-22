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

-- Modules --
local entity = require("spriter_imp.entity")
local folder = require("spriter_imp.folder")
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

	return setmetatable(data, EntityFactory)
--[[
local path = system.pathForFile( "myfile.txt", system.DocumentsDirectory )
local file = io.open( path, "w" )
require("var_dump").Print(data, function(s, ...)
	file:write(s:format(...), "\n")
end)
io.close( file )
--]]

-- Could check for "Corona-fied" file, i.e. already processed as so...
end

--- DOCME
function Entity:pause ()
	self.m_paused = true
end

--- DOCME
function Entity:play ()
	self.m_paused = false
end

--
local function AuxUpdateEntity (entity, from, to)
	--[[
		with mainline in ANIMATION:
			for object in OBJECTS do
				Hide past transients
				Play sounds? (seek into if necessary)
				Show valid transients, interpolated
			end

			for ref in OBJECT_REFS do
				Do each intermediate key
				Sounds?
				Interpolate up to current key
			end
		end
	]]
end

--
local function Prepare (entity, anim)
	entity.m_anim = anim

	AuxUpdateEntity(entity, 0, 0)

	entity:pause()
end

--- DOCME
-- @string name
function Entity:prepare (name)
	-- Hide any transients
	-- Cancel sounds?

	Prepare(self, self._name[name])
end

--

--- DOCME
-- @pgroup group
-- @string name
-- @treturn pobject X
function EntityFactory:New (group, name)
	local entity = display.newGroup()

	group:insert(entity)

	--
	local id = utils.IDFromNameInLUT(self.entity, name) or 1
	local data = self.entity[id]

	--
	-- load up images, time = 0 properties

	--
	entity.m_data = data
	entity.m_time = 0

	--
	for k, v in pairs(Entity) do
		entity[k] = v
	end

	--
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