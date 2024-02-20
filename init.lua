
narrator = {}

-- list all converted files in stories/*.lua here:
-- (in order to convert files from .ink to .lua, use ink2lua.lua!)
narrator.book_list = {"game"}

narrator.modpath = minetest.get_modpath("narrator")

narrator.classic = dofile(narrator.modpath..'/narrator/libs/classic.lua')
narrator.lume = dofile(narrator.modpath..'/narrator/libs/lume.lua')
narrator.enums = dofile(narrator.modpath..'/narrator/enums.lua')
narrator.list_mt = dofile(narrator.modpath..'/narrator/list/mt.lua')

local classic = narrator.classic
local lume = narrator.lume
local enums = narrator.enums
local list_mt = narrator.list_mt


-- Dependencies
local modpath = minetest.get_modpath("narrator")

--local narrator = dofile(modpath.."/narrator/narrator.lua")
local Story = dofile(modpath.."/narrator/story.lua")

local start_choose_book = "Please select a story:\n"
-- Require a parsed and saved before book
local book_data = {}
local initial_book_list = {}
-- read the books
for i, b in ipairs(narrator.book_list) do
	book_data[i] = dofile(modpath.."/stories/"..narrator.book_list[i]..".lua")
	initial_book_list[i] = tostring(i)..") "..tostring(narrator.book_list[i])
end

-- -- Start observing the Ink variable 'x'
-- story:observe('x', function(x) print('The x did change! Now it\'s ' .. x) end)

-- -- Bind local functions to call from ink as external functions
-- story:bind('beep', function() print('Beep! 😃') end)
-- story:bind('sum', function(x, y) return x + y end)


local player_data = {}

local ink_process_answer = function(story, text, options, selected_option)
	if(not(options) or type(options) ~= "table") then
		options = {}
	end
	local nr = -1
	if(#options > 0 and selected_option and selected_option ~= "") then
		-- validate input
		nr = tonumber(selected_option)
		if(not(nr) or nr < 0 or nr > #options or not(options[nr])) then
			nr = -1
		end
	end

	-- repeat the last shown text to the player
	if(nr == -1) then
		return {story = story, text = text, options = options}
	end

	if(story) then
		-- Send an answer to the story to generate new paragraphs
		story:choose(nr)
	end

	-- update the text
	text = ''
	if(not(story) or not(story:can_continue())) then
		if(nr == -1) then
			return {story   = nil,
				text    = start_choose_book,
				options = initial_book_list}
		end
		story = Story(book_data[nr])
		story:begin()
		text = '--- Game started ---\n'
	end

	-- Get current paragraphs to output
	local paragraphs = story:continue()

	for _, paragraph in ipairs(paragraphs) do
		text = text..paragraph.text

		-- You can handle tags as you like, but we attach them to text here.
		if paragraph.tags then
			text = text .. ' #' .. table.concat(paragraph.tags, ' #')
		end

		text = text.."\n"
	end

	-- If there is no choice, it seems the game is over
	if not story:can_choose() then
		return {story   = nil,
			text    = text.."\n--- Game over ---\n"..start_choose_book,
			options = initial_book_list}
	end

	-- Get available choices and update options
	options = {}
	local choices = story:get_choices()
	for i, choice in ipairs(choices) do
		options[i] = tostring(i)..') '..tostring(choice.text)
	end
	return {story = story, text = text, options = options}
end


minetest.register_chatcommand( 'ink', {
	description = "Lets you interact with an ink game.\n"..
		"Parmeters: [<number of the answer you want to select>]\n"..
		"Example:   /ink 3     selects answer no. 3\n"..
		"           /ink       shows you text and choices again",
	privs = {interact = true},
	func = function(pname, param)
		if(not(player_data[pname])) then
			player_data[pname] = {
				text    = start_choose_book,
				options = initial_book_list}
		end
		local data = player_data[pname]
		data = ink_process_answer(data.story, data.text, data.options, param)
		player_data[pname] = data
		minetest.chat_send_player(pname,
				tostring(data.text).."\n"..
				table.concat(data.options or {}, "\n"))
	end
})



-- integration into yl_speak_up
if(not(minetest.get_modpath("yl_speak_up"))) then
	return
end


local old_fun = yl_speak_up.generate_next_dynamic_dialog
-- the dialog will be modified for this player only:
-- (pass on all the known parameters in case they're relevant):
-- 	called from yl_speak_up.get_fs_talkdialog(..):
yl_speak_up.generate_next_dynamic_dialog = function(player, n_id, d_id, alternate_text, recursion_depth)
	if(not(player)) then
		return
	end
	local pname = player:get_player_name()
	if(not(yl_speak_up.speak_to[pname])) then
		return
	end
	local dialog = yl_speak_up.speak_to[pname].dialog
	if(not(dialog.n_dialogs["d_dynamic"])) then
		dialog.n_dialogs["d_dynamic"] = {}
	end
	-- which dialog did the player come from?
	local prev_d_id = yl_speak_up.speak_to[pname].d_id
	local selected_o_id = yl_speak_up.speak_to[pname].selected_o_id
	-- the text the NPC shall say:
	local prev_answer = "- unknown -"
	local tmp_topic = "- none -"
	if(dialog.n_dialogs[prev_d_id]
	  and dialog.n_dialogs[prev_d_id].d_options
	  and dialog.n_dialogs[prev_d_id].d_options[selected_o_id]
	  and dialog.n_dialogs[prev_d_id].d_options[selected_o_id].o_text_when_prerequisites_met) then
		prev_answer = dialog.n_dialogs[prev_d_id].d_options[selected_o_id].o_text_when_prerequisites_met
		tmp_topic   = dialog.n_dialogs[prev_d_id].d_options[selected_o_id].tmp_topic
	end

	-- new: ink_game
	if(tmp_topic and string.sub(tmp_topic, 1, 9) == "ink_game_") then
		local selected_answer = tonumber(string.sub(tmp_topic, 10)) or 0
		-- make sure we have data stored for the player:
		if(not(player_data[pname])) then
			player_data[pname] = {
				text    = start_choose_book,
				options = initial_book_list}
		end
		local data = player_data[pname]
		-- get the next output from the ink game runtime:
		data = ink_process_answer(data.story, data.text, data.options, selected_answer)
		player_data[pname] = data

		local new_text = data.text
		local answers = {}
		local topics = {}
		for i, v in ipairs(data.options or {}) do
			answers[i] = data.options[i]
			topics[i] = "ink_game_"..tostring(i)
		end
		answers[#answers + 1] = "Leave Ink game."
		topics[ #topics  + 1] = "back_from_ink_game"

		-- With this answer/option, the player can leave the d_dynamic dialog and return..
		local back_option_o_id = "o_"..tostring(#answers)
		-- ..back to the dynamic dialog:
		local back_option_target_dialog = "d_dynamic"
		-- actually update the d_dynamic dialog
		return yl_speak_up.generate_next_dynamic_dialog_simple(
			player, n_id, d_id, alternate_text, recursion_depth,
			new_text, answers, topics, back_option_o_id, back_option_target_dialog)
	end


	-- pname is the name of the player; d_id is "d_dynamic"
	local new_text = "Hello $PLAYER_NAME$,\n".. -- also: pname
			"you're talking to me, $NPC_NAME$, who has the NPC ID "..tostring(n_id)..".\n"..
			"Previous dialog: "..tostring(prev_d_id)..".\n"..
			"Selected option: "..tostring(selected_o_id).." with the text:\n"..
			"\t\""..tostring(prev_answer).."\".\n"..
			"We have shared "..tostring(dialog.n_dialogs["d_dynamic"].tmp_count or 0)..
				" such continous dynamic dialogs this time.\n"
	-- the answers/options the player can choose from:
	local answers = {"$GOOD_DAY$! My name is $PLAYER_NAME$.",
			"Can I help you, $NPC_NAME$?",
			"Let's play a game together! [->Start Ink game(s)]",
			"What is your name? I'm called $PLAYER_NAME$.", "Who is your employer?",
			"What are you doing here?", "Help me, please!", "This is just a test.",
			"That's too boring. Let's talk normal again!"}
	-- store a topic for each answer so that the NPC can reply accordingly:
	local topics = {"my_name", "help_offered",
			"ink_game_0",
			"your_name", "your_employer", "your_job",
			"help_me", "test", "back"}
	-- react to the previously selected topic (usually you'd want a diffrent new_text,
	-- answers and topics based on what the player last selected; this here is just for
	-- demonstration):
	if(tmp_topic     == "my_name") then
		new_text = new_text.."Pleased to meet you, $PLAYER_NAME$!"
	elseif(tmp_topic == "help_offered") then
		new_text = new_text.."Thanks! But I don't need any help right now."
	elseif(tmp_topic == "your_name") then
		new_text = new_text.."Thank you for asking for my name! It is $NPC_NAME$."
	elseif(tmp_topic == "your_employer") then
		new_text = new_text.."I work for $OWNER_NAME$."
	elseif(tmp_topic == "your_job") then
		new_text = new_text.."My job is to answer questions from adventurers like yourself."
	elseif(tmp_topic == "help_me") then
		new_text = new_text.."I'm afraid I'm unable to help you."
	elseif(tmp_topic == "test") then
		new_text = new_text.."Your test was successful. We're talking."
	elseif(tmp_topic == "back_from_ink_game") then
		new_text = new_text.."Hope you enjoyed our Ink game!"
	else
		new_text = new_text.."Feel free to talk to me! Just choose an answer or question."
	end
	-- With this answer/option, the player can leave the d_dynamic dialog and return..
	local back_option_o_id = "o_"..tostring(#answers)
	-- ..back to dialog d_1 (usually the start dialog):
	local back_option_target_dialog = "d_1"
	-- store some additional values:
	if(d_id ~= "d_dynamic" or not(dialog.n_dialogs["d_dynamic"].tmp_count)) then
		dialog.n_dialogs["d_dynamic"].tmp_count = 0
	end
	dialog.n_dialogs["d_dynamic"].tmp_count = dialog.n_dialogs["d_dynamic"].tmp_count + 1
	-- actually update the d_dynamic dialog
	return yl_speak_up.generate_next_dynamic_dialog_simple(
			player, n_id, d_id, alternate_text, recursion_depth,
			new_text, answers, topics, back_option_o_id, back_option_target_dialog)
end

