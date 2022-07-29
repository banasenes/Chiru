Hooks:PostHook(SentryGunBase, "init", "init_drone", function (self)
	self._is_player_sentry = table.contains(tweak_data.equipments.sentry_id_strings, self._unit:name())
end)

-- Don't fall down if attachment point moved
local _check_body = SentryGunBase._check_body
function SentryGunBase:_check_body(...)
	if not self._is_player_sentry then
		return _check_body(self, ...)
	end

	if not self._is_dynamic then
		self._attached_data.index = (self._attached_data.index < self._attached_data.max_index and self._attached_data.index or 0) + 1
	end
end


-- Add some additional sync data for drop in clients
Hooks:PostHook(SentryGunBase, "save", "save_drone", function (self, save_data)
	if not self._is_player_sentry then
		return
	end

	save_data.owner_id = self._owner_id
	save_data.has_shield = self._has_shield
end)

Hooks:PostHook(SentryGunBase, "load", "load_drone", function (self, save_data)
	if not self._is_player_sentry then
		return
	end

	if save_data.owner_id then
		self:set_owner_id(save_data.owner_id)
	end
	if save_data.has_shield then
		self:enable_shield()
	end
end)


-- Enable additional shield models
local shield_objects = { Idstring("g_shield_r"), Idstring("g_shield_l"), Idstring("s_shield_r"), Idstring("s_shield_l") }
Hooks:PostHook(SentryGunBase, "enable_shield", "enable_shield_drone", function (self)
	if not self._is_player_sentry then
		return
	end

	for _, obj_ids in pairs(shield_objects) do
		local obj = self._unit:get_object(obj_ids)
		if obj then
			obj:set_visibility(true)
		end
	end
end)
