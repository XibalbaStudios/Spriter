--- Some common Spriter utilities.

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
local print = print
local setmetatable = setmetatable
local tonumber = tonumber
local type = type
local vdump = vdump

-- Exports --
local M = {}

--- DOCME
-- @ptable t
-- @param data
-- @ptable props
function M.AddByID (t, data, props)
	t[M.Index(props)] = data
end

--- DOCME
-- @ptable lut
-- @param data
-- @ptable props
function M.AddToLUT (lut, data, props)
	local index = M.Index(props)

	lut[index] = data
	lut._name[props.name] = index
end

--
local function AuxChildren (t, i)
	local child = t[i + 1]

	if child then
		return i + 1, child, child.properties
	end
end

-- --
local function NoOp () end

--- DOCME
-- @ptable t
-- @treturn iterator X
function M.Children (t)
	if t.child then
		return AuxChildren, t.child, 0
	else
		return NoOp
	end
end

--- DOCME
-- @string what
-- @ptable t
-- @int index
function M.Dump (what, t, index)
	print(what, index)

	local tdup = {}

	for k, v in pairs(t) do
		tdup[k] = (type(v) ~= "table" or k == "properties") and v or "TABLE"
	end

	vdump(tdup)
end

-- --
local FuncsMT = {
	__call = function(t, elem, data, arg1, arg2)
		return t[elem.name](elem, data, arg1, arg2)
	end,
	__index = function(_, key)
		print(key .. " not yet exported / implemented")
	end
}

--- DOCME
-- @treturn table Y
function M.FuncTable ()
	return setmetatable({}, FuncsMT)
end

--- DOCME
-- @ptable props
-- @string key
-- @treturn uint X
function M.Index (props, key)
	return tonumber(props[key or "id"]) + 1
end

--- DOCME
-- @treturn table Z
function M.NewLUT ()
	return { _name = {} }
end

-- Export the module.
return M