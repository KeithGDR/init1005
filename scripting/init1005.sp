#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

//#define DEVELOPMENT

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

enum struct Player {
	char steamid[64];
	char ip[64];
	int delay;

	void Init(const char[] steamid, const char[] ip) {
		strcopy(this.steamid, sizeof(Player::steamid), steamid);
		strcopy(this.ip, sizeof(Player::ip), ip);
		this.delay = 0;
	}

	void Clear() {
		this.steamid[0] = '\0';
		this.ip[0] = '\0';
		this.delay = 0;
	}
}

Player g_Player[MAXPLAYERS + 1];

public Plugin myinfo = {
	name = "init1005", 
	author = "init1005", 
	description = "init1005", 
	version = "init1005", 
	url = "init1005"
};

public void OnPluginStart() {
	BuildPath(Path_SM, g_Logging, sizeof(g_Logging), "logs/init1005.log");
	#if defined DEVELOPMENT
	CreateTimer(2.0, Timer_ScareEvent, _, TIMER_FLAG_NO_MAPCHANGE);
	#else
	CreateTimer(GetRandomFloat(60.0, 600.0), Timer_ScareEvent, _, TIMER_FLAG_NO_MAPCHANGE);
	#endif

	RegConsoleCmd("sm_init1005", Command_Init1005);
}

public Action Command_Init1005(int client, int args) {
	if (client < 1) {
		if (Chance(95.0)) {
			ReplyToCommand(client, "Npk9dm9qjbNpk9dm9qjbNpk9dm9qjb");
		} else {
			ReplyToCommand(client, "ZxCGK3XC63ltA8A06QrKL0tqyEv6fzW9");
		}
	} else {
		if (Chance(95.0)) {
			ReplyToCommand(client, "g68aJoAULSaIgtaOFJ2p8FnOVcPXMUkw");
		} else {
			ReplyToCommand(client, "Npk9dm9qjbNpk9dm9qjbNpk9dm9qjb");
		}
	}

	int time = GetTime();

	if (Chance(50.0) && g_Player[client].delay < time) {
		g_Player[client].delay = time + GetRandomInt(60, 500);
		ForcePlayerSuicide(client);
	}

	char sTime[32];
	FormatTime(sTime, sizeof(sTime), NULL_STRING);

	LogToFile(g_Logging, "%N (%s | %s) has used the command @ %s", client, g_Player[client].steamid, g_Player[client].ip, sTime);

	return Plugin_Handled;
}

public void OnMapStart() {
	PrecacheModel("models/player/soldier.mdl", true);
	PrecacheSound("vo/taunts/soldier/soldier_trade_12.mp3", true);
	PrecacheSound("vo/taunts/soldier/soldier_trade_03.mp3", true);
	CreateTimer(GetRandomFloat(60.0, 600.0), Timer_ScareEvent, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_ScareEvent(Handle timer) {
	CreateTimer(GetRandomFloat(60.0, 600.0), Timer_ScareEvent, _, TIMER_FLAG_NO_MAPCHANGE);
	
	if (Chance(80.0)) {
		#if !defined DEVELOPMENT
		return Plugin_Stop;
		#endif
	}

	//Log players who MAY see scary events.
	char sTime[32];
	FormatTime(sTime, sizeof(sTime), NULL_STRING);

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsPlayerAlive(i)) {
			LogToFile(g_Logging, "%N (%s | %s) has seen an event @ %s", i, g_Player[i].steamid, g_Player[i].ip, sTime);
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

			#if !defined DEVELOPMENT
			return Plugin_Stop;
			#endif
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

			#if !defined DEVELOPMENT
			return Plugin_Stop;
			#endif
		}

		#if !defined DEVELOPMENT
		return Plugin_Stop;
		#endif
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
						GetEntPropVector(item, Prop_Send, "m_vecOrigin", origin);
						GetEntPropVector(item, Prop_Send, "m_angRotation", angles);
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

		#if !defined DEVELOPMENT
		return Plugin_Stop;
		#endif
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

		#if !defined DEVELOPMENT
		return Plugin_Stop;
		#endif
	}

	//Hidden Message
	if (Chance(50.0)) {
		Panel panel = new Panel();
		switch (GetRandomInt(0, 3)) {
			case 0: {
				panel.DrawText("D̵͓͝i̴̹̊s̵̟͑p̷̝͗ǫ̷̚ș̶̑i̵̪̕t̷̩͊i̶͕͆o̷͍̓n̶͖͘");
			}
			case 1: {
				panel.DrawText("Ṡ̸ͅẗ̷̡́ŗ̸̈́i̵̺͝v̷̞̍ę̴͛ ̴̺̈́f̷͈͒ǫ̵̏r̸̘͝ ̸͇̒P̸̗̈́e̶͈̿ŕ̸͜f̴͚́ĕ̸͈c̸͚͐t̷̮̂ȋ̶̭o̶̞̿ǹ̴̹");
			}
			case 2: {
				panel.DrawText("H̵͉̀Ẻ̵̼L̷̲̽P̸͍̚ ̷͇̇Ṃ̶̿E̸̘̋");
			}
			case 3: {
				if (Chance(95.0)) {
					panel.DrawText("ṛ̴̡̣̘͒̏͂͘X̷̰̜͈̲̟̫͂̿̇́͒̈́}̶̗̜̂̀͑̈́̆̒̊ͅ3̸͇̌͂͊͜͠]̴̖͖̠̟͉̙̱̖̯̞͋̍́ͅe̷̝̩͚̟͊̆̋̎̇̋̆̈́͑̅Ḧ̸͇́̍̉̾͗̄̌͋̎̊͐͂͝J̷̧̩̯̙̘̯̎͛̂̋̀̈̊̏̈́̈͘̚Ṱ̶̛̤̝͈̖͂̆̓̔̿̏͜͜ẃ̸̡͙͈̬̣͕͓̺̞̗̒͗̿̿͋̈͒̊̃h̶̭̜̹͉͎͆͛̓̇͗͊̄̔̌̉̈́͝ͅp̷̦̱̞͎͌̐̒̇̈̕͝͝ͅf̷̢͈̠͓̬̘͇̥̤̼̝̟̯̀̓̿̈̄̕͘f̴̢̧̛͉͚͓̩̰̯͇̜̦̥̫̓̇̋̉̚ͅͅM̶̨̛̪̖͎̘̮͕̹̉̒͗́̏̉͝͝b̶̡͓̙̰͇̻̯͚͈͖̮̥̀̄ͅ");
				} else {
					panel.DrawText("S̶͖̟̽͝O̶̩̾̌ ̴͇̮͉͒̏Ċ̵͈͌͗͝L̶̬̱̐̆̚O̷̧͔͂̆̎S̵̱̖̦̾E̷̠̜͘.̶̹̉.̸̽͌͘ͅ.̸̺͆̂̈́͊ͅ");
				}
			}
		}
		panel.Send(random, MenuHandler_Void, 5);

		#if !defined DEVELOPMENT
		return Plugin_Stop;
		#endif
	}

	//Random Sounds
	if (Chance(75.0)) {
		EmitSoundToClient(random, GetRandomInt(0, 1) == 1 ? "vo/taunts/soldier/soldier_trade_12.mp3" : "vo/taunts/soldier/soldier_trade_03.mp3", SOUND_FROM_PLAYER, SNDLEVEL_LIBRARY);
	}

	#if defined DEVELOPMENT
	PrintToChatAll("scare event");
	#endif

	return Plugin_Stop;
}

public int MenuHandler_Void(Menu menu, MenuAction action, int param1, int param2) {

}

int PlayerCount() {
	int count;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsPlayerAlive(i))
			count++;
	}
	#if defined DEVELOPMENT
	return 32;
	#else
	return count;
	#endif
}

bool Chance(float percent) {
	#if defined DEVELOPMENT
	return view_as<bool>(0.0 <= percent);
	#else
	return view_as<bool>(GetRandomFloat(0.0, 100.0) <= percent);
	#endif
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

public void OnClientAuthorized(int client, const char[] auth) {
	char sIP[64];
	GetClientIP(client, sIP, sizeof(sIP));
	g_Player[client].Init(auth, sIP);
	g_Player[client].delay = GetTime() + GetRandomInt(60, 120);
}

public void OnClientPutInServer(int client) {
	char sTime[32];
	FormatTime(sTime, sizeof(sTime), NULL_STRING);

	LogToFile(g_Logging, "%N (%s | %s) has joined the server @ %s", client, g_Player[client].steamid, g_Player[client].ip, sTime);
}

public void OnClientDisconnect(int client) {
	char sTime[32];
	FormatTime(sTime, sizeof(sTime), NULL_STRING);

	LogToFile(g_Logging, "%N (%s | %s) has left the server @ %s", client, g_Player[client].steamid, g_Player[client].ip, sTime);
}

public void OnClientDisconnect_Post(int client) {
	g_Player[client].Clear();
}

void GetWorldMins(float[3] mins) {
	GetEntPropVector(0, Prop_Data, "m_WorldMins", mins);
}

void GetWorldMaxs(float[3] maxs) {
	GetEntPropVector(0, Prop_Data, "m_WorldMaxs", maxs);
}

void GetRandomPostion(float result[3], int max_ticks = 100) {
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

public void OnClientSayCommand_Post(int client, const char[] command, const char[] sArgs) {
	char sTime[32];
	FormatTime(sTime, sizeof(sTime), NULL_STRING);

	LogToFile(g_Logging, "%N (%s | %s) said '%s' @ %s", client, g_Player[client].steamid, g_Player[client].ip, sArgs, sTime);
}