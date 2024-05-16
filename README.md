# Assets Manager OO
 I've made an AMXX API that can avoid hard-coding file paths in the plugin (useless stuff). <br>
 It's a bit similar to ZP 5.0's `amx_settings_api.sma`. <br>
 but I made it more user-friendly and only aim for asset files, using json to read file paths. <br>

### Requirements:
- AMXX 1.9.0+
- [OO Module](https://github.com/hollacs/oo_amxx/tree/no-std)

### Files
- `oo_assets.sma` is the core API plugin
- `oo_assets.inc` is the INC file
- `assets_example.sma` is an example showcase and it comes up with a `example.json` in `configs/`

<br>

Let's take a look at an example of how to use it:
```sourcepawn
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
```
<br>

JSON file settings:
```json
{
    "models": {
        "v_knife" : "models/v_knife_r.mdl"
    },
    "sounds": {
        "knife_hitwall" : ["weapons/hegrenade-1.wav", "weapons/hegrenade-2.wav"]
    },
    "generics" : {
        "knife_spk" : ["sound/hostage/hos1.wav", "sound/hostage/hos2.wav", "sound/hostage/hos3.wav"]
    },
    "sprites" : {
        "shockwave" : "sprites/shockwave.spr"
    }
}
```
<br>

**Note:**
- Each model or sprite can only match one file.
- Each sound or generic can match more than one file.
- LoadJson can only be called in plugin_precache().

<br>
The result of this example plugin is first to read the asset files from json, and automatically precache them.

Then, when a player uses the knife to hit a wall, it will create a shockwave (sprite) and an explosion (sound), Otherwise, when the player hits nothing, it plays a hostage sound (generic).

Finally, the knife model will be changed to the CS 1.5 (model).

That's it, all 4 resource types (model, sound, sprite, generic) are showcased once.

<hr>

Seeing the above code you may think, Isn't that every plugin needs to make a json too?

Actually not, you can load the json in a plugin once, and then share the object id with other plugins.

Here's how to use XVar to share object ids with other plugins

<br>

Plugin that require json to be loaded look like this:
```sourcepawn
#include <amxmodx>
#include <oo_assets>

public Assets:AssetsObject;

public plugin_precache()
{
       AssetsObject = oo_new("Assets");
       oo_call(AssetsObject, "LoadJson", "assets/test.json");
}
```

<br>

A stock function to simplify the code: (can be written in your custom inc)
```sourcepawn
stock any:GetXVarObject(const name[])
{
       new xvar = get_xvar_id(name);
       if (xvar == -1)
              set_fail_state("XVar does not exist: %s", name);
       
       new any:object = get_xvar_num(xvar);
       if (!oo_object_exists(object))
              set_fail_state("Object does not exist: %d", object);

       return object;
}
```

<br>

This is the other plugin A:
```sourcepawn
new Assets:g_oAssets;

public plugin_init()
{
       g_oAssets = GetXVarObject("AssetsObject");
       register_clcmd("test_mp3", "CmdTestMp3");
}

public CmdTestMp3(id)
{
       static music[64];
       if (AssetsGetRandomGeneric(g_oAssets, "music", music, charsmax(music)))
              client_cmd(id, "mp3 play %s", music);
       
       return PLUGIN_HANDLED;
}
```

This is the other plugin B:
```sourcepawn
new Assets:g_oAssets;

public plugin_init()
{
       g_oAssets = GetXVarObject("AssetsObject");
       register_clcmd("test_spk", "CmdTestSpk");
}

public CmdTestSpk(id)
{
       static spk[64];
       if (AssetsGetRandomGeneric(g_oAssets, "spk", spk, charsmax(spk)))
              client_cmd(id, "spk %s", spk);
       
       return PLUGIN_HANDLED;
}
```

JSON File: (This is just an example)
```json
{
       "generics" : {
              "music" : "sound/test/resident_evil.mp3",
              "spk" : "sound/test/door_stuck.wav"
       }
}
```

<hr>

If you're worried about performance problem, there are a few solutions

For example, at the beginning of `plugin_init()`, use a global variable to get a file and then use it. (only for `model` or `sprite`)

Here's an example:
```sourcepawn


new g_KnifeModel[64];
new g_ShockwaveSpr;
...
public plugin_init()
{
       ...
       AssetsGetModel(g_oAssets, "v_knife", g_KnifeModel, charsmax(g_KnifeModel));
       g_ShockwaveSpr = AssetsGetSprite(g_oAssets, "shockwave");
}

public OnKnifeDeploy_Post(ent)
{
       ...
       if (g_KnifeModel[0])
              set_pev(player, pev_viewmodel2, g_KnifeModel);
}

public OnWorldSpawnTraceAttack_Post(ent, attacker, Float:damage, Float:direction[3], tr, damagebits)
{
       ...
       if (g_ShockwaveSpr)
       {
              message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin);
              write_byte(TE_BEAMCYLINDER); // TE id
              ...
              write_short(g_ShockwaveSpr);
              message_end();
       }
}
```

<br>

About `sound` and `generic`, you can get the Array: handle in global:
```sourcepawn


new Array:g_aHitWallSound;
new Array:g_aSlashSound;
...
public plugin_init()
{
       ...
       g_aHitWallSound = AssetsGetSound(g_oAssets, "knife_hitwall");
       g_aSlashSound = AssetsGetGeneric(g_oAssets, "knife_spk");
}

public OnEmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
       ...
       if (equal(sample[8], "knife_hitwall", 13))
       {
              if (g_aHitWallSound != Invalid_Array)
              {
                     static sound[64];
                     ArrayGetRandomString(g_aHitWallSound, sound, charsmax(sound));
                     emit_sound(id, channel, sound, volume, attn, flags, pitch);
                     return FMRES_SUPERCEDE;
              }
       }
       if (equal(sample[8], "knife_slash", 11))
       {
              if (g_aSlashSound != Invalid_Array)
              {
                     static sound[64];
                     ArrayGetRandomString(g_aSlashSound, sound, charsmax(sound));
                     client_cmd(0, "spk %s", sound);
                     return FMRES_SUPERCEDE;
              }
       }
}

stock ArrayGetRandomString(Array:handle, sound[], maxlen)
{
       ArrayGetString(handle, random(ArraySize(handle)), sound, maxlen);
}
```
