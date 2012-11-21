--- Spriter folder logic.

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
local tonumber = tonumber

-- Modules --
local utils = require("spriter_imp.utils")

--
local function File (file, data, folder)
	local ftype = file.type or "image"
	local file_data = { type = ftype }

	if ftype == "image" or ftype == "atlas_image" then
		file_data.pivot_x, file_data.pivot_y = tonumber(file.pivot_x) or 0, tonumber(file.pivot_y) or 0

		if ftype == "image" then
			-- DoImage
		else
			-- Stuff
		end
	else
		-- Stuff
	end

	return file_data
end

--
return function(folder, data, props)
	local folders, folder_data = data._folders or utils.NewLUT(), utils.NewLUT()

	for _, file, fprops in utils.Children(folder) do
--utils.Dump("FILE", file, _)
--vdump(file)
--assert(file.name == "file") ??
		local file_data = File(file, data, folder_data)

		utils.AddToLUT(folder_data, file_data, fprops)
	end

	--
	utils.AddToLUT(folders, folder_data, props)

	data._folders = folders
end