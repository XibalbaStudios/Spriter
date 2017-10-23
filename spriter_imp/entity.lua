--- Spriter entity logic.

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
local ipairs = ipairs
local tonumber = tonumber

-- Modules --
local mainline = require("spriter_imp.mainline")
local timeline = require("spriter_imp.timeline")

-- Exports --
local M = {}

--
local function AddVars (tracks, arr, oname)
	for i = 1, #(arr or "") do
		local info = arr[i]

		tracks = tracks or {}

		tracks[#tracks + 1] = {
			line = "varline", id = info.id, object = oname, type = info.type,
			default = info.type == "string" and info.default or tonumber(info.default)
		}
	end

	return tracks
end

--
local AddLine = {}

function AddLine:soundline (track)
	-- TODO
end

function AddLine:tagline (track, entity)
	-- TODO
	-- add first key if missing
end

function AddLine:varline (track)
	--
	-- see varline, etc.
end

--
local function AddToLine (anim_data, tracks, md, entity, object)
	for i = 1, #(tracks or "") do
		local track = tracks[i]

		if track.line == md.label and track.id == md.id and track.object == object then
			AddLine[track.line](anim_data, track, entity)

			break
		end
	end
end

--- DOCME
-- @ptable entity
function M.Load (entity, data)
	local entity_data = {}

	-- Extract data for animations (only type of child for entities)
	local tracks

	for _, anim in ipairs(entity) do
		local label = anim.label

		--
		if label == "obj_info" then
			for _, oi in ipairs(anim) do
				if oi.label == "var_defs" then
					tracks = AddVars(tracks, oi, anim.name)
				end
			end
		elseif label == "var_defs" then
			tracks = AddVars(tracks, anim)
		else
			-- Set properties from xml attributes: looping, length
			local anim_data, bone_refs = { length = tonumber(anim.length), looping = anim.looping ~= "false" }

			-- stub out tracks: 1, ..., eventline?

			-- Iterate over children (one mainline, zero or many timelines)
			for _, timeline_data in ipairs(anim) do
				local anim_type = timeline_data.label

				if anim_type == "mainline" then
					anim_data.mainline = mainline.Load(timeline_data)

					local bone_refs = anim_data.mainline[1].bone_ref

					if bone_refs then
						local bone_table = {}

						for _, bone_data in ipairs(bone_refs) do
							bone_table[#bone_table + 1] = bone_data.timeline
						end

						anim_data.bone_table = bone_table
					end
				elseif anim_type == "timeline" then
					anim_data[#anim_data + 1] = timeline.Load(timeline_data, data)
				elseif anim_type == "eventline" then
					local eline = {}

					for _, eventline_data in ipairs(timeline_data) do
						local elem_type = eventline_data.label

						if elem_type == "key" then
							--
						elseif elem_type == "meta" then
							for _, md in ipairs(eventline_data) do
							--	AddToLine(anim_data, tracks, md, eventline_data)
							end
						end
					end
					
					-- TODO: add keys...

					anim_data.eventline = eline -- TODO, similar to meta just below...
				elseif anim_type == "meta" then
					for _, md in ipairs(timeline_data) do
						AddToLine(anim_data, tracks, md, entity)
					end
				end
			end

			entity_data[#entity_data + 1] = anim_data

			--
			local name = anim.name

			if name then
				local names = entity_data.names or {}

				names[name] = #entity_data

				entity_data.names = names
			end
		end
	end

	return entity_data
end

-- Export the module.
return M