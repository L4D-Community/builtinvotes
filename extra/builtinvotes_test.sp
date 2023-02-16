#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <builtinvotes>

Handle g_hVoteHandler = null;

public void OnPluginStart()
{
	RegAdminCmd("sm_builtinvotes_test", Cmd_BuiltinVotesTest, ADMFLAG_GENERIC);
}

public Action Cmd_BuiltinVotesTest(int iClient, int iArgs)
{
	StartBuiltinVote(iClient, (iArgs == 1));

	return Plugin_Handled;
}

void StartBuiltinVote(const int iInitiator, bool bPassData = false)
{
	if (IsNewBuiltinVoteAllowed()) {
		int iNumPlayers;
		int[] iPlayers = new int[MaxClients];
		for (int i = 1; i <= MaxClients; i++) {
			if (!IsClientInGame(i) || IsFakeClient(i)) {
				continue;
			}

			iPlayers[iNumPlayers++] = i;
		}

		g_hVoteHandler = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
		
		char sBuffer[64];
		Format(sBuffer, sizeof(sBuffer), "Builtinvote test!");
		SetBuiltinVoteArgument(g_hVoteHandler, sBuffer);
		SetBuiltinVoteInitiator(g_hVoteHandler, iInitiator);
		
		if (bPassData) {
			DataPack hPack = new DataPack();
			
			hPack.WriteString("UserData 1");
			hPack.WriteString("UserData 2");
			hPack.WriteCell(1);
			hPack.WriteCell(2);
		
			SetBuiltinVoteResultCallback(g_hVoteHandler, VoteResultHandlerUserData, hPack, BV_DATA_HNDL_CLOSE);
		} else {
			SetBuiltinVoteResultCallback(g_hVoteHandler, VoteResultHandler);
		}
	
		DisplayBuiltinVote(g_hVoteHandler, iPlayers, iNumPlayers, 20);
		//FakeClientCommand(iInitiator, "Vote Yes");
		return;
	}

	PrintToChat(iInitiator, "Builtinvote cannot be started now.");
}

public int VoteActionHandler(Handle hVote, BuiltinVoteAction iAction, int iParam1, int iParam2)
{
	switch (iAction) {
		case BuiltinVoteAction_End: {
			g_hVoteHandler = null;
			delete hVote;
		}
		case BuiltinVoteAction_Cancel: {
			DisplayBuiltinVoteFail(hVote, BuiltinVoteFail_Generic);
		}
	}
}

public void VoteResultHandlerUserData(Handle hVote, int iNumVotes, int iNumClients, \
									const int[][] iClientInfo, int iNumItems, const int[][] iItemInfo, DataPack hPack)
{
	for (int i = 0; i < iNumItems; i++) {
		if (iItemInfo[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES) {
			if (iItemInfo[i][BUILTINVOTEINFO_ITEM_VOTES] > (iNumClients / 2)) {
				hPack.Reset();
				
				char sBuffer1[32], sBuffer2[32];
				hPack.ReadString(sBuffer1, sizeof(sBuffer1));
				hPack.ReadString(sBuffer2, sizeof(sBuffer2));
				
				int iBuff1 = hPack.ReadCell();
				int iBuff2 = hPack.ReadCell();
				PrintToChatAll("String1: %s, String2: %s, int1: %d, int2: %d", sBuffer1, sBuffer2, iBuff1, iBuff2);
				
				DisplayBuiltinVotePass(hVote, "Builtinvote test end...");
				return;
			}
		}
	}

	DisplayBuiltinVoteFail(hVote, BuiltinVoteFail_Loses);
}

public void VoteResultHandler(Handle hVote, int iNumVotes, int iNumClients, \
									const int[][] iClientInfo, int iNumItems, const int[][] iItemInfo)
{
	for (int i = 0; i < iNumItems; i++) {
		if (iItemInfo[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES) {
			if (iItemInfo[i][BUILTINVOTEINFO_ITEM_VOTES] > (iNumClients / 2)) {
				DisplayBuiltinVotePass(hVote, "Builtinvote test end...");
				return;
			}
		}
	}

	DisplayBuiltinVoteFail(hVote, BuiltinVoteFail_Loses);
}
