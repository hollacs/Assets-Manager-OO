#if defined _oo_assets_included
	#endinput
#endif
#define _oo_assets_included

#include <oo>

#define CHECK_OBJ(%0,%1) if (!oo_object_exists(%0) || !oo_isa(%0, "Assets")) { abort(AMX_ERR_GENERAL, "Invalid Assets object (%d)", %0); return %1; }

stock AssetsGetSprite(any:this, const key[])
{
	CHECK_OBJ(this, 0)
	return oo_call(this, "GetSprite", key);
}

stock AssetsGetModel(any:this, const key[], model[], len)
{
	CHECK_OBJ(this, 0)
	return oo_call(this, "GetModel", key, model, len);
}

stock bool:AssetsGetRandomGeneric(any:this, const key[], sound[], len)
{
	CHECK_OBJ(this, false)

	new Array:generics_a;
	if ((generics_a = any:oo_call(this, "GetGeneric", key)) != Invalid_Array)
	{
		ArrayGetString(generics_a, random(ArraySize(generics_a)), sound, len);
		return true;
	}

	return false;
}

stock Array:AssetsGetGeneric(any:this, const key[])
{
	CHECK_OBJ(this, Invalid_Array)

	new Array:generics_a;
	if ((generics_a = any:oo_call(this, "GetGeneric", key)) != Invalid_Array)
		return generics_a;

	return Invalid_Array;
}

stock bool:AssetsGetRandomSound(any:this, const key[], sound[], len)
{
	CHECK_OBJ(this, false)

	new Array:sound_a;
	if ((sound_a = any:oo_call(this, "GetSound", key)) != Invalid_Array)
	{
		ArrayGetString(sound_a, random(ArraySize(sound_a)), sound, len);
		return true;
	}

	return false;
}

stock Array:AssetsGetSound(any:this, const key[])
{
	CHECK_OBJ(this, Invalid_Array)

	new Array:sound_a;
	if ((sound_a = any:oo_call(this, "GetSound", key)) != Invalid_Array)
		return sound_a;

	return Invalid_Array;
}

stock AssetsClone(any:this, any:other)
{
	CHECK_OBJ(this, )
	CHECK_OBJ(other, )

	oo_call(this, "Clone", other);
}

stock bool:AssetsLoadJson(any:this, const filename[])
{
	CHECK_OBJ(this, false);

	return oo_call(this, "LoadJson", filename);
}