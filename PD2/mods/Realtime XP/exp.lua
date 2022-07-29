local Void_UI = VoidUI and VoidUI.loaded
local Custom_HUDs = Void_UI
blt.xaudio.setup()
local buff = XAudio.Buffer
local src = XAudio.Source
local PD2old = buff:new(ModPath .. "PD2.ogg")
local PDTH = buff:new(ModPath .. "PDTH.ogg")
if string.lower(RequiredScript) == "lib/managers/localizationmanager" then
	Hooks:Add("LocalizationManagerPostInit", "RealtimeXP_loc", function(...)				
		LocalizationManager:add_localized_strings({
			menu_RealtimeXP_name = "Realtime XP",
			RXP_allow_bottom_tab = "Tab XP info",
			RXP_allow_bottom_tab_desc = "Show information about current reputation level, amount of exp gained and infamy pool.",
			RXP_allow_save = "Progress Save",
			RXP_allow_save_desc = "Keep your progress saved every time you get experience. Disable it if you getting stutters and freezes.",
			RXP_selected_jingle = "Level Up jingle",
			RXP_selected_jingle_desc = "Select level up sound.",
			menu_reached_level_title = "Level Up!",
			menu_reached_level_desc = "Reputation Level Reached",
			menu_current_level_reached = "Reputation Level Reached:   $CURRENT_LVLUP",
			hud_total_xp_gained = "Total XP gained: $XP",
			hud_total_xp_left = "Next rank in: ##$XP##",
			hud_level_ups = "Reputation Levels Reached: $LEVELS",
			hud_ingame_rewarded_xp = "XP gained: $REWARD",
			rxp_selected_jingle_0 = "None",
			rxp_selected_jingle_1 = "Default",
			rxp_selected_jingle_2 = "Aldstone",
			rxp_selected_jingle_3 = "Level Up",
			rxp_selected_jingle_4 = "Side Job (Long)",
			rxp_selected_jingle_5 = "Side Job (Short)",
			rxp_selected_jingle_6 = "Infamy",
			rxp_selected_jingle_7 = "Infamy (Old)",
			rxp_selected_jingle_8 = "Level Up (PAYDAY: The Heist)",
			rxp_selected_jingle_9 = "Current Infamy Stinger",
			
		})
			
		if Idstring("russian"):key() == SystemInfo:language():key() then
			LocalizationManager:add_localized_strings({
				RXP_allow_bottom_tab = "Информация об опыте во кладке TAB",
				RXP_allow_bottom_tab_desc = "Показывает информацию от текущем уровне, количестве опыта, количества полученых уровней и резверве бесславия.",
				RXP_allow_save = "Сохранение прогресса",
				RXP_allow_save_desc = "Сохраняет ваш прогресс каждый раз когда вы получаете опыт. Отключить эту опцию если оно вызывает зависания и фризы.",
				RXP_selected_jingle = "Звук поднятия уровня",
				RXP_selected_jingle_desc = "Выбрать звук повышения уровня.",
				menu_reached_level_title = "Уровень получен!",
				menu_reached_level_desc = "Достигнут уровень",
				menu_current_level_reached = "Достигнут уровень репутации:   $CURRENT_LVLUP",
				hud_total_xp_gained = "Всего получено опыта: $XP",
				hud_total_xp_left = "Следующий ранг через: ##$XP##",
				hud_level_ups = "Уровней репутации достигнуто: $LEVELS",
				hud_ingame_rewarded_xp = "Получено опыта: $REWARD",
				rxp_selected_jingle_0 = "Нет",
				rxp_selected_jingle_1 = "По умолчанию",
				rxp_selected_jingle_9 = "Выбранный звук присоединения",
			})
		end
	end)

	_G.RealtimeXP = _G.RealtimeXP or {}
	RealtimeXP._mod_path = RealtimeXP._mod_path or ModPath
	RealtimeXP._setting_path = SavePath .. "realtimexp_save.json"
	RealtimeXP.settings = RealtimeXP.settings or {}
	RealtimeXP.stingers = {
		"stinger_feedback_positive",
		"chill_upgrade_stinger",
		"stinger_levelup",
		"sidejob_stinger_long",
		"sidejob_stinger_short",
		"infamous_stinger_generic"
	}

	function RealtimeXP:Save()
		local file = io.open(self._setting_path, "w+")
		if file then
			file:write(json.encode(self.settings))
			file:close()
		end
	end

	function RealtimeXP:Load()
		local file = io.open(self._setting_path, "r")
		if file then
			for k, v in pairs(json.decode(file:read("*all")) or {}) do
				self.settings[k] = v
			end
			file:close()
		else
			self.settings = {
				allow_bottom_tab = true,
				allow_save = true,
				selected_jingle = 2
			}
			self:Save()
		end
	end

	Hooks:Add("MenuManagerInitialize", "MenuManagerInitialize_RealtimeXP", function(...)
		RealtimeXP:Load()
		
		MenuCallbackHandler.RXP_allow_save_callback = function(self, item)
			RealtimeXP.settings.allow_save = item:value() == "on" and true or false
			RealtimeXP:Save()
		end
		
		MenuCallbackHandler.RXP_allow_bottom_tab_callback = function(self, item)
			RealtimeXP.settings.allow_bottom_tab = item:value() == "on" and true or false
			RealtimeXP:Save()
		end
		
		MenuCallbackHandler.RXP_selected_jingle_callback = function(self, item)
			RealtimeXP.settings.selected_jingle = tonumber(item:value()) or 2
			RealtimeXP:Save()
			
			local jingle = RealtimeXP.settings.selected_jingle
			if jingle == 8 then
				src:new(PD2old)
			elseif jingle == 9 then
				src:new(PDTH)
			elseif jingle == 10 then
				managers.menu:play_join_stinger_by_index(managers.infamy:selected_join_stinger())
			else
				managers.menu:post_event(RealtimeXP.stingers[RealtimeXP.settings.selected_jingle - 1 or 1])
			end
		end
		
		MenuHelper:LoadFromJsonFile(RealtimeXP._mod_path .. "options.json", RealtimeXP, RealtimeXP.settings)
	end)
end
if string.lower(RequiredScript) == "lib/managers/hud/hudchallengenotification" then
	local data = HudChallengeNotification.init
	function HudChallengeNotification:init(title, text, icon, rewards, queue)
		data(self, title, text, icon, rewards, queue)
		if not Custom_HUDs then
			if icon == "level_up_icon" then
				local box = ExtendedPanel:new(self)
				
				box:set_y(20)
				local size = 68
				local player_level_panel = box:panel({
					vertical = "center",
					align = "center",
					name = "player_level_panel",
					y = 10,
					x = 10,
					w = size,
					h = size
				})
				local function exp_ring(color)
					local exp_ring = player_level_panel:bitmap({
						texture = "guis/textures/pd2/endscreen/exp_ring",
						alpha = 0.4,
						texture_rect = {
							16,
							16,
							224,
							224
						},
						w = size,
						h = size,
						color = Color.white
					})
					if color then
						exp_ring:set_alpha(1)
						exp_ring:set_render_template(Idstring("VertexColorTexturedRadial"))
						exp_ring:set_color(color)
					end
				end
				
				exp_ring(Color(text * 0.01, 1, 1))
				exp_ring()
				
				player_level_panel:text({
					vertical = "center",
					align = "center",
					y = 2,
					text = tostring(text),
					font = tweak_data.menu.pd2_massive_font,
					font_size = 29
				})
				local desc = box:text({
					vertical = "center",
					text = managers.localization:to_upper_text("menu_reached_level_desc"),
					font = tweak_data.menu.pd2_medium_font,
					font_size = tweak_data.menu.pd2_medium_font_size,
					y = -10
				})
				desc:set_left(player_level_panel:right() + 10)
			end
		end
	end
	
	Hooks:PostHook(HudChallengeNotification, "close", "RealtimeXP_play_jingle_again", function()
		managers.experience._message_is_active = false
	end)
end
if string.lower(RequiredScript) == "lib/managers/gageassignmentmanager" then
	local data = GageAssignmentManager.present_progress
	function GageAssignmentManager:present_progress(assignment, peer_name)
		data(self, assignment, peer_name)
		DelayedCalls:Add("Delay_for_calculating_xp_from_gage_packs", 0.1, function()
			managers.experience:add_exp()
		end)
	end
end
if string.lower(RequiredScript) == "lib/managers/experiencemanager" then
	function ExperienceManager:add_exp()
		if not self:_instant_xp_allowed() or managers.crime_spree:is_active() then
			return
		end
		
		local total = self:_total_xp()
		local xp_gained = self._total_xp_gained
		if total > xp_gained then
			self:add_instant_xp(total - xp_gained)
		end
	end
	
	Hooks:PostHook(ExperienceManager, "mission_xp_award", "add_mission_xp", function(self)
		self:add_exp()
	end)
	
	Hooks:PostHook(ExperienceManager, "init", "initial_thingies", function(self)
		self._levels_reached = 0
		self._total_xp_gained = 0
		self._message_is_active = false
	end)
	
	function ExperienceManager:_instant_xp_allowed()
		return managers.job:has_active_job()
	end
	
	function ExperienceManager:_total_xp()
		local players = managers.network:session() and managers.network:session():amount_of_alive_players() or 0
		return managers.experience:get_xp_dissected(true, players, not Utils:IsInCustody())
	end
	
	function ExperienceManager:add_instant_xp(xp)
		if not self:_instant_xp_allowed() then
			return
		end
		
		self._total_xp_gained = self._total_xp_gained + xp
		
		managers.experience:add_points(xp, true)
		
		if managers.hud then
			managers.hud:on_ext_inventory_changed()
		end
		
		if _G.RealtimeXP.settings.allow_save then
			MenuCallbackHandler:save_progress()
			managers.savefile._gui_script:set_text(managers.localization:to_upper_text("hud_ingame_rewarded_xp", {REWARD = managers.money:add_decimal_marks_to_string(tostring(xp))}))
		end
	end
	
	function ExperienceManager:level_up_message()
		tweak_data.hud_icons.level_up_icon = {
			texture = "guis/textures/pd2/blackmarket/xp_drop",
			texture_rect = Custom_HUDs and {0, 0, 128, 128} or {128, 128, 128, 128}
		}
		
		if Custom_HUDs then
			local icon = tweak_data.hud_icons
			if level_ups == 5 then
				icon.level_up_icon = icon.Other_H_All_AllLevel005
			elseif level_ups == 10 then
				icon.level_up_icon = icon.Other_H_All_AllLevel010
			elseif level_ups == 25 then
				icon.level_up_icon = icon.Other_H_All_AllLevel025
			elseif level_ups == 50 then
				icon.level_up_icon = icon.Other_H_All_AllLevel050
			elseif level_ups == 75 then
				icon.level_up_icon = icon.Other_H_All_AllLevel075
			elseif level_ups == 100 then
				icon.level_up_icon = icon.Other_H_All_AllLevel100
			end
		end
		
		if managers.hud then
			local text = Custom_HUDs and managers.localization:to_upper_text("menu_current_level_reached", {CURRENT_LVLUP = managers.experience:current_level()}) or managers.experience:current_level()
			managers.hud:custom_ingame_popup_text(
				managers.localization:to_upper_text("menu_reached_level_title"),
				text,
				"level_up_icon"
			)
			
			if not self._message_is_active then
				local jingle = RealtimeXP.settings.selected_jingle
				if jingle == 8 then
					src:new(PD2old)
				elseif jingle == 9 then
					src:new(PDTH)
				elseif jingle == 10 then
					managers.menu:play_join_stinger_by_index(managers.infamy:selected_join_stinger())
				else
					managers.menu:post_event(RealtimeXP.stingers[RealtimeXP.settings.selected_jingle - 1 or 1])
				end
			end
		end
		
		self._message_is_active = true
	end
	
	Hooks:PostHook(ExperienceManager, "_level_up", "get_level_up_message", function(self)
		self._levels_reached = self._levels_reached + 1
		self:level_up_message()
	end)
		
	local data = ExperienceManager.give_experience
	function ExperienceManager:give_experience(xp, force_or_debug)
		local allowed_xp = not self:_instant_xp_allowed() and xp or 0
		if self:_instant_xp_allowed() then
			managers.skilltree:give_specialization_points(xp)
			managers.custom_safehouse:give_upgrade_points(xp)
		end
		return data(self, allowed_xp, force_or_debug)
	end
end
if string.lower(RequiredScript) == "lib/managers/hud/hudstageendscreen" then
	local data = HUDStageEndScreen.update
	function HUDStageEndScreen:update(t, dt)
		data(self, t, dt)
		if managers.experience._total_xp_gained ~= 0 and managers.experience:current_level() < 100 then
			self._lp_xp_gain:set_color(tweak_data.screen_colors.skill_color)
			self._lp_xp_gain:set_text(managers.money:add_decimal_marks_to_string(tostring(managers.experience._total_xp_gained)))
		end
	end
end
if string.lower(RequiredScript) == "lib/managers/hud/newhudstatsscreen" then
	local data = HUDStatsScreen.recreate_right
	function HUDStatsScreen:recreate_right()
		data(self)
		self:exp_progress(self._right)
	end
	
	local data = HUDStatsScreen.on_ext_inventory_changed
	function HUDStatsScreen:on_ext_inventory_changed()
		data(self)
		self:recreate_right()
	end

	function HUDStatsScreen:_animate_text_pulse(text, exp_gain_ring, exp_ring, bg_ring)
		local t = 0
		local c = text:color()
		local w, h = text:size()
		local cx, cy = text:center()
		local ecx, ecy = exp_gain_ring:center()

		while true do
			local dt = coroutine.yield()
			t = t + dt
			local alpha = math.abs(math.sin(t * 180 * 1))

			text:set_size(math.lerp(w * 2, w, alpha), math.lerp(h * 2, h, alpha))
			text:set_font_size(math.lerp(25, tweak_data.menu.pd2_small_font_size, alpha * alpha))
			text:set_center_y(cy)
			exp_gain_ring:set_size(math.lerp(72, 64, alpha * alpha), math.lerp(72, 64, alpha * alpha))
			exp_gain_ring:set_center(ecx, ecy)
			exp_ring:set_size(exp_gain_ring:size())
			exp_ring:set_center(exp_gain_ring:center())
			bg_ring:set_size(exp_gain_ring:size())
			bg_ring:set_center(exp_gain_ring:center())
		end
	end
	
	function HUDStatsScreen:exp_progress(exp_panel)
		if not _G.RealtimeXP.settings.allow_bottom_tab or managers.crime_spree:is_active() or Custom_HUDs then
			return
		end
		
		local profile_wrapper_panel = exp_panel:panel({name = "profile_wrapper_panel", x = 15, y = -45})

		local next_level_data = managers.experience:next_level_data() or {}
		local current_progress = (next_level_data.current_points or 1) / (next_level_data.points or 1)
		
		local bg_ring = profile_wrapper_panel:bitmap({
			texture = "guis/textures/pd2/level_ring_small",
			w = 64,
			h = 64,
			alpha = 0.4,
			color = Color.black
		})
		local exp_ring = profile_wrapper_panel:bitmap({
			texture = "guis/textures/pd2/level_ring_small",
			h = 64,
			render_template = "VertexColorTexturedRadial",
			w = 64,
			blend_mode = "add",
			rotation = 360,
			layer = 1,
			color = Color(current_progress, 1, 1)
		})

		bg_ring:set_bottom(profile_wrapper_panel:h())
		exp_ring:set_bottom(profile_wrapper_panel:h())

		local reached = managers.experience._levels_reached
		local prank = managers.experience:current_rank()
		local plevel = managers.experience:current_level()
		local gain_xp = managers.experience._total_xp_gained
		local at_max_level = plevel == managers.experience:level_cap()
		local can_lvl_up = plevel ~= 0 and not at_max_level and next_level_data.current_points <= gain_xp
		local progress = (next_level_data.current_points or 1) / (next_level_data.points or 1)
		local below = reached > 0 and current_progress or (gain_xp or 1) / (next_level_data.points or 1)
		local above = managers.experience:get_prestige_xp_percentage_progress()
		local gain_progress = at_max_level and above or below
		local h = at_max_level and 70 or 64
		local w = at_max_level and 70 or 64
		local exp_gain_ring = profile_wrapper_panel:bitmap({
			texture = at_max_level and "guis/textures/pd2/exp_ring_purple" or "guis/textures/pd2/level_ring_potential_small",
			h = h,
			w = w,
			render_template = "VertexColorTexturedRadial",
			blend_mode = "normal",
			rotation = 360,
			layer = 2,
			color = Color(gain_progress, 1, 1)
		})
		if not at_max_level and reached < 1 then
			exp_gain_ring:rotate(360 * (progress - gain_progress))
		end
		
		exp_gain_ring:set_center(exp_ring:center())

		local level_text = profile_wrapper_panel:text({
			name = "level_text",
			font = tweak_data.menu.pd2_medium_font,
			font_size = tweak_data.hud_stats.day_description_size,
			text = tostring(plevel),
			color = tweak_data.screen_colors.text
		})

		managers.hud:make_fine_text(level_text)
		level_text:set_center(exp_ring:center())

		local text_offset = 4
		local prestige_xp_left = managers.experience:get_max_prestige_xp() - managers.experience:get_current_prestige_xp()
		
		local prestige_allowed = managers.experience:get_prestige_xp_percentage_progress() < 1 and prank > 0
		local below_max = plevel < 100 or prestige_allowed
		if not below_max then
			local at_max_level_text = profile_wrapper_panel:text({
				name = "at_max_level_text",
				text = managers.localization:to_upper_text("hud_at_max_level"),
				font_size = tweak_data.menu.pd2_small_font_size,
				font = tweak_data.menu.pd2_small_font,
				color = tweak_data.hud_stats.potential_xp_color
			})

			managers.hud:make_fine_text(at_max_level_text)
			at_max_level_text:set_left(math.round(exp_ring:right() + text_offset))
			at_max_level_text:set_center_y(math.round(exp_ring:center_y()) + 0)
		else
			local next_level_in = profile_wrapper_panel:text({
				text = "",
				name = "next_level_in",
				font_size = tweak_data.menu.pd2_small_font_size,
				font = tweak_data.menu.pd2_small_font,
				color = tweak_data.screen_colors.text
			})
			local points = next_level_data.points - next_level_data.current_points
			
			if at_max_level then
				next_level_in:set_text(managers.localization:to_upper_text("hud_total_xp_left", {XP = managers.money:add_decimal_marks_to_string(tostring(prestige_xp_left))}))
			else
				next_level_in:set_text(managers.localization:to_upper_text("menu_es_next_level") .. " " .. managers.money:add_decimal_marks_to_string(tostring(points)))
			end
			
			managers.menu_component:make_color_text(next_level_in, tweak_data.screen_colors.infamy_color)
			
			managers.hud:make_fine_text(next_level_in)
			next_level_in:set_left(math.round(exp_ring:right() + text_offset))
			next_level_in:set_center_y(math.round(exp_ring:center_y()) - 20)
				
			local text = managers.localization:to_upper_text("hud_total_xp_gained", {XP = managers.money:add_decimal_marks_to_string(tostring(gain_xp))})
			local gain_xp_text = profile_wrapper_panel:text({
				name = "gain_xp_text",
				text = text,
				font_size = tweak_data.menu.pd2_small_font_size,
				font = tweak_data.menu.pd2_small_font,
				color = tweak_data.hud_stats.potential_xp_color
			})

			managers.hud:make_fine_text(gain_xp_text)
			gain_xp_text:set_left(math.round(exp_ring:right() + text_offset))
			gain_xp_text:set_center_y(math.round(exp_ring:center_y()) + 0)

			local potential_level_up_text = profile_wrapper_panel:text({
				vertical = "center",
				name = "potential_level_up_text",
				blend_mode = "normal",
				align = "left",
				layer = 3,
				text = "",
				font_size = tweak_data.menu.pd2_small_font_size,
				font = tweak_data.menu.pd2_small_font
			})


			if at_max_level then
				potential_level_up_text:set_text(managers.localization:to_upper_text("menu_infamy_infamy_panel_prestige_level") .. " " .. math.floor(managers.experience:get_prestige_xp_percentage_progress() * 100) .. "%")
				potential_level_up_text:set_color(tweak_data.screen_colors.infamy_color)
			else
				if reached > 0 then
					potential_level_up_text:set_text(managers.localization:to_upper_text("hud_level_ups", {LEVELS = tostring(reached)}))
					potential_level_up_text:set_color(tweak_data.hud_stats.potential_xp_color)
				end
			end
			
			managers.hud:make_fine_text(potential_level_up_text)
			potential_level_up_text:set_left(math.round(exp_ring:right() + 4))
			potential_level_up_text:set_center_y(math.round(exp_ring:center_y()) + 20)
			
			if not at_max_level and reached > 0 then
				potential_level_up_text:animate(callback(self, self, "_animate_text_pulse"), exp_gain_ring, exp_ring, bg_ring)
			end
		end	
	end
end