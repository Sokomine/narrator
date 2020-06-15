--
-- Bot for story playing

local Bot = { }

--- Play a story by bot
-- @param story Story: a story instance
-- @param instructor function: function that will be return the answer index
-- @param params.print bool: print a game log to console or not, false by default
-- @return string: a log of the game
function Bot.play(story, instructor, params)
  local params = params or { print = false }

  local log = { }
  local step = 1
  
  local function output(text)
    if params.print then print(text) end
    table.insert(log, text)
  end  
  
  story:begin()
  
  while story:canContinue() do
    local paragraphs = story:continue()
    for _, paragraph in ipairs(paragraphs) do
      local text = paragraph.text or ''
      if paragraph.tags then
        text = text .. ' #' .. table.concat(paragraph.tags, ' #')
      end
      output(text)
    end
    
    if not story:canChoose() then break end

    local choices = story:getChoices()
    local answer = instructor(choices, step)
    step = step + 1

    -- Check for a signal to emergency exit
    if answer == -1 then
      return nil
    end

    output('')
    for i, choice in ipairs(choices) do
      local prefix = (i == answer and '>' or i) .. ') '
      local text = prefix .. choice.title
      output(text)
    end
    output('')
  
    story:choose(answer)
  end

  return table.concat(log, '\n')
end

return Bot