#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

char g_Logging[PLATFORM_MAX_PATH];

#define RAG_GIBBED			(1<<0)
#define RAG_BURNING			(1<<1)
#define RAG_ELECTROCUTED	(1<<2)
#define RAG_FEIGNDEATH		(1<<3)
#define RAG_WASDISGUISED	(1<<4)
#define RAG_BECOMEASH		(1<<5)
#define RAG_ONGROUND		(1<<6)
#define RAG_CLOAKED			(1<<7)
#define RAG_GOLDEN			(1<<8)
#define RAG_ICE				(1<<9)
#define RAG_CRITONHARDCRIT	(1<<10)
#define RAG_HIGHVELOCITY	(1<<11)
#define RAG_NOHEAD			(1<<12)

public Plugin myinfo = {
	name = "init1005", 
	author = "init1005", 
	description = "init1005", 
	version = "init1005", 
	url = "init1005"
};

public void OnPluginStart() {
	BuildPath(Path_SM, g_Logging, sizeof(g_Logging), "logs/init1005.log");
	CreateTimer(GetRandomFloat(60.0, 600.0), Timer_ScareEvent, _, TIMER_FLAG_NO_MAPCHANGE);
	//CreateTimer(2.0, Timer_ScareEvent, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void OnMapStart() {
	PrecacheModel("models/player/soldier.mdl", true);
	CreateTimer(GetRandomFloat(60.0, 600.0), Timer_ScareEvent, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_ScareEvent(Handle timer) {
	CreateTimer(GetRandomFloat(60.0, 600.0), Timer_ScareEvent, _, TIMER_FLAG_NO_MAPCHANGE);
	
	if (Chance(80.0)) {
		return Plugin_Stop;
	}

	//Log players who MAY see scary events.
	char sTime[32];
	FormatTime(sTime, sizeof(sTime), NULL_STRING);

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsPlayerAlive(i)) {
			LogToFile(g_Logging, "%N has seen an event @ %s", i, sTime);
		}
	}

	//Too many players, can't do blatantly spooky shit.
	if (PlayerCount() > 2) {

		//Clear Clips
		if (Chance(80.0)) {
			int weapon;
			for (int i = 1; i <= MaxClients; i++) {
				if (!IsClientInGame(i) || !IsPlayerAlive(i)) {
					continue;
				}

				for (int slot = 0; slot < 2; slot++) {
					if ((weapon = GetPlayerWeaponSlot(i, slot)) != -1 && Chance(50.0)) {
						SetEntProp(weapon, Prop_Data, "m_iClip1", 0);
					}
				}
			}

			return Plugin_Stop;
		}

		//Deduct Health
		if (Chance(80.0)) {
			for (int i = 1; i <= MaxClients; i++) {
				if (!IsClientInGame(i) || !IsPlayerAlive(i)) {
					continue;
				}

				if (GetClientHealth(i) > 50 && Chance(50.0)) {
					SetEntityHealth(i, GetClientHealth(i) - GetRandomInt(1, 5));
				}
			}

			return Plugin_Stop;
		}

		return Plugin_Stop;
	}

	//Get a random player.
	int random = GetRandomPlayer();

	if (random < 1) {
		return Plugin_Stop;
	}

	float vecOrigin[3];
	GetClientAbsOrigin(random, vecOrigin);

	//Spawn Soldier
	if (Chance(80.0)) {
		int entity = CreateEntityByName("prop_dynamic");

		if (IsValidEntity(entity)) {	

			float origin[3]; float angles[3]; bool spawn;
			switch (GetRandomInt(0, 1)) {
				case 0: {
					GetClientAbsOrigin(random, origin);
					GetClientAbsAngles(random, angles);
					spawn = true;
				}
				case 1: {
					int item = GetNearestEntity(random, "item_*");
					
					if (IsValidEntity(item)) {
						GetClientAbsOrigin(item, origin);
						GetClientAbsAngles(item, angles);
						spawn = true;
					}
				}
			}

			if (spawn) {
				DispatchKeyValue(entity, "model", "models/player/soldier.mdl");
				DispatchKeyValueVector(entity, "origin", origin);
				DispatchKeyValueVector(entity, "angles", angles);
				DispatchSpawn(entity);
				ActivateEntity(entity);
			}

			AutoKill(entity, 0.2);
		}

		return Plugin_Stop;
	}

	//Random Gibs
	if (Chance(50.0)) {
		int ragdoll = CreateEntityByName("tf_ragdoll");

		if (IsValidEntity(ragdoll)) {
			SetEntProp(ragdoll, Prop_Send, "m_iPlayerIndex", random);
			SetEntProp(ragdoll, Prop_Send, "m_iTeam", 2);
			SetEntProp(ragdoll, Prop_Send, "m_iClass", 3);

			float rand[3];
			GetRandomPostion(rand);

			SetEntPropVector(ragdoll, Prop_Send, "m_vecRagdollOrigin", rand);
			SetEntProp(ragdoll, Prop_Send, "m_bGib", 1);

			DispatchSpawn(ragdoll);
			ActivateEntity(ragdoll);
		}

		return Plugin_Stop;
	}

	//PrintToChatAll("scare event");

	return Plugin_Stop;
}

int PlayerCount() {
	int count;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsPlayerAlive(i))
			count++;
	}
	return count;
}

bool Chance(float percent) {
	return view_as<bool>(GetRandomFloat(0.0, 100.0) > percent);
}

int GetRandomPlayer() {
	int[] players = new int[MaxClients];
	int total;

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsPlayerAlive(i)) {
			players[total++] = i;
		}
	}

	return players[GetRandomInt(0, total - 1)];
}

void AutoKill(int entity, float duration) {
	char output[64];
	Format(output, sizeof(output), "OnUser1 !self:kill::%.1f:1", duration);
	SetVariantString(output);
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser1");
}

int GetNearestEntity(int entity, const char[] classname = "*") {
	float vecStart[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vecStart);
	
	int nearest = -1;
	
	int buffer = -1; float vecEnd[3]; float cache; float distance;
	while ((buffer = FindEntityByClassname(buffer, classname)) != -1) {
		GetEntPropVector(buffer, Prop_Send, "m_vecOrigin", vecEnd);
		distance = GetVectorDistance(vecStart, vecEnd);
		
		if (cache == 0.0) {
			nearest = buffer;
			cache = distance;
			continue;
		}
		
		if (GetVectorDistance(vecStart, vecEnd) < cache) {
			nearest = buffer;
			cache = distance;
		}
	}
	
	return nearest;
}

public void OnClientPutInServer(int client) {
	char sTime[32];
	FormatTime(sTime, sizeof(sTime), NULL_STRING);

	LogToFile(g_Logging, "%N has joined the server @ %s", client, sTime);
}

public void OnClientDisconnect(int client) {
	char sTime[32];
	FormatTime(sTime, sizeof(sTime), NULL_STRING);

	LogToFile(g_Logging, "%N has left the server @ %s", client, sTime);
}

stock void GetWorldMins(float[3] mins) {
	GetEntPropVector(0, Prop_Data, "m_WorldMins", mins);
}

stock void GetWorldMaxs(float[3] maxs) {
	GetEntPropVector(0, Prop_Data, "m_WorldMaxs", maxs);
}

stock void GetRandomPostion(float result[3], int max_ticks = 100) {
	float vecWorldMins[3];
	GetWorldMins(vecWorldMins);

	float vecWorldMaxs[3];
	GetWorldMaxs(vecWorldMaxs);

	int ticks = 1;
	result[0] = GetRandomFloat(vecWorldMins[0], vecWorldMaxs[0]);
	result[1] = GetRandomFloat(vecWorldMins[1], vecWorldMaxs[1]);
	result[2] = GetRandomFloat(vecWorldMins[2], vecWorldMaxs[2]);

	while (TR_PointOutsideWorld(result) && max_ticks > ticks) {
		ticks++;
		result[0] = GetRandomFloat(vecWorldMins[0], vecWorldMaxs[0]);
		result[1] = GetRandomFloat(vecWorldMins[1], vecWorldMaxs[1]);
		result[2] = GetRandomFloat(vecWorldMins[2], vecWorldMaxs[2]);
	}
}