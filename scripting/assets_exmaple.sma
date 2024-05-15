#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <oo_assets>

new Assets:g_oAssets;

public plugin_precache()
{
	// create object
	g_oAssets = oo_new("Assets");

	// load assets from json file
	oo_call(g_oAssets, "LoadJson", "assets/example.json");
}

public plugin_init()
{
	register_plugin("Assets Exmaple", "0.1", "holla");

	RegisterHam(Ham_Item_Deploy, "weapon_knife", "OnKnifeDeploy_Post", 1);
	RegisterHam(Ham_TraceAttack, "worldspawn", "OnWorldSpawnTraceAttack_Post", 1);

	register_forward(FM_EmitSound, "OnEmitSound");
}

public OnKnifeDeploy_Post(ent)
{
	// check valid entity
	if (!pev_valid(ent))
		return;

	// get this knife owner (player id)
	new player = get_ent_data_entity(ent, "CBasePlayerItem", "m_pPlayer");
	if (!player)
		return;

	// get new v_knife model from assets object
	static model[32];
	if (AssetsGetModel(g_oAssets, "v_knife", model, charsmax(model)))
	{
		// change player v_knife model
		set_pev(player, pev_viewmodel2, model);
	}
}

public OnWorldSpawnTraceAttack_Post(ent, attacker, Float:damage, Float:direction[3], tr, damagebits)
{
	// check valid entity and alive attacker
	if (!is_user_alive(attacker))
		return;

	// attacker is using knife
	if (get_user_weapon(attacker) == CSW_KNIFE)
	{
		// get shockwave sprite from assets object
		new sprite = AssetsGetSprite(g_oAssets, "shockwave");
		if (sprite)
		{
			// get trace end position
			static Float:origin[3];
			pev(attacker, pev_origin, origin);

			// make a shockwave effect when a knife hit wall
			message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin);
			write_byte(TE_BEAMCYLINDER); // TE id
			write_coord_f(origin[0]); // x
			write_coord_f(origin[1]); // y
			write_coord_f(origin[2]); // z
			write_coord_f(origin[0]); // x axis
			write_coord_f(origin[1]); // y axis
			write_coord_f(origin[2] + 250.0); // z axis
			write_short(sprite); // sprite
			write_byte(0); // startframe
			write_byte(0); // framerate
			write_byte(10); // life
			write_byte(30); // width
			write_byte(0); // noise
			write_byte(200); // red
			write_byte(200); // green
			write_byte(200); // blue
			write_byte(200); // brightness
			write_byte(0); // speed
			message_end();
		}
	}
}

public OnEmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	// check alive
	if (!is_user_alive(id))
		return FMRES_IGNORED;
	
	// weapons/
	if (strlen(sample) > 8)
	{
		// is knife hit wall sound
		if (equal(sample[8], "knife_hitwall", 13))
		{
			// get new knife hitwall sound from assets object
			static sound[32];
			if (AssetsGetRandomSound(g_oAssets, "knife_hitwall", sound, charsmax(sound)))
			{
				// replace original sound
				emit_sound(id, channel, sound, volume, attn, flags, pitch);
				return FMRES_SUPERCEDE;
			}
		}
		
		// is knife slash sound
		if (equal(sample[8], "knife_slash", 11))
		{
			// get new knife hitwall sound from assets object
			static spk[32];
			if (AssetsGetRandomGeneric(g_oAssets, "knife_spk", spk, charsmax(spk)))
			{
				// make a spk sound
				client_cmd(0, "spk %s", spk);

				// block original sound
				return FMRES_SUPERCEDE;
			}
		}
	}

	return FMRES_IGNORED;
}