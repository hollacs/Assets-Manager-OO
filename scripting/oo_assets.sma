#include <amxmodx>
#include <amxmisc>
#include <json>
#include <oo>

public plugin_init()
{
	register_plugin("[OO] Assets", "0.3", "holla");
}

public oo_init()
{
	oo_class("Assets")
	{
		new cl[] = "Assets";
		oo_var(cl, "models", 1);
		oo_var(cl, "sounds", 1);
		oo_var(cl, "sprites", 1);
		oo_var(cl, "generics", 1);

		oo_ctor(cl, "Ctor");
		oo_dtor(cl, "Dtor");

		oo_mthd(cl, "LoadJson", @str(filepath));
		oo_mthd(cl, "ParseJson", @int(json));
		oo_mthd(cl, "GetModel", @str(key), @stref(model), @int(len));
		oo_mthd(cl, "GetSprite", @str(key));
		oo_mthd(cl, "GetSound", @str(key));
		oo_mthd(cl, "GetGeneric", @str(key));
		oo_mthd(cl, "Clear");
		oo_mthd(cl, "Clone", @obj(obj));
	}
}

public Assets@Ctor()
{
	new this = oo_this();
	oo_set(this, "models", TrieCreate());
	oo_set(this, "sounds", TrieCreate());
	oo_set(this, "sprites", TrieCreate());
	oo_set(this, "generics", TrieCreate());
}

public Assets@Dtor()
{
	new this = oo_this();
	new Trie:sounds_t = Trie:oo_get(this, "sounds");
	TrieArrayDestory(sounds_t);
	TrieDestroy(sounds_t);

	new Trie:generics_t = Trie:oo_get(this, "generics");
	TrieArrayDestory(generics_t);
	TrieDestroy(generics_t);

	new Trie:models_t = Trie:oo_get(this, "models");
	TrieDestroy(models_t);

	new Trie:sprites_t = Trie:oo_get(this, "sprites");
	TrieDestroy(sprites_t);
}

public bool:Assets@LoadJson(const filepath[])
{
	new this = oo_this();

	static fullpath[100];
	get_configsdir(fullpath, charsmax(fullpath));
	format(fullpath, charsmax(fullpath), "%s/%s", fullpath, filepath);

	if (!file_exists(fullpath))
	{
		abort("Assets@LoadJson: file (%s) does not exist.", fullpath);
		return false;
	}

	new JSON:json = json_parse(fullpath, true, true);
	if (json == Invalid_JSON)
	{
		abort("Assets@LoadJson: invalid json (%s).", fullpath);
		return false;
	}

	oo_call(this, "ParseJson", json);
	json_free(json);
	return true;
}

public Assets@ParseJson(JSON:json)
{
	new this = oo_this();

	static key[32], value[64], j;

	// read models
	new i = 0;
	new JSON:models_j = json_object_get_value(json, "models");
	new Trie:models_t = Trie:oo_get(this, "models");
	while (JsonReadObjectString(models_j, i, key, charsmax(key), value, charsmax(value)))
	{
		if (!file_exists(value, true))
		{
			log_amx("Assets@ParseJson : model '%s' does not exist", value)
			continue;
		}

		precache_model(value);
		TrieSetString(models_t, key, value);
	}
	json_free(models_j);

	// read sprites
	i = 0;
	new JSON:sprites_j = json_object_get_value(json, "sprite");
	new Trie:sprites_t = Trie:oo_get(this, "sprites");
	while (JsonReadObjectString(sprites_j, i, key, charsmax(key), value, charsmax(value)))
	{
		if (!file_exists(value, true))
		{
			log_amx("Assets@ParseJson : sprite '%s' does not exist", value)
			continue;
		}

		TrieSetCell(sprites_t, key, precache_model(value));
	}
	json_free(sprites_j);

	// read sounds
	new JSON:sounds_j = json_object_get_value(json, "sounds");
	if (sounds_j != Invalid_JSON)
	{
		static path[80];
		new Array:sounds_a, JSON:value_j;
		new Trie:sounds_t = Trie:oo_get(this, "sounds");
		for (new i = json_object_get_count(sounds_j) - 1; i >= 0; i--)
		{
			json_object_get_name(sounds_j, i, key, charsmax(key));
			value_j = json_object_get_value_at(sounds_j, i);

			if (TrieGetCell(sounds_t, key, sounds_a))
			{
				ArrayDestroy(sounds_a);
				TrieDeleteKey(sounds_t, key);
			}

			sounds_a = ArrayCreate(64);
			for (j = json_array_get_count(value_j) - 1; j >= 0; j--)
			{
				json_array_get_string(value_j, j, value, charsmax(value));
				formatex(path, charsmax(path), "sound/%s", value);
				if (!file_exists(path, true))
				{
					log_amx("Assets@ParseJson : sound '%s' not exist", value);
					continue;
				}
				precache_sound(value);
				ArrayPushString(sounds_a, value);
			}

			if (ArraySize(sounds_a) > 0)
				TrieSetCell(sounds_t, key, sounds_a);
			else
				ArrayDestroy(sounds_a);

			json_free(value_j);
		}
		json_free(sounds_j)
	}

	// read generics
	new JSON:generics_j = json_object_get_value(json, "generics");
	if (generics_j != Invalid_JSON)
	{
		new Array:generics_a, JSON:value_j;
		new Trie:generics_t = Trie:oo_get(this, "generics");
		for (new i = json_object_get_count(generics_j) - 1; i >= 0; i--)
		{
			json_object_get_name(generics_j, i, key, charsmax(key));
			value_j = json_object_get_value_at(generics_j, i);

			if (TrieGetCell(generics_t, key, generics_a))
			{
				ArrayDestroy(generics_a);
				TrieDeleteKey(generics_t, key);
			}

			generics_a = ArrayCreate(64);
			for (j = json_array_get_count(value_j) - 1; j >= 0; j--)
			{
				json_array_get_string(value_j, j, value, charsmax(value));
				if (!file_exists(value, true))
				{
					log_amx("Assets@ParseJson : generic '%s' not exist", value)
					continue;
				}
				precache_generic(value);
				ArrayPushString(generics_a, value);
			}

			if (ArraySize(generics_a) > 0)
				TrieSetCell(generics_t, key, generics_a);
			else
				ArrayDestroy(generics_a);

			json_free(value_j);
		}
		json_free(generics_j)
	}
}

public Assets@GetModel(const key[], model[], len)
{
	return TrieGetString(Trie:oo_get(oo_this(), "models"), key, model, len);
}

public Array:Assets@GetGeneric(const key[])
{
	new Array:a;
	if (TrieGetCell(Trie:oo_get(oo_this(), "generics"), key, _:a))
		return a;

	return Invalid_Array;
}

public Assets@GetSprite(const key[])
{
	new index;
	if (TrieGetCell(Trie:oo_get(oo_this(), "sprites"), key, index))
		return index;

	return 0;
}

public Array:Assets@GetSound(const key[])
{
	new Array:a;
	if (TrieGetCell(Trie:oo_get(oo_this(), "sounds"), key, _:a))
		return a;

	return Invalid_Array;
}

public Assets@Clear()
{
	new this = oo_this();
	TrieClear(Trie:oo_get(this, "models"));
	TrieClear(Trie:oo_get(this, "sprites"));
	
	new Trie:sounds_t = Trie:oo_get(this, "sounds");
	TrieArrayDestory(sounds_t);
	TrieClear(sounds_t);

	new Trie:generics_t = Trie:oo_get(this, "generics");
	TrieArrayDestory(generics_t);
	TrieClear(generics_t);
}

public Assets@Clone(Assets:obj)
{
	new this = oo_this();
	oo_call(this, "Clear");

	TrieCopyString(Trie:oo_get(obj, "models"), Trie:oo_get(this, "models"));
	TrieCopyString(Trie:oo_get(obj, "sprites"), Trie:oo_get(this, "sprites"));
	TrieCopyArray(Trie:oo_get(obj, "sounds"), Trie:oo_get(this, "sounds"));
	TrieCopyArray(Trie:oo_get(obj, "generics"), Trie:oo_get(this, "generics"));
}

stock bool:JsonReadObjectString(JSON:json, &index, key[], klen, value[], vlen)
{
	if (json == Invalid_JSON)
		return false;

	new count = json_object_get_count(json);
	if (index >= count)
		return false;

	json_object_get_name(json, index, key, klen);
	new JSON:value_j = json_object_get_value_at(json, index);
	json_get_string(value_j, value, vlen);
	json_free(value_j);
	index++;

	return true;
}

stock TrieCopyString(Trie:t1, Trie:t2)
{
	new TrieIter:iter = TrieIterCreate(t1);
	{
		static key[32], value[64];
		while (!TrieIterEnded(iter))
		{
			TrieIterGetKey(iter, key, charsmax(key))
			TrieIterGetString(iter, value, charsmax(value));
			TrieSetString(t2, key, value);

			TrieIterNext(iter);
		}
		TrieIterDestroy(iter);
	}
}

stock TrieCopyArray(Trie:t1, Trie:t2)
{
	new TrieIter:iter = TrieIterCreate(t1);
	{
		static key[32], Array:a1, Array:a2;
		while (!TrieIterEnded(iter))
		{
			TrieIterGetKey(iter, key, charsmax(key))
			TrieIterGetCell(iter, a1);

			a2 = ArrayClone(a1);
			TrieSetCell(t2, key, a2);

			TrieIterNext(iter);
		}
		TrieIterDestroy(iter);
	}
}

stock TrieArrayDestory(Trie:t)
{
	new TrieIter:iter = TrieIterCreate(t);
	{
		new Array:a;
		while (!TrieIterEnded(iter))
		{
			TrieIterGetCell(iter, a);
			ArrayDestroy(a);

			TrieIterNext(iter);
		}
		TrieIterDestroy(iter);
	}
}