--Link fire mode unit
Hooks:PostHook(SentryGunWeapon, "interaction_setup", "interaction_setup_drone", function (self)
	self._unit:movement()._fire_mode_unit = self._fire_mode_unit -- Linking units doesnt work for some reason, so save fire mode unit to manually position it
end)
