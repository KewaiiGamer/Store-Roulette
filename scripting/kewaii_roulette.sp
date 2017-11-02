#pragma semicolon 1
#include <csgocolors>
#include <store>
#pragma newdecls required

int ScrollTimes[MAXPLAYERS + 1];
int WinNumber[MAXPLAYERS + 1];
int betAmount[MAXPLAYERS + 1];
bool isSpinning[MAXPLAYERS + 1] = false;

#define PLUGIN_NAME "Store Roulette"
#define PLUGIN_AUTHOR "Kewaii"
#define PLUGIN_DESCRIPTION "Zephyrus Store Roulette"
#define PLUGIN_VERSION "1.3.1"
#define PLUGIN_TAG "{pink}[Roulette by Kewaii]{green}"

public Plugin myinfo =
{
    name        =    PLUGIN_NAME,
    author        =    PLUGIN_AUTHOR,
    description    =    PLUGIN_DESCRIPTION,
    version        =    PLUGIN_VERSION,
    url            =    "http://steamcommunity.com/id/KewaiiGamer"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_roleta", CommandRoulette);
	RegConsoleCmd("sm_roulette", CommandRoulette);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			OnClientPostAdminCheck(i);
		}
	}
	LoadTranslations("kewaii_roulette.phrases");
}

public void OnClientPostAdminCheck(int client)
{
	isSpinning[client] = false;
}

public Action CommandRoulette(int client, int args)
{
	if (client > 0 && args < 1)
	{		
		CreateRouletteMenu(client).Display(client, 10);	
	}
	return Plugin_Handled;
}

Menu CreateRouletteMenu(int client)
{
	Menu menu = new Menu(RouletteMenuHandler);
	char buffer[128];
	Format(buffer, sizeof(buffer), "%T", "ChooseType", client);
	menu.SetTitle(buffer);	
	menu.AddItem("player", "Player");
	menu.AddItem("vip", "VIP", !HasClientFlag(client, ADMFLAG_CUSTOM1) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);	
	return menu;
}

public int RouletteMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(IsClientInGame(client))
			{
				char option[32];
				menu.GetItem(selection, option, sizeof(option));
				if (StrEqual(option, "player"))
				{
					CreatePlayerRouletteMenu(client).Display(client, MENU_TIME_FOREVER);
				}
				if (StrEqual(option, "vip"))
				{
					CreateVIPRouletteMenu(client).Display(client, MENU_TIME_FOREVER);
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}


Menu CreatePlayerRouletteMenu(int client)
{
	Menu menu = new Menu(CreditsChosenMenuHandler);
	char buffer[128];
	Format(buffer, sizeof(buffer), "%T", "ChooseCredits", client, Store_GetClientCredits(client));
	menu.SetTitle(buffer);	
	menu.AddItem("50", "50");
	menu.AddItem("100", "100");	
	menu.AddItem("250", "250");	
	menu.AddItem("500", "500");	
	menu.ExitBackButton = true;
	return menu;
}


Menu CreateVIPRouletteMenu(int client)
{
	Menu menu = new Menu(CreditsChosenMenuHandler);
	char buffer[128];
	Format(buffer, sizeof(buffer), "%T", "ChooseCredits", client, Store_GetClientCredits(client));
	menu.SetTitle(buffer);	
	menu.AddItem("1000", "1000");
	menu.AddItem("5000", "2500");	
	menu.AddItem("5000", "5000");	
	menu.AddItem("10000", "10000");	
	menu.ExitBackButton = true;
	return menu;
}

public int CreditsChosenMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(IsClientInGame(client))
			{
				char option[32];
				menu.GetItem(selection, option, sizeof(option));
								
				int crd = Store_GetClientCredits(client);
				int bet = StringToInt(option);
				if(crd >= bet)
				{
					if (!isSpinning[client])
					{
						Store_SetClientCredits(client, crd - bet);
						betAmount[client] = bet;
						SpinCredits(client);
						isSpinning[client] = true;
					}
					else
					{
						CPrintToChat(client, "%s %t", PLUGIN_TAG, "AlreadySpinning");
					}
				} 
				else
				{
					CPrintToChat(client, "%s %t", PLUGIN_TAG, bet - crd, "NoEnoughCredits");
					delete menu;
				}
			}
		}
		case MenuAction_Cancel:
		{
			if (IsClientInGame(client) && selection == MenuCancel_ExitBack)
			{
				CreateRouletteMenu(client).Display(client, 10);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public void SpinCredits(int client)
{
	int	FakeNumber = GetRandomInt(0,999);
	PrintHintText(client, "<font color='#ff0000'>[Roulette]</font><font color='#00ff00'> Number:</font><font color='#0000ff'> %i", FakeNumber);
	if(ScrollTimes[client] == 0)
	{
		ClientCommand(client, "playgamesound *ui/csgo_ui_crate_open.wav");
	}
	if(ScrollTimes[client] < 20)
	{
		CreateTimer(0.05, TimerNext, client);
		ScrollTimes[client] += 1;
		ClientCommand(client, "playgamesound *ui/csgo_ui_crate_item_scroll.wav");
	} 
	else if(ScrollTimes[client] < 30)
	{
		float AddSomeTime = 0.05 * ScrollTimes[client] / 3;
		CreateTimer(AddSomeTime, TimerNext, client);
		ScrollTimes[client] += 1;
		ClientCommand(client, "playgamesound *ui/csgo_ui_crate_item_scroll.wav");
	}
	else if(ScrollTimes[client] == 30)
	{
		int troll = GetRandomInt(1,2);
		if(troll == 1)
		{
			ClientCommand(client, "playgamesound *ui/csgo_ui_crate_item_scroll.wav");
			ScrollTimes[client] += 1;
			CreateTimer(1.5, TimerNext, client);
		}
		else
		{
			ClientCommand(client, "playgamesound *ui/csgo_ui_crate_item_scroll.wav");
			CreateTimer(1.5, TimerFinishing, client);
			WinNumber[client] = FakeNumber;
			ScrollTimes[client] = 0;
		}
	} 
	else
	{
		ClientCommand(client, "playgamesound *ui/csgo_ui_crate_item_scroll.wav");
		CreateTimer(1.5, TimerFinishing, client);
		WinNumber[client] = FakeNumber;
		ScrollTimes[client] = 0;
	}
}

public Action TimerFinishing(Handle timer, any client)
{
	if (IsClientInGame(client))
	{
		WinCredits(client, WinNumber[client], betAmount[client]);
		isSpinning[client] = false;
	}
}

public void WinCredits(int client, int Number, int Bet)
{
	if(IsClientInGame(client))
	{
		CPrintToChat(client, "%s %t", PLUGIN_TAG, "WinNumber", Number);		
		int multiplier;
		if(Number == 0)
		{
			multiplier = 25;
			ClientCommand(client, "playgamesound *ui/item_drop6_ancient.wav");
		}
		else if(Number > 0 && Number <= 500)
		{
			ClientCommand(client, "playgamesound music/skog_01/lostround.mp3");
			CPrintToChat(client, "%s %t", PLUGIN_TAG, "YouLost", Bet);
		}
		else if(Number > 500 && Number <= 600)
		{			
			multiplier = 0;
			ClientCommand(client, "playgamesound *ui/item_drop1_common.wav");
			CPrintToChat(client, "%s %t", PLUGIN_TAG, "NoLoseNoWin");
		} 
		else if(Number > 600 && Number <= 750)
		{
			multiplier = 1;
			ClientCommand(client, "playgamesound *ui/item_drop2_uncommon.wav");
		}
		else if(Number > 750 && Number <= 850)
		{
			multiplier = 2;
			ClientCommand(client, "playgamesound *ui/item_drop2_uncommon.wav");
		} 
		else if(Number > 850 && Number <= 925)
		{
			multiplier = 3;
			ClientCommand(client, "playgamesound *ui/item_drop3_rare.wav");
		}
		else if(Number > 925 && Number <= 965)
		{			
			multiplier = 4;
			ClientCommand(client, "playgamesound *ui/item_drop3_rare.wav");
		} 
		else if(Number > 965 && Number <= 996)
		{
			multiplier = 5;
			ClientCommand(client, "playgamesound *ui/item_drop3_rare.wav");
		}
		else if(Number == 997)
		{
			multiplier = 10;
			ClientCommand(client, "playgamesound *ui/item_drop3_rare.wav");
		} 
		else if(Number == 998)
		{
			multiplier = 15;
			ClientCommand(client, "playgamesound *ui/item_drop3_rare.wav");
		} 
		else if(Number == 999)
		{
			multiplier = 20;
			ClientCommand(client, "playgamesound *ui/item_drop6_ancient.wav");
		} 
		else
		{		
			ClientCommand(client, "playgamesound *ui/item_drop1_common.wav");
			CPrintToChat(client, "%s %t", PLUGIN_TAG, "NoLoseNoWin");		
			Store_SetClientCredits(client, Store_GetClientCredits(client) + (Bet));
		}	
		if (Number == 0 || Number > 600)
		{		
			CPrintToChat(client, "%s %t", PLUGIN_TAG, "YouWin", Bet * multiplier, multiplier);
		}
		if (Number == 0 || Number > 500)
		{
			Store_SetClientCredits(client, Store_GetClientCredits(client) + Bet * (multiplier + 1));		
		}
	}
}

public Action TimerNext(Handle timer, any client)
{
	if (IsClientInGame(client))
	{
		SpinCredits(client);
	}
}

public bool HasClientFlag(int client, int flag)
{
	return CheckCommandAccess(client, "", flag, true);
}