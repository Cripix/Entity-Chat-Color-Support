#include <sourcemod>
#include <clientprefs>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>
#include <colors>

#pragma newdecls required

#define TRIGGER_SYMBOL2 '/'

Handle TimerState[MAXPLAYERS + 1] = INVALID_HANDLE;

ConVar g_hChatFlag;
int g_hFlag;

bool g_bClientHasPermission[MAXPLAYERS + 1] = false;

public Plugin myinfo = 
{
	name = "[CSGO] Entity - Requested Color Support", 
	author = "Entity", 
	description = "Support colors with chat tags", 
	version = "1.0"
};

public void OnPluginStart()
{
	LoadTranslations("ent_chatcolor.phrases");
	
	g_hChatFlag = CreateConVar("sm_ent_chatflag", "a", "The flag of the custom chat colors");
	
	AddCommandListener(OnMessageSent, "say");
	AddCommandListener(OnMessageSentTeam, "say_team");
	
	HookEvent("player_spawn", OnPlayerSpawn);
	
	AutoExecConfig(true, "ent_chatcolor");
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			if (TimerState[i] == INVALID_HANDLE)
			{
				TimerState[i] = CreateTimer(1.0, Timer_Analyze, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public Action OnPlayerSpawn(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (TimerState[client] == INVALID_HANDLE)
	{
		TimerState[client] = CreateTimer(1.0, Timer_Analyze, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void OnClientPostAdminCheck(int client)
{
	if (TimerState[client] == INVALID_HANDLE)
	{
		TimerState[client] = CreateTimer(1.0, Timer_Analyze, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action OnMessageSent(int client, const char[] command, int args)
{
	char message[1024], arg[128];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArgString(message, sizeof(message));
	if (IsValidClient(client) && arg[0] != '/')
	{			
		SendMessage(client, message, false);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action OnMessageSentTeam(int client, const char[] command, int args)
{
	char message[1024], arg[128];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArgString(message, sizeof(message));
	if (IsValidClient(client) && arg[0] != '/')
	{		
		SendMessage(client, message, true);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

stock void SendMessage(int client, char h_strMessage[1024], bool teamchat)
{	
	PlayerInformations(client);

	char name[MAX_NAME_LENGTH], chatMsg[1280], TeamColor[16];
	GetClientName(client, name, sizeof(name));
	
	StripQuotes(h_strMessage);
	
	int ClientTeam = GetClientTeam(client);
	if (ClientTeam == 2) TeamColor = "\x09";
	else TeamColor = "\x0B";
	
	if (g_bClientHasPermission[client] == true)
	{
		ReplaceString(h_strMessage, sizeof(h_strMessage), "{white}", "\x01", false);
		ReplaceString(h_strMessage, sizeof(h_strMessage), "{default}", "\x03", false);
		ReplaceString(h_strMessage, sizeof(h_strMessage), "{red}", "\x02", false); 
		ReplaceString(h_strMessage, sizeof(h_strMessage), "{team}", "\x03", false); 
		ReplaceString(h_strMessage, sizeof(h_strMessage), "{green}", "\x04", false); 
		ReplaceString(h_strMessage, sizeof(h_strMessage), "{turquoise}", "\x05", false); 
		ReplaceString(h_strMessage, sizeof(h_strMessage), "{cyan}", "\x05", false); 
		ReplaceString(h_strMessage, sizeof(h_strMessage), "{lime}", "\x06", false); 
		ReplaceString(h_strMessage, sizeof(h_strMessage), "{lightred}", "\x07", false); 
		ReplaceString(h_strMessage, sizeof(h_strMessage), "{lightgray}", "\x08", false); 
		ReplaceString(h_strMessage, sizeof(h_strMessage), "{yellow}", "\x09", false); 
		ReplaceString(h_strMessage, sizeof(h_strMessage), "{gray}", "\x0A", false); 
		ReplaceString(h_strMessage, sizeof(h_strMessage), "{darkblue}", "\x0C", false); 
		ReplaceString(h_strMessage, sizeof(h_strMessage), "{blue}", "\x0B", false); 
		ReplaceString(h_strMessage, sizeof(h_strMessage), "{pink}", "\x0E", false); 
		ReplaceString(h_strMessage, sizeof(h_strMessage), "{violet}", "\x0E", false); 
		ReplaceString(h_strMessage, sizeof(h_strMessage), "{orange}", "\x10", false); 
		
		CFormatColor(h_strMessage, sizeof(h_strMessage), client);
		Format(chatMsg, sizeof(chatMsg), "%s%s: \x01%s", TeamColor, name, h_strMessage);
	}
	else
	{
		CRemoveTags(h_strMessage, sizeof(h_strMessage));
		Format(chatMsg, sizeof(chatMsg), "%s%s: \x01%s", TeamColor, name, h_strMessage);
	}

	if (teamchat)
	{
		int team = GetClientTeam(client);

		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == team)
			{
				if (GetClientTeam(client) == 1)
				{
					CPrintToChatEx(i, client, "\x07%t %s", "Spec_Team", chatMsg);
				}
				else if (IsPlayerAlive(client))
				{
					CPrintToChatEx(i, client, "\x07%t %s", "Team", chatMsg);
				}
				else
				{
					CPrintToChatEx(i, client, "\x07%t%t %s", "Dead", "Team", chatMsg);
				}
			}
		}
	}
	else
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
			{
				if (GetClientTeam(client) == 1)
				{
					CPrintToChatEx(i, client, "\x07%t %s", "Spec", chatMsg);
				}
				else if (IsPlayerAlive(client))
				{
					CPrintToChatEx(i, client, "%s", chatMsg);
				}
				else
				{
					if (!IsPlayerAlive(i))
					{
						CPrintToChatEx(i, client, "\x07%t %s", "Dead", chatMsg);
					}
					else
					{
						CPrintToChatEx(i, client, "\x07%t %s", "Dead", chatMsg);
					}
				}
			}
		}
	}
}

stock bool IsValidClient(int client, bool alive = false, bool bots = false)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && (alive == false || IsPlayerAlive(client)) && (bots == false && !IsFakeClient(client)))
	{
		return true;
	}
	return false;
}

public void PlayerInformations(int client)
{
	if (IsValidClient(client))
	{		
		char flag[8];
		GetConVarString(g_hChatFlag, flag, sizeof(flag));
		if (StrEqual(flag, "a")) g_hFlag = ADMFLAG_RESERVATION;
		else if (StrEqual(flag, "b")) g_hFlag = ADMFLAG_GENERIC;
		else if (StrEqual(flag, "c")) g_hFlag = ADMFLAG_KICK;
		else if (StrEqual(flag, "d")) g_hFlag = ADMFLAG_BAN;
		else if (StrEqual(flag, "e")) g_hFlag = ADMFLAG_UNBAN;
		else if (StrEqual(flag, "f")) g_hFlag = ADMFLAG_SLAY;
		else if (StrEqual(flag, "g")) g_hFlag = ADMFLAG_CHANGEMAP;
		else if (StrEqual(flag, "h")) g_hFlag = ADMFLAG_CONVARS;
		else if (StrEqual(flag, "i")) g_hFlag = ADMFLAG_CONFIG;
		else if (StrEqual(flag, "j")) g_hFlag = ADMFLAG_CHAT;
		else if (StrEqual(flag, "k")) g_hFlag = ADMFLAG_VOTE;
		else if (StrEqual(flag, "l")) g_hFlag = ADMFLAG_PASSWORD;
		else if (StrEqual(flag, "m")) g_hFlag = ADMFLAG_RCON;
		else if (StrEqual(flag, "n")) g_hFlag = ADMFLAG_CHEATS;
		else if (StrEqual(flag, "z")) g_hFlag = ADMFLAG_ROOT;
		else if (StrEqual(flag, "o")) g_hFlag = ADMFLAG_CUSTOM1;
		else if (StrEqual(flag, "p")) g_hFlag = ADMFLAG_CUSTOM2;
		else if (StrEqual(flag, "q")) g_hFlag = ADMFLAG_CUSTOM3;
		else if (StrEqual(flag, "r")) g_hFlag = ADMFLAG_CUSTOM4;
		else if (StrEqual(flag, "s")) g_hFlag = ADMFLAG_CUSTOM5;
		else if (StrEqual(flag, "t")) g_hFlag = ADMFLAG_CUSTOM6;
		else
		{
			SetFailState("[ENTVIP] - The given flag is invalid in sm_ent_chatflag");
		}
		
		int flags = GetUserFlagBits(client);		
		if (flags & g_hFlag)
		{
			g_bClientHasPermission[client] = true;
		}
		else
		{
			g_bClientHasPermission[client] = false;
		}
	}
}

public Action Timer_Analyze(Handle timer, int client)
{
	PlayerInformations(client);
	return Plugin_Continue;
}