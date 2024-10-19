#pragma semicolon 1

#define PLUGIN_AUTHOR "Feykich, null138"
#define PLUGIN_VERSION "2.2.0"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zombiereloaded>

#pragma newdecls required

int iCaseSelection; //i2Modes, dumbInt2modes;
Handle hTimerRepeat = INVALID_HANDLE, hFindConVar;
char NemesisModelPath[PLATFORM_MAX_PATH], NemesisModel[256];

bool bEnabledGame, bHookPlayerSpawn, bHookWeaponFire, bHookModelScale, bHookFastPlay, bDontChange; //b2Modes; // checking if everything is working to avoid errors and bugs
bool bEnableGravityMode, bEnableFastPlayMode, bEnableNemesisMode, bEnableModelScaleMode, bEnableRandomGunsMode; // menu switchers

ConVar cvGravityValue, cvSpeedValue, cvSpeedValueNemesis, cvModelScaleValue, cvFloatGravityValue, cvRandomGunsTimer; // settings
ConVar cvGravityMode, cvFastPlayMode, cvNemesisMode, cvModelScaleMode, cvRandomGunsMode; // cvar switchers

static const char StringWeapons[][] = {
	"weapon_glock", "weapon_usp", "weapon_p228",
	"weapon_deagle", "weapon_elite", "weapon_fiveseven", 
	"weapon_m3", "weapon_xm1014", "weapon_galil",
	"weapon_ak47", "weapon_scout", "weapon_sg552", 
	"weapon_awp", "weapon_g3sg1", "weapon_famas", 
	"weapon_m4a1", "weapon_aug", "weapon_sg550", 
	"weapon_mac10", "weapon_tmp", "weapon_mp5navy",
	"weapon_ump45", "weapon_p90", "weapon_m249" };


public Plugin myinfo = 
{
	name = "[ZR] Random Game Modes",
	author = PLUGIN_AUTHOR,
	description = "The name of this plugin is the answer",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/feykich/",
	url = "https://steamcommunity.com/id/null138/"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_random", CheckMenu, ADMFLAG_KICK);
	
	cvGravityValue = 		CreateConVar("sm_servergravityvalue", 	"300", 	"Sets value of 'sv_gravity' for Gravity mode", FCVAR_NOTIFY, true, 0.0, true, 9999.0);
	cvSpeedValue = 			CreateConVar("sm_speedvalue", 			"2.0", 	"Sets value of speed for Fast Play mode",	FCVAR_NOTIFY, true, 0.1, true, 10.0);
	cvSpeedValueNemesis = 	CreateConVar("sm_speedvaluenemesis", 	"3.0", 	"Sets the value of speed mother zombies for Nemesis mode", FCVAR_NOTIFY, true, 0.1, true, 999.0);
	cvModelScaleValue = 	CreateConVar("sm_modelscalevalue", 		"0.5", 	"Sets models scale value for Model Scale mode", FCVAR_NOTIFY, true, 0.1, true, 30.0);
	cvFloatGravityValue = 	CreateConVar("sm_gravityvalue", 		"0.5", 	"Sets value of gravity for Fast Play mode", FCVAR_NOTIFY, true, 0.1, true, 100.0);
	cvRandomGunsTimer = 	CreateConVar("sm_randomgunstimer", 		"60.0", "Sets number of seconds for Random Guns countdown", FCVAR_NOTIFY, true, 1.0, true, 999.0);
	
	
	cvRandomGunsMode = CreateConVar("sm_randomgunsmode", "1", "0 - Disable mode. 1 - Enable Mode");
	cvRandomGunsMode.AddChangeHook(RandomGunsModeValue);
	
	cvModelScaleMode = CreateConVar("sm_modelscalemode", "1", "0 - Disable mode. 1 - Enable mode");
	cvModelScaleMode.AddChangeHook(ModelScaleModeValue);
	
	cvFastPlayMode = CreateConVar("sm_fastplaymode", "1", "0 - Disable mode. 1 - Enable Mode");
	cvFastPlayMode.AddChangeHook(FastPlayModeValue);
	
	cvGravityMode = CreateConVar("sm_gravitymode", "1", "0 - Disable mode. 1 - Enable mode");
	cvGravityMode.AddChangeHook(GravityModeValue);
	
	cvNemesisMode = CreateConVar("sm_nemesismode", "1", "0 - Disable mode. 1 - Enable Mode");
	cvNemesisMode.AddChangeHook(NemesisModeValue);
	
	
	BuildPath(Path_SM, NemesisModelPath, sizeof(NemesisModelPath), "configs/randomgames.cfg");
	
	HookEvent("round_start", RoundStart);
	HookEvent("round_end", RoundEnd);
}

public Action CheckMenu(int client, int args)
{
	if(!IsFakeClient(client) && IsClientInGame(client))
	{
		MenuRandomGames(client);
	}
	return Plugin_Handled;
}

public void MenuRandomGames(int client)
{
	Menu menu = new Menu(RandomMenu_Handler);
	
	char sbuffer[32];
	
	menu.SetTitle("Settings Random Modes \n \n");
	
	Format(sbuffer, 32, "Enable Random [%c] \n \n", bEnabledGame ? 'X':'-');
	menu.AddItem("1", sbuffer);
	Format(sbuffer, 32, "Enable Random Guns Mode [%c]", bEnableRandomGunsMode ? 'X':'-');
	menu.AddItem("2", sbuffer);
	Format(sbuffer, 32, "Enable Model Scale Mode [%c]", bEnableModelScaleMode ? 'X':'-');
	menu.AddItem("3", sbuffer);
	Format(sbuffer, 32, "Enable Fast Play Mode [%c]", bEnableFastPlayMode ? 'X':'-');
	menu.AddItem("4", sbuffer);
	Format(sbuffer, 32, "Enable Gravity Mode [%c]", bEnableGravityMode ? 'X':'-');
	menu.AddItem("5", sbuffer);
	Format(sbuffer, 32, "Enable Nemesis mode [%c] \n \n", bEnableNemesisMode ? 'X':'-');
	menu.AddItem("6", sbuffer);
	//Format(sbuffer, 32, "Allow 2 modes in one round? [%c]", b2Modes ? 'X':'-');
	//menu.AddItem("7", sbuffer);
	
	menu.Display(client, 30);
}

int RandomMenu_Handler(Menu menu, MenuAction action, int client, int choice)
{
	if(action == MenuAction_Select)
	{
		char list[64];
		menu.GetItem(choice, list, sizeof(list));
		if(StrEqual(list, "1"))
		{
			bEnabledGame = !bEnabledGame;
			PrintToChatAll("[ZR Randomizer] Random Games %sabled by %N", bEnabledGame ? "en" : "dis", client);
			LogMessage("[ZR Randomizer] ADMIN %N Toggled random games", client);
			ConfigModel();
		}
		if(StrEqual(list, "2"))
		{
			bEnableRandomGunsMode = !bEnableRandomGunsMode;
		}
		if(StrEqual(list, "3"))
		{
			bEnableModelScaleMode = !bEnableModelScaleMode;
		}
		if(StrEqual(list, "4"))
		{
			bEnableFastPlayMode = !bEnableFastPlayMode;
		}
		if(StrEqual(list, "5"))
		{
			bEnableGravityMode = !bEnableGravityMode;
		}
		if(StrEqual(list, "6"))
		{
			bEnableNemesisMode = !bEnableNemesisMode;
		}
		/*
		if(StrEqual(list, "7"))
		{
			CreateTimer(0.0, dumbfunction, TIMER_DATA_HNDL_CLOSE);
			b2Modes = !b2Modes;
		}
		*/
		MenuRandomGames(client);
	}
	else if(action == MenuAction_End)
	{
		menu.Close();
	}
}

public Action CheckConVarValue()
{
	static int LastRandom;
	if(bEnabledGame == true)
	{
		int count;
		if(bEnableRandomGunsMode)
		{
			count++;
		}
		if(bEnableModelScaleMode)
		{
			count++;
		}
		if(bEnableFastPlayMode)
		{
			count++;
		}
		if(bEnableGravityMode)
		{
			count++;
		}
		if(bEnableNemesisMode)
		{
			count++;
		}
		if(count < 2)
		{
			PrintToChatAll("[ZR Randomizer] WARNING Modes are disabled by Menu settings. Please enable at least 2 (TWO) modes to continue.");
			return Plugin_Handled;
		}
		bool choosen;
		iCaseSelection = GetRandomInt(1, 5);
		if(LastRandom != iCaseSelection)
		{
			switch(iCaseSelection)
			{
				case 1:
				{
					if(bEnableRandomGunsMode)
					{
						choosen = true;
						
						hFindConVar = FindConVar("zr_weapons_zmarket");
						
						int value = GetConVarInt(hFindConVar);
						if(value == 0)
						{
							bDontChange = true; // just in case if server's setting of "zr_weapons_zmarket" is set to 0
						}
						
						SetConVarString(hFindConVar, "0", false, false);
						randomGuns();
						
						float fRandomGunsTimer = GetConVarFloat(cvRandomGunsTimer);
						PrintToChatAll("[ZR Randomizer] Mode for this round: Random equipped guns! (Every %.f sec. new weapon)", fRandomGunsTimer);
					}
				}
				case 2:
				{
					if(bEnableModelScaleMode)
					{
						choosen = true;
						SetModelScale();
						PrintToChatAll("[ZR Randomizer] Mode for this round: Modified size players' model!");
					}
				}
				case 3:
				{
					if(bEnableFastPlayMode)
					{
						choosen = true;
						
						FastPlayMode();
						PrintToChatAll("[ZR Randomizer] Mode for this round: High Speed + Low Gravity Zombies and Infinity Ammo!");
					}
				}
				case 4:
				{
					if(bEnableGravityMode)
					{
						choosen = true;
						
						GravityMode();
						PrintToChatAll("[ZR Randomizer] Mode for this round: Modified Gravity!");
						//PrintToChatAll("%i", i2Modes);
					}
				}
				case 5:
				{
					if(bEnableNemesisMode)
					{
						choosen = true;
						NemesisMode();
						PrintToChatAll("[ZR Randomizer] Mode for this round: The zombies are now become Nemesis!");
					}
				}
			}
			if(!choosen)
			{
				CheckConVarValue();
			}
		}
		else if(LastRandom == iCaseSelection)
		{
			CheckConVarValue();
			PrintToChatAll("[ZR Randomizer] Repeat selection");
		}
		LastRandom = iCaseSelection;
		
		//if(b2Modes)
		//{
		//	b2Modes = false;
		//	CheckConVarValue();
		//	PrintToChatAll("true randomize");
		//}
	}
	
	//if(dumbInt2modes == 1)
	//{
	//	CreateTimer(0.1, dumbfunction, TIMER_DATA_HNDL_CLOSE); // horrible.. this fixes spamming issue
	//}
	//PrintToChatAll("%i", dumbInt2modes);
	//PrintToChatAll("%i", i2Modes);
	
	
	return Plugin_Handled;
}

/*
public Action dumbfunction(Handle timer)
{
	if(b2Modes)
	{
		dumbInt2modes = 1;
	}
	else
	{
		dumbInt2modes = 0;
	}
}
*/

/*
	Event
*/
public Action RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(bEnabledGame == true)
	{
		PrintToChatAll("[ZR Randomizer] Game mode will be started when become the first infection!");
	}
	return Plugin_Continue;
}

public Action ZR_OnClientInfect(int &client, int &attacker, bool &motherInfect, bool &respawnOverride, bool &respawn)
{
	if(motherInfect)
	{
		RequestFrame(OnNextTick);
	}
}

void OnNextTick(any shit) // ignore this warning
{
	CheckConVarValue();
}

public Action RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if(bEnabledGame == true)
	{
		/*
		if(b2Modes)
		{
			
		}
		*/
		
		//PrintToChatAll("%i", i2Modes);
		if(iCaseSelection == 1)
		{
			hFindConVar = FindConVar("zr_weapons_zmarket");
			if(hTimerRepeat)
			{
				KillTimer(hTimerRepeat);
			}
			if(bDontChange) // if true then we pass
			{
				return Plugin_Handled; // hold up!
			}
			SetConVarString(hFindConVar, "1", false, false);
		}
		if(iCaseSelection == 2)
		{
			if(bHookPlayerSpawn)
			{
				UnhookEvent("player_spawn", PlayerSpawn);
				bHookPlayerSpawn = false;
				bHookModelScale = false;
				for (int i = 1; i <= MaxClients; i++)
				{
					if(!IsClientInGame(i)) // fix error
					{
						continue;
					}
					SetEntPropFloat(i, Prop_Send, "m_flModelScale", 1.0);
				}
			}
		}
		if(iCaseSelection == 3)
		{
			if(bHookWeaponFire)
			{
				UnhookEvent("weapon_fire", WeaponFire);
				bHookWeaponFire = false;
				bHookFastPlay = false;
			}
		}
		if(iCaseSelection == 4)
		{
			hFindConVar = FindConVar("sv_gravity");
			SetConVarString(hFindConVar, "800", false, false);
		}
		if(iCaseSelection == 5)
		{
			hFindConVar = FindConVar("zr_respawn");
			SetConVarString(hFindConVar, "1", false, false);
			for(int i = 1; i <= MaxClients; i++)
			{
				if(!IsClientInGame(i)) // fix error
				{
					continue;
				}
				if(IsPlayerAlive(i) && ZR_IsClientZombie(i))
				{
					SetEntPropFloat(i, Prop_Send, "m_flLaggedMovementValue", 1.0);
					SetEntityGravity(i, 1.0);
				}
			}
		}
	}
	return Plugin_Handled;
}

public Action PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(iCaseSelection == 2 && bHookModelScale)
	{
		float fModelScaleValue = GetConVarFloat(cvModelScaleValue);
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", fModelScaleValue);
	}
	if(iCaseSelection == 3 && ZR_IsClientZombie(client) && bHookFastPlay)
	{
		float fSpeedValue = GetConVarFloat(cvSpeedValue);
		float fFloatGravityValue = GetConVarFloat(cvFloatGravityValue);
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", fSpeedValue);
		SetEntityGravity(client, fFloatGravityValue);
	}
	return Plugin_Continue;
}
/*
	End Event
*/

/*
	Function game modes
*/
void randomGuns()
{
	static int iLastWeapon;
	int iRandom;
	iRandom = GetRandomInt(1, 24);
	if(iLastWeapon != iRandom)
    {
		for (int i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i)) // fix error
			{
				continue;
			}
			if(IsPlayerAlive(i) && ZR_IsClientHuman(i))
			{
				int iWeaponSlot0 = GetPlayerWeaponSlot(i, 0);
				int iWeaponSlot1 = GetPlayerWeaponSlot(i, 1);
				int iGrenadeHE = GetPlayerWeaponSlot(i, 2);
				int iGivePlayerHE = GivePlayerItem(i, "weapon_hegrenade"); // fix error
				if(iWeaponSlot0 > 0) 
				{
					RemovePlayerItem(i, iWeaponSlot0);
					RemoveEdict(iWeaponSlot0);
				}
				if(iWeaponSlot1 > 0) 
				{
					RemovePlayerItem(i, iWeaponSlot1);
					RemoveEdict(iWeaponSlot1);
				}
				if(iGrenadeHE < 0) 
				{
					EquipPlayerWeapon(i, iGivePlayerHE);
				}
				DataPack data = new DataPack();
				data.WriteCell(i);
				data.WriteString(StringWeapons[iRandom]);
				RequestFrame(OnNextFrame0, data);
			}
			else if(iLastWeapon == iRandom)
			{
				if(GetAdminFlag(GetUserAdmin(i), Admin_Kick))
				{
					PrintToChat(i, "[Weapon Randomizer] Previous weapon repeat detected. Repeat randomizing..");
				}
				randomGuns();
			}
		}
		float fRandomGunsTimer = GetConVarFloat(cvRandomGunsTimer);
		hTimerRepeat = CreateTimer(fRandomGunsTimer, TimerHandle);
	}
	iLastWeapon = iRandom;
}

void OnNextFrame0(any datapack)
{
	DataPack data = datapack;
	data.Reset();
	int client = data.ReadCell();
	char sWeapon[32];
	data.ReadString(sWeapon, 32);
	int iGiveWeapon = GivePlayerItem(client, sWeapon);
	EquipPlayerWeapon(client, iGiveWeapon);
	CreateTimer(0.5, tGiveAmmo, iGiveWeapon);
}

// code shared from https://github.com/srcdslab/sm-plugin-ExtraCommands/blob/master/addons/sourcemod/scripting/ExtraCommands.sp#L493
public Action tGiveAmmo(Handle timer, int iGiveWeapon)
{
	int client = GetEntPropEnt(iGiveWeapon, Prop_Data, "m_hOwner");
	int primaryAmmoType = GetEntProp(iGiveWeapon, Prop_Data, "m_iPrimaryAmmoType");
	int secondaryAmmoType = GetEntProp(iGiveWeapon, Prop_Data, "m_iSecondaryAmmoType");
	int iAmmo = 2000;
	if(primaryAmmoType != -1)
	{
		SetEntProp(client, Prop_Send, "m_iAmmo", iAmmo, _, primaryAmmoType);
	}
	if(secondaryAmmoType != -1)
	{
		SetEntProp(client, Prop_Send, "m_iAmmo", iAmmo, _, secondaryAmmoType);
	}
}

public Action TimerHandle(Handle timer)
{
	randomGuns();
}

void SetModelScale()
{
	HookEvent("player_spawn", PlayerSpawn); bHookPlayerSpawn = true; // fix error
	bHookModelScale = true;
	float fModelScaleValue = GetConVarFloat(cvModelScaleValue);
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i)) // fix error
		{
			continue;
		}
		if(IsPlayerAlive(i))
		{
			SetEntPropFloat(i, Prop_Send, "m_flModelScale", fModelScaleValue);
		}
	}
}

void FastPlayMode()
{
	HookEvent("player_spawn", PlayerSpawn); bHookPlayerSpawn = true; // fix error
	HookEvent("weapon_fire", WeaponFire); bHookWeaponFire = true; // fix error
	bHookFastPlay = true;
	float fSpeedValue = GetConVarFloat(cvSpeedValue);
	float fFloatGravityValue = GetConVarFloat(cvFloatGravityValue);
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i)) // fix error
		{
			continue;
		}
		if(IsPlayerAlive(i) && ZR_IsClientZombie(i))
		{
			SetEntPropFloat(i, Prop_Send, "m_flLaggedMovementValue", fSpeedValue);
			SetEntityGravity(i, fFloatGravityValue);
		}
	}
}

void GravityMode()
{
	hFindConVar = FindConVar("sv_gravity");
	char GravityValue[128];
	GetConVarString(cvGravityValue, GravityValue, sizeof(GravityValue));
	SetConVarString(hFindConVar, GravityValue, false, false);
}

void NemesisMode()
{
	hFindConVar = FindConVar("zr_respawn");
	float fSpeedValueNemesis = GetConVarFloat(cvSpeedValueNemesis);
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i)) // fix error
		{
			continue;
		}
		if(IsPlayerAlive(i) && ZR_IsClientZombie(i))
		{
			SetEntityModel(i, NemesisModel);
			SetEntPropFloat(i, Prop_Send, "m_flLaggedMovementValue", fSpeedValueNemesis);
			SetConVarString(hFindConVar, "0", false, false);
		}
	}
}
/*
	End function game modes
*/

void ConfigModel()
{
	KeyValues kv = new KeyValues("models");
	
	if(!FileExists(NemesisModelPath))
	{
		SetFailState("Couldn't find file: %s", NemesisModelPath);
		return;
	}
	if(!kv.ImportFromFile(NemesisModelPath))
	{
		SetFailState("Couldn't import from File: %s", NemesisModelPath);
		return;
	}
	
	if(kv.JumpToKey("modes", true)) // if the key is missing
	{
		kv.GetString("nemesis", NemesisModel, sizeof(NemesisModel));
		
		if(NemesisModel[0] == '\0') // empty string?
		{
			kv.SetString("nemesis", "insert your skin here");
			
			bEnabledGame = false;
			PrintToChatAll("[ZR Randomizer] Detected missing key in the file. More details in Server console.");
			LogError("[ZR Randomizer] Created new key in the file. Insert your model for Nemesis into this file: %s", NemesisModelPath);
			
			kv.Rewind();
			kv.ExportToFile(NemesisModelPath);
			
			kv.Close();
			return; // to prevent error invalid handle
		}
	}
	
	if(StrContains(NemesisModel, ".mdl", false) != -1)
	{
		if(!IsModelPrecached(NemesisModel))
		{
			PrecacheModel(NemesisModel, false);
		}
	}
	else
	{
		bEnabledGame = false;
		PrintToChatAll("[ZR Randomizer] Can't find nemesis model! Insert the skin via config. More details in Server console.");
		PrintToChatAll("[ZR Randomizer] Disabling Randomizer.. After inserting, enable randomizer again through Menu.");
		LogError("Couldn't find model in key 'nemesis' from file: %s", NemesisModelPath);
	}
	
	kv.Close();
}

/*
	CVar
*/
public void GravityModeValue(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bEnableGravityMode = cvGravityMode.BoolValue;
}

public void ModelScaleModeValue(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bEnableModelScaleMode = cvModelScaleMode.BoolValue;
}

public void FastPlayModeValue(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bEnableFastPlayMode = cvFastPlayMode.BoolValue;
}

public void RandomGunsModeValue(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bEnableRandomGunsMode = cvRandomGunsMode.BoolValue;
}

public void NemesisModeValue(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bEnableNemesisMode = cvNemesisMode.BoolValue;
}
/*
	End CVar
*/

public void OnMapEnd()
{
	
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(iCaseSelection != 5)
	{
		return Plugin_Continue;
	}
	if(IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		return Plugin_Continue;
	}
	char sWeapon[32];
	GetClientWeapon(client, sWeapon, sizeof(sWeapon));
	if(StrContains(sWeapon, "knife", false))
	{
		ForcePlayerSuicide(client);
	}
	return Plugin_Continue;
}

public Action WeaponFire(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int iWeaponActive = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(IsValidEntity(iWeaponActive))
	{
		if(GetEntProp(iWeaponActive, Prop_Data, "m_iState"))
		{
			SetEntProp(iWeaponActive, Prop_Data, "m_iClip1", GetEntProp(iWeaponActive, Prop_Data, "m_iClip1") + 1);
		}
	}
	return Plugin_Continue;
}
