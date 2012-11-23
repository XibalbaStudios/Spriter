--- Spriter demo driver.

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
local print = print

-- Modules --
local spriter = require("spriter")
local var_dump = require("var_dump")

--- Helper to print formatted argument.
-- @string s Format string.
-- @param ... Format arguments.
function printf (s, ...)
	print(s:format(...))
end

-- Install printf as the default var dump routine.
var_dump.SetDefaultOutf(printf)

-- Checks for vdump --
local Checks

--- Helper to dump generic variable.
-- @param var Variable to dump.
-- @param name If provided, the dump will check if it has been called with this name
-- before; if _limit_ has been reached, dumps will be ignored.
-- @uint limit Maximum number of times to allow a dump with _name_; if absent, 1.
function vdump (var, name, limit)
	if name then
		Checks = Checks or {}

		local check = Checks[name] or 0

		if check >= (limit or 1) then
			return
		else
			Checks[name] = check + 1
		end
	end

	var_dump.Print(var)
end

local sf = spriter.NewFactory("monster/Example")

local sp = sf:New()

sp:setSequence("Posture")

sp:play()

sp.x, sp.y = 200, 500

transition.to(sp, { time = 2000, x = 250, y = 700 })