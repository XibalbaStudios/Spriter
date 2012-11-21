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

-- Modules --
local entity = require("spriter_imp.entity")
local folder = require("spriter_imp.folder")
local utils = require("spriter_imp.utils")
local xml = require("xml")

-- Corona globals --
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

--- DOCME
-- @pgroup group
-- @string file
-- @param base
function M.New (group, file, base)
	if file:sub(-5) ~= ".scml" then
		file = file .. ".scml"
	end

	--
	local t = Parser:loadFile(file, base)
	local data = { _file = file, _base = base or system.ResourceDirectory }

	for _, child, cprops in utils.Children(t) do
		TopLevel(child, data, cprops)
	end

	--
	entity.Process(data)
	folder.Process(data)

--	vdump(t)
--	vdump(data)
end

-- Export the module.
return M