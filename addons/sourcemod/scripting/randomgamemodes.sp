#pragma semicolon 1

#define PLUGIN_AUTHOR "Feykich, null138"
#define PLUGIN_VERSION "2.0"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zombiereloaded>

#pragma newdecls required

bool bEnabledGame = false, bHookPlayerSpawn, bHookWeaponFire, bHookModelScale, bHookFastPlay;
Handle hTimerRepeat = INVALID_HANDLE, hFindConVar;
int iCaseSelection;
ConVar cvGravityValue, cvSpeedValue, cvSpeedValueNemesis;
int icvGravityMode, icvFastPlayMode, icvNemesisMode, icvModelScaleMode, icvRandomGunsMode;
char NemesisModelPath[PLATFORM_MAX_PATH], NemesisModel[256];

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
	url = "https://steamcommunity.com/id/zombiefeyk159753/",
	url = "https://steamcommunity.com/id/null138/"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_random", CheckMenu, ADMFLAG_KICK);
	
	cvGravityValue = CreateConVar("sm_gravityvalue", "300", "Sets value of gravity for random mode", FCVAR_NOTIFY, true, 0.0, true, 9999.0);
	cvSpeedValue = CreateConVar("sm_speedvalue", "2", "Sets value of speed for random mode", FCVAR_NOTIFY, true, 1.0, true, 10.0);
	cvSpeedValueNemesis = CreateConVar("sm_speedvaluenemesis", "3", "Sets value of speed for random mode", FCVAR_NOTIFY, true, 0.1, true, 999.0);
	
	ConVar cvar;
	cvar = CreateConVar("sm_randomgunsmode", "1", "0 - Disable mode. 1 - Enable Mode", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	icvRandomGunsMode = cvar.IntValue;
	cvar.AddChangeHook(RandomGunsModeValue);
	
	cvar = CreateConVar("sm_modelscalemode", "1", "0 - Disable mode. 1 - Enable mode", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	icvModelScaleMode = cvar.IntValue;
	cvar.AddChangeHook(ModelScaleModeValue);
	
	cvar = CreateConVar("sm_fastplaymode", "1", "0 - Disable mode. 1 - Enable Mode", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	icvFastPlayMode = cvar.IntValue;
	cvar.AddChangeHook(FastPlayModeValue);
	
	cvar = CreateConVar("sm_gravitymode", "1", "0 - Disable mode. 1 - Enable mode", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	icvGravityMode = cvar.IntValue;
	cvar.AddChangeHook(GravityModeValue);
	
	cvar = CreateConVar("sm_nemesismode", "1", "0 - Disable mode. 1 - Enable Mode", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	icvNemesisMode = cvar.IntValue;
	cvar.AddChangeHook(NemesisModeValue);
	
	
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
	
	menu.SetTitle("Settings Random Modes\n");
	
	Format(sbuffer, 32, "Enable Random [%c]", bEnabledGame ? 'X':'-');
	menu.AddItem("1", sbuffer);
	
	menu.Display(client, 30);
}

int RandomMenu_Handler(Menu menu, MenuAction action, int client, int choice)
{
	if(action == MenuAction_Select)
	{
		choice++;
		switch(choice)
		{
			case 1:
			{
				bEnabledGame = !bEnabledGame;
				PrintToChatAll("[ZR] Random Games %sabled", bEnabledGame ? "en" : "dis");
				LogMessage("[ZR Randomizer] ADMIN %N Toggled random games", client);
				ConfigModel();
			}
		}
	}
	else if(action == MenuAction_End)
	{
		menu.Close();
	}
}

void CheckConVarValue()
{
	static int LastRandom;
	if(bEnabledGame == true)
	{
		int count;
		if(icvRandomGunsMode)
		{
			count++;
		}
		if(icvModelScaleMode)
		{
			count++;
		}
		if(icvFastPlayMode)
		{
			count++;
		}
		if(icvGravityMode)
		{
			count++;
		}
		if(icvNemesisMode)
		{
			count++;
		}
		if(count < 2)
		{
			PrintToChatAll("[Randomizer] WARNING Modes are disabled by CVar. Please enable at least 2 (TWO) modes to continue.");
			return;
		}
		iCaseSelection = GetRandomInt(1, 5);
		if(LastRandom != iCaseSelection)
		{
			bool choosen;
			switch(iCaseSelection)
			{
				case 1:
				{
					if(icvRandomGunsMode)
					{
						choosen = true;
						randomGuns();
						hFindConVar = FindConVar("zr_weapons_zmarket");
						SetConVarString(hFindConVar, "0", false, false);
						HookEvent("weapon_fire", WeaponFire); bHookWeaponFire = true; // fix error
						PrintToChatAll("[Randomizer] Mode for this round: Random equipped guns! (Every 60 sec. new weapon)");
					}
				}
				case 2:
				{
					if(icvModelScaleMode)
					{
						choosen = true;
						SetModelScale();
						PrintToChatAll("[Randomizer] Mode for this round: Modified size players' model!");
					}
				}
				case 3:
				{
					if(icvFastPlayMode)
					{
						choosen = true;
						FastPlayMode();
						PrintToChatAll("[Randomizer] Mode for this round: High Speed + Low Gravity Zombies and Infinity Ammo!");
					}
				}
				case 4:
				{
					if(icvGravityMode)
					{
						choosen = true;
						GravityMode();
						PrintToChatAll("[Randomizer] Mode for this round: Low Gravity!");
					}
				}
				case 5:
				{
					if(icvNemesisMode)
					{
						choosen = true;
						NemesisMode();
						PrintToChatAll("[Randomizer] Mode for this round: The zombies are now become Nemesis!");
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
			PrintToChatAll("[Randomizer] Repeat slection");
		}
	}
	LastRandom = iCaseSelection;
}

/*
	Event
*/
public Action RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(bEnabledGame == true)
	{
		PrintToChatAll("[Randomizer] Game mode will be started when become the first infection!");
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

void OnNextTick(any shit)
{
	CheckConVarValue();
}

public Action RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if(bEnabledGame == true)
	{
		if(iCaseSelection == 1)
		{
			hFindConVar = FindConVar("zr_weapons_zmarket");
			SetConVarString(hFindConVar, "1", false, false);
			if(hTimerRepeat != null)
			{
				KillTimer(hTimerRepeat);
			}
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
		else if(iCaseSelection == 3)
		{
			if(bHookWeaponFire)
			{
				UnhookEvent("weapon_fire", WeaponFire);
				bHookWeaponFire = false;
				bHookFastPlay = false;
			}
		}
		else if(iCaseSelection == 4)
		{
			hFindConVar = FindConVar("sv_gravity");
			SetConVarString(hFindConVar, "800", false, false);
		}
		else if(iCaseSelection == 5)
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
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 0.5);
	}
	else if(iCaseSelection == 3 && ZR_IsClientZombie(client) && bHookFastPlay)
	{
		float fSpeedValue = GetConVarFloat(cvSpeedValue);
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", fSpeedValue);
		SetEntityGravity(client, 0.5);
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
		hTimerRepeat = CreateTimer(60.0, TimerHandle);
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
	//CreateTimer(1.0, tGiveAmmo, iGiveWeapon);
}

/*
public Action tGiveAmmo(Handle timer, int iGiveWeapon) *this piece of shit doesn't work, uncomment if you know what to do.*
{
	int primaryAmmoType = GetEntProp(iGiveWeapon, Prop_Data, "m_iPrimaryAmmoType");
	int secondaryAmmoType = GetEntProp(iGiveWeapon, Prop_Data, "m_iSecondaryAmmoType");
	int client = GetEntPropEnt(iGiveWeapon, Prop_Data, "m_hOwner");
	int iAmmo = 9999;
	if(primaryAmmoType != -1)
	{
		SetEntData(client, primaryAmmoType, iAmmo);
	}
	if(secondaryAmmoType != -1)
	{
		SetEntData(client, secondaryAmmoType, iAmmo);
	}
}
*/
public Action TimerHandle(Handle timer)
{
	randomGuns();
}

void SetModelScale()
{
	HookEvent("player_spawn", PlayerSpawn); bHookPlayerSpawn = true; // fix error
	bHookModelScale = true;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i)) // fix error
		{
			continue;
		}
		if(IsPlayerAlive(i))
		{
			SetEntPropFloat(i, Prop_Send, "m_flModelScale", 0.5);
		}
	}
}

void FastPlayMode()
{
	HookEvent("player_spawn", PlayerSpawn); bHookPlayerSpawn = true; // fix error
	HookEvent("weapon_fire", WeaponFire); bHookWeaponFire = true; // fix error
	bHookFastPlay = true;
	float fSpeedValue = GetConVarFloat(cvSpeedValue);
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i)) // fix error
		{
			continue;
		}
		if(IsPlayerAlive(i) && ZR_IsClientZombie(i))
		{
			SetEntPropFloat(i, Prop_Send, "m_flLaggedMovementValue", fSpeedValue);
			SetEntityGravity(i, 0.5);
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
	PrecacheModel(NemesisModel, false);
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
	if(!kv.ImportFromFile())
	{
		SetFailState("Couldn't import from File: %s", NemesisModelPath);
		return;
	}
	kv.GetString("nemesis", NemesisModel, sizeof(NemesisModel));
	
	kv.GoBack();
}

/*
	CVar
*/
public void GravityModeValue(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	icvGravityMode = cvar.IntValue;
	
	CheckConVarValue();
}

public void ModelScaleModeValue(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	icvModelScaleMode = cvar.IntValue;
	
	CheckConVarValue();
}

public void FastPlayModeValue(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	icvFastPlayMode = cvar.IntValue;
	
	CheckConVarValue();
}

public void RandomGunsModeValue(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	icvRandomGunsMode = cvar.IntValue;
	
	CheckConVarValue();
}

public void NemesisModeValue(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	icvNemesisMode = cvar.IntValue;
	
	CheckConVarValue();
}
/*
	End CVar
*/

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
