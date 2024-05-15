#include <amxmodx>
#include <amxmisc>
#include <json>
#include <oo>

public plugin_init()
{
	register_plugin("[OO] Assets", "0.1", "holla");
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
	new TrieIter:iter = TrieIterCreate(sounds_t);
	{
		new Array:sounds_a;
		while (!TrieIterEnded(iter))
		{
			TrieIterGetCell(iter, sounds_a);
			ArrayDestroy(sounds_a);

			TrieIterNext(iter);
		}
		TrieIterDestroy(iter);
	}
	TrieDestroy(sounds_t);

	new Trie:generics_t = Trie:oo_get(this, "generics");
	{
		new Array:generics_a;
		while (!TrieIterEnded(iter))
		{
			TrieIterGetCell(iter, generics_a);
			ArrayDestroy(generics_a);

			TrieIterNext(iter);
		}
		TrieIterDestroy(iter);
	}
	TrieDestroy(generics_t);

	new Trie:models_t = Trie:oo_get(this, "models");
	TrieDestroy(models_t);

	new Trie:sprites_t = Trie:oo_get(this, "sprites");
	TrieDestroy(sprites_t);
}

public bool:Assets@LoadJson(const filepath[])
{
	static fullpath[64];
	get_configsdir(fullpath, charsmax(fullpath));
	format(fullpath, charsmax(fullpath), "%s/%s", fullpath, filepath);

	new this = oo_this();
	if (!file_exists(fullpath))
	{
		abort(AMX_ERR_GENERAL, "file (%s) does not exist", fullpath);
		return false;
	}

	new JSON:json = json_parse(fullpath, true, true);
	if (json == Invalid_JSON)
	{
		abort(AMX_ERR_GENERAL, "invalid json (%s)", fullpath);
		return false;
	}

	oo_call(this, "ParseJson", json);
	json_free(json);
	return true;
}

public Assets@ParseJson(JSON:json)
{
	new this = oo_this();
	static key[32], value[64]

	new JSON:models_j = json_object_get_value(json, "models");
	if (models_j != Invalid_JSON)
	{
		new JSON:value_j;
		new Trie:models_t = Trie:oo_get(this, "models");

		for (new i = json_object_get_count(models_j) - 1; i >= 0; i--)
		{
			json_object_get_name(models_j, i, key, charsmax(key));

			value_j = json_object_get_value_at(models_j, i);
			json_get_string(value_j, value, charsmax(value));

			if (file_exists(value, true))
			{
				precache_model(value);
				TrieSetString(models_t, key, value);
			}
			json_free(value_j);
		}
		json_free(models_j);
	}

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

			// already exist
			if (TrieGetCell(sounds_t, key, sounds_a))
			{
				ArrayDestroy(sounds_a);
				TrieDeleteKey(sounds_t, key);
			}

			sounds_a = ArrayCreate(64);
			for (new i = json_array_get_count(value_j) - 1; i >= 0; i--)
			{
				json_array_get_string(value_j, i, value, charsmax(value));

				formatex(path, charsmax(path), "sound/%s", value);
				if (file_exists(path, true))
				{
					precache_sound(value);
					ArrayPushString(sounds_a, value);
				}
			}

			if (ArraySize(sounds_a) > 0)
				TrieSetCell(sounds_t, key, sounds_a);
			else
				ArrayDestroy(sounds_a);

			json_free(value_j);
		}

		json_free(sounds_j)
	}

	new JSON:sprites_j = json_object_get_value(json, "sprites");
	if (sprites_j != Invalid_JSON)
	{
		new JSON:value_j = Invalid_JSON;
		new Trie:sprites_t = Trie:oo_get(this, "sprites");
		for (new i = json_object_get_count(sprites_j) - 1; i >= 0; i--)
		{
			json_object_get_name(sprites_j, i, key, charsmax(key));
			value_j = json_object_get_value_at(sprites_j, i);
			json_get_string(value_j, value, charsmax(value));
			json_free(value_j);

			if (file_exists(value, true))
			{
				TrieSetCell(sprites_t, key, precache_model(value));
			}
		}
		json_free(sprites_j);
	}

	new JSON:generics_j = json_object_get_value(json, "generics");
	if (generics_j != Invalid_JSON)
	{
		new Array:generics_a, JSON:value_j;
		new Trie:generics_t = Trie:oo_get(this, "generics");

		for (new i = json_object_get_count(generics_j) - 1; i >= 0; i--)
		{
			json_object_get_name(generics_j, i, key, charsmax(key));
			value_j = json_object_get_value_at(generics_j, i);

			// already exist
			if (TrieGetCell(generics_t, key, generics_a))
			{
				ArrayDestroy(generics_a);
				TrieDeleteKey(generics_t, key);
			}

			generics_a = ArrayCreate(64);
			for (new i = json_array_get_count(value_j) - 1; i >= 0; i--)
			{
				json_array_get_string(value_j, i, value, charsmax(value));
				if (file_exists(value, true))
				{
					precache_generic(value);
					ArrayPushString(generics_a, value);
				}
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

	return -1;
}

public Array:Assets@GetSound(const key[])
{
	new Array:a;
	if (TrieGetCell(Trie:oo_get(oo_this(), "sounds"), key, _:a))
		return a;

	return Invalid_Array;
}