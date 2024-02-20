--
-- A simple command-line game example
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

local game_name = 'game'
if(arg and arg[1]) then
	game_name = arg[1]
end
print("Running game \""..tostring(game_name)..".ink\"...")

-- Parse a book from the Ink file and save as module 'stories.game.lua'
local book = narratorI.parse_file('stories.'..tostring(game_name), { save = true })
-- Require a parsed and saved before book
--local book = require('stories.game')

-- Init a story from the book
local story = narratorI.init_story(book)

-- Start observing the Ink variable 'x'
story:observe('x', function(x) print('The x did change! Now it\'s ' .. x) end)

-- Bind local functions to call from ink as external functions
story:bind('beep', function() print('Beep! 😃') end)
story:bind('sum', function(x, y) return x + y end)

-- Begin the story
story:begin()

print('--- Game started ---\n')

while story:can_continue() do

  -- Get current paragraphs to output
  local paragraphs = story:continue()

  for _, paragraph in ipairs(paragraphs) do
    local text = paragraph.text

    -- You can handle tags as you like, but we attach them to text here.
    if paragraph.tags then
      text = text .. ' #' .. table.concat(paragraph.tags, ' #')
    end

    -- Output text to the player
    print(text)
  end

  -- If there is no choice, it seems the game is over
  if not story:can_choose() then break end
  print('')

  -- Get available choices and output them to the player
  local choices = story:get_choices()
  for i, choice in ipairs(choices) do
    print(i .. ') ' .. choice.text)
  end

  -- Read the choice from the player input
  local answer = tonumber(io.read()) or 0
  print('')

  -- Send an answer to the story to generate new paragraphs
  story:choose(answer)
end

print('\n--- Game over ---')
