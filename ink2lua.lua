-- story.lua needs access to the libraries; Minetest doesn't support require:
narrator = {}

narrator.classic = require('narrator.libs.classic')
narrator.lume = require('narrator.libs.lume')
narrator.enums = require('narrator.enums')
narrator.list_mt = require('narrator.list.mt')

local classic = narrator.classic
local lume = narrator.lume
local enums = narrator.enums
local list_mt = narrator.list_mt


-- Dependencies
local narratorI = require('narrator.narrator')

if(not(arg) or not(arg[1])) then
	print("Please provide the name of the .ink file you want to convert!")
	return
end
local file_name = arg[1]
if(string.sub(file_name, string.len(file_name)-3) == '.ink') then
	file_name = string.sub(file_name, 1, string.len(file_name)-4)
end
print("Trying to convert file stories/"..tostring(file_name)..".ink ...")
-- Parse a book from the Ink file and save as module 'stories.game.lua'
local book = narratorI.parse_file('stories.'..tostring(file_name), { save = true })
if(book) then
	print("Success. Converted into stories/"..tostring(file_name)..".lua.")
else
	print("Failed to convert file.")
end
