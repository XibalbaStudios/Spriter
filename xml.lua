---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
--
-- xml.lua - XML parser for use with the Corona SDK.
--
-- version: 1.1
--
-- CHANGELOG:
--
-- 1.1 - Fixed base directory issue with the loadFile() function.
--
-- NOTE: This is a modified version of Alexander Makeev's Lua-only XML parser
-- found here: http://lua-users.org/wiki/LuaXml
--
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Standard library imports --
local char = string.char
local error = error
local find = string.find
local gsub = string.gsub
local open = io.open
local print = print
local remove = table.remove
local sub = string.sub
local tonumber = tonumber

-- Corona globals --
local system = system

-- Exports --
local M = {}

--- DOCME
function M.newParser ()
	local XmlParser = {}

	local function Decimal (h) 
		return char(tonumber(h, 16)) 
	end

	local function Hexadecimal (h) 
		return char(tonumber(h, 16)) 
	end
	
	function XmlParser:FromXmlString(value)
		value = gsub(value, "&#x([%x]+)%;", Hexadecimal)
		value = gsub(value, "&#([0-9]+)%;", Decimal)
		value = gsub(value, "&quot;", "\"")
		value = gsub(value, "&apos;", "'")
		value = gsub(value, "&gt;", ">")
		value = gsub(value, "&lt;", "<")
		value = gsub(value, "&amp;", "&")

		return value
	end

	-- --
	local Arg

	local function AddArg (w, _, a)
		Arg[w] = XmlParser:FromXmlString(a)
	end

	function XmlParser:ParseArgs (s, label)
		Arg = { label = label }

		gsub(s, "([_%w]+)=([\"'])(.-)%2", AddArg)

		s, Arg = Arg -- co-opt s to avoid new declaration

		return s
	end

	function XmlParser:ParseXmlText (xmlText)
		local stack, top = {}, {}

		stack[#stack + 1] = top

		local i, j, ni, c, label, xarg, empty = 1, 1

		while true do
			ni, j, c, label, xarg, empty = find(xmlText, "<(%/?)([_%w:]+)(.-)(%/?)>", i)

			if not ni then break end

			local text = sub(xmlText, i, ni - 1)

			if not find(text, "^%s*$") then
				top.value = (top.value or "") .. self:FromXmlString(text)
			end

			if empty == "/" then  -- empty element tag
				top[#top + 1] = self:ParseArgs(xarg, label)
			elseif c == "" then   -- start tag
				top = self:ParseArgs(xarg, label)
				stack[#stack + 1] = top   -- new level
			else  -- end tag
				local toclose = remove(stack)  -- remove top

				top = stack[#stack]

				if #stack < 1 then
					error("XmlParser: nothing to close with " .. label)
				end

				if toclose.label ~= label then
					error("XmlParser: trying to close " .. toclose.label .. " with " .. label)
				end

				top[#top + 1] = toclose
			end

			i = j + 1
		end

		local text = sub(xmlText, i)

		if not find(text, "^%s*$") then
			stack[#stack].value = (stack[#stack].value or "") .. self:FromXmlString(text)
		end

		if #stack > 1 then
			error("XmlParser: unclosed " .. stack[#stack].name)
		end

		return stack[1][1]
	end

	function XmlParser:loadFile (xmlFilename, base)
		base = base or system.ResourceDirectory

		local path = system.pathForFile(xmlFilename, base)
		local hFile, err = open(path, "r")

		if hFile and not err then
			local xmlText = hFile:read("*a") -- read file content

			hFile:close()

			return self:ParseXmlText(xmlText), nil
		else
			print(err)

			return nil
		end
	end

	return XmlParser
end

-- Export the module.
return M