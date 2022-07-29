local mrot_set_axis_angle = mrotation.set_axis_angle
local mrot_yaw = mrotation.yaw
local mvec_add = mvector3.add
local mvec_cross = mvector3.cross
local mvec_dir = mvector3.direction
local mvec_dot = mvector3.dot
local mvec_lerp = mvector3.lerp
local mvec_mul = mvector3.multiply
local mvec_norm = mvector3.normalize
local mvec_set = mvector3.set
local mvec_set_static = mvector3.set_static
local mvec_set_z = mvector3.set_z
local tmp_rot1 = Rotation()
local tmp_vec1 = Vector3()
local tmp_vec2 = Vector3()

-- How many follow spots are available and their offsets
local spots_template = {
	{ offset = Vector3(150, 150, 160) },
	{ offset = Vector3(-150, 150, 160) }
}
local spots = {}


tweak_data.upgrades.sentry_gun_base_ammo = 300
tweak_data.upgrades.sentry_gun_base_armor = 50


SentryGunMovement.placed_sentries = {}
SentryGunMovement.allowed_sentries = {}


Hooks:Add("NetworkReceivedData", "NetworkReceivedDataDroneSentries", function (sender, id, data)
	if (id == "ICanHazDroneSentry?" and Network:is_server() and sender ~= 1) or (id == "IHazDroneSentry!" and Network:is_client() and sender == 1) then
		local unit_id = tonumber(data)
		SentryGunMovement.allowed_sentries[unit_id] = true

		local sentry = SentryGunMovement.placed_sentries[unit_id]
		if alive(sentry) then
			sentry:movement():select_drone_spot(true)
		end
	end
end)


Hooks:PostHook(SentryGunMovement, "init", "init_drone", function (self)
	self._is_player_sentry = table.contains(tweak_data.equipments.sentry_id_strings, self._unit:name())
	if not self._is_player_sentry then
		return
	end

	self._propeller_obj = self._unit:get_object(Idstring("a_propeller"))
	self._propeller_r_obj = self._unit:get_object(Idstring("g_propeller_r"))
	self._propeller_l_obj = self._unit:get_object(Idstring("g_propeller_l"))

	self._t_offset = 100 * math.random()

	self._ground_slotmask = managers.slot:get_mask("bullet_blank_impact_targets")

	SentryGunMovement.placed_sentries[self._unit:id()] = self._unit
end)

Hooks:PostHook(SentryGunMovement, "pre_destroy", "pre_destroy_drone", function (self)
	if not self._is_player_sentry then
		return
	end

	SentryGunMovement.placed_sentries[self._unit:id()] = nil
	SentryGunMovement.allowed_sentries[self._unit:id()] = nil
end)


Hooks:PostHook(SentryGunMovement, "save", "save_drone", function (self, save_data)
	if self._is_player_sentry then
		save_data.is_following = self._follow_spot and true
	end
end)

Hooks:PostHook(SentryGunMovement, "load", "load_drone", function (self, save_data)
	if save_data.is_following then
		SentryGunMovement.allowed_sentries[self._unit:id()] = true
		self:select_drone_spot()
	end
end)


function SentryGunMovement:select_drone_spot()
	if not self._is_player_sentry then
		return
	end

	local peer_id = self._unit:base():get_owner_id()
	if not peer_id then
		return
	end

	local follow_spot
	spots[peer_id] = spots[peer_id] or deep_clone(spots_template)
	for _, v in pairs(spots[peer_id]) do
		if not alive(v.unit) or self._unit == v.unit then
			follow_spot = v
			break
		end
	end

	if not follow_spot then
		return
	end

	local allowed = SentryGunMovement.allowed_sentries[self._unit:id()]
	if Network:is_server() then
		if peer_id == managers.network:session():local_peer():id() or allowed then
			LuaNetworking:SendToPeers("IHazDroneSentry!", tostring(self._unit:id()))
		else
			return
		end
	elseif not allowed then
		if peer_id == managers.network:session():local_peer():id() and not self._spot_requested then
			LuaNetworking:SendToPeer(1, "ICanHazDroneSentry?", tostring(self._unit:id()))
			self._spot_requested = true
		end
		return
	end

	self._follow_spot = follow_spot
	self._follow_spot.unit = self._unit
end

function SentryGunMovement:remove_drone_spot()
	if not self._is_player_sentry then
		return
	end

	self._switched_off = false -- Prevent disabling of movement update

	self._spot_requested = nil

	SentryGunMovement.allowed_sentries[self._unit:id()] = nil

	if self._follow_spot then
		self._follow_spot.unit = nil
		self._follow_spot = nil
	end

	if self._unit:character_damage():dead() then
		self._unit:base():sync_set_dynamic()
		self._propeller_r_obj:set_visibility(false)
		self._propeller_l_obj:set_visibility(false)
	end
end

Hooks:PostHook(SentryGunMovement, "setup", "setup_drone", SentryGunMovement.select_drone_spot)
Hooks:PostHook(SentryGunMovement, "switch_on", "switch_on_drone", SentryGunMovement.select_drone_spot)

Hooks:PostHook(SentryGunMovement, "switch_off", "switch_off_drone", SentryGunMovement.remove_drone_spot)
Hooks:PostHook(SentryGunMovement, "on_death", "on_death_drone", SentryGunMovement.remove_drone_spot)


Hooks:PostHook(SentryGunMovement, "update", "update_drone", function (self, unit, t, dt)
	if not self._is_player_sentry then
		return
	end

	t = t + self._t_offset

	mvec_set_static(tmp_vec1, math.cos(t * 20) * 10, -math.sin(t * 20) * 5, math.sin(t * 40) * 10)
	self._spin_obj:set_local_position(tmp_vec1)

	mrot_set_axis_angle(tmp_rot1, math.UP, t * math.random(500, 510))
	self._propeller_l_obj:set_local_rotation(tmp_rot1)
	self._propeller_r_obj:set_local_rotation(tmp_rot1)

	if self._motor_sound then
		self._motor_sound:stop()
	end

	local owner_pos, owner_rot
	local unit_pos = unit:position()
	local follow_spot = self._follow_spot
	if follow_spot then
		local owner = unit:base():get_owner()
		if alive(owner) then
			owner_pos = owner:position()
			owner_rot = owner:camera() and owner:camera():rotation() or owner:rotation()
		else
			follow_spot = nil
		end
	end

	if follow_spot then
		mvec_set(tmp_vec1, owner_rot:y())
		mvec_set_z(tmp_vec1, 0)
		mvec_norm(tmp_vec1)
		mvec_cross(tmp_vec2, tmp_vec1, math.UP)
		mvec_mul(tmp_vec2, follow_spot.offset.x)
		mvec_mul(tmp_vec1, follow_spot.offset.y)
		mvec_add(tmp_vec1, tmp_vec2)
		mvec_add(tmp_vec1, owner_pos)
		mvec_set_z(tmp_vec1, tmp_vec1.z + follow_spot.offset.z)
	else
		mvec_set(tmp_vec1, unit_pos)
		mvec_set_z(tmp_vec1, tmp_vec1.z + 50)
		mvec_set(tmp_vec2, tmp_vec1)
		mvec_set_z(tmp_vec2, tmp_vec2.z - 4000)
		local ray = unit:raycast("ray", tmp_vec1, tmp_vec2, "slot_mask", self._ground_slotmask)
		mvec_set(tmp_vec1, ray and ray.hit_position.z < unit_pos.z and ray.hit_position or unit_pos)
	end

	local dis = mvec_dir(tmp_vec2, unit_pos, tmp_vec1)
	local dot = mvec_dot(tmp_vec2, self._m_head_fwd)
	mrot_set_axis_angle(tmp_rot1, math.X, -dot * 40 * math.min(1, dis / 200))
	self._propeller_obj:set_local_rotation(tmp_rot1)

	mvec_lerp(tmp_vec1, unit_pos, tmp_vec1, dt)
	unit:set_position(tmp_vec1)
	if alive(self._fire_mode_unit) then
		self._fire_mode_unit:set_position(tmp_vec1)
	end

	local function angle_lerp(a, b, t)
		if math.abs(b - a) > 180 then
			if b > a then
				a = a + 360
			else
				b = b + 360
			end
		end
		return math.lerp(a, b, t)
	end

	local attention = self:attention()
	if follow_spot and (not attention or attention.reaction < AIAttentionObject.REACT_SHOOT) then
		mrotation.set_look_at(tmp_rot1, tmp_vec2, math.UP)
		local target = angle_lerp(mrot_yaw(owner_rot), mrot_yaw(tmp_rot1), math.min(1, dis / 200))
		local current = mrot_yaw(unit:rotation())
		mrot_set_axis_angle(tmp_rot1, math.UP, angle_lerp(current, target, 2 * dt))
		unit:set_rotation(tmp_rot1)
	end

end)
