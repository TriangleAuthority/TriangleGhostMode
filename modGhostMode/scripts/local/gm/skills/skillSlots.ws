// SKL-01: skill slots unlock by Geralt's level, as in 1.32 and legacy Ghost Mode (the slots'
// unlockedOnLevel: 0, 2, 4, 6, 8, 10, 12, 15, 18, 22, 26, 30). 5.x compares the same numbers
// with the total of skill points instead, so Places of Power and quest items open slots early,
// and a change to the skill point income would change the pace of slots.
// See docs/features/skl.md.

// The slots outside the mutation group follow the level. With lock, a slot above the level is
// locked again (on load, as legacy's PostInit); without, slots are only opened.
@addMethod(W3PlayerAbilityManager)
function GMUpdateSkillSlotsByLevel(lock : bool)
{
	var witcher : W3PlayerWitcher;
	var i, playerLevel : int;

	witcher = (W3PlayerWitcher)owner;
	if(!witcher || !witcher.levelManager)
		return;
	playerLevel = witcher.GetLevel();
	for(i = 0; i < skillSlots.Size(); i += 1)
	{
		if(skillSlots[i].groupID == MUTATION_SKILL_GROUP_ID)
			continue;
		if(playerLevel >= skillSlots[i].unlockedOnLevel)
			skillSlots[i].unlocked = true;
		else if(lock)
			skillSlots[i].unlocked = false;
	}
}

// Called when a level or skill points are gained and when the new character menu opens.
@replaceMethod(W3PlayerAbilityManager)
function UpdateSkillSlots()
{
	GMUpdateSkillSlotsByLevel(false);	//modSigns: by level, not by skill points
}

// On spawn and load. 5.x's own rule reads the points through GetWitcherPlayer(), which leaves
// every slot but the first locked after a load.
@wrapMethod(W3PlayerAbilityManager)
function PostInit()
{
	wrappedMethod();
	GMUpdateSkillSlotsByLevel(true);
	GMEnsureSkillTreeProfile();	// SKL-02
}

// 5.x's one-time conversion of saves from before 5.0 (NGEFixSkillPoints).
@wrapMethod(W3PlayerAbilityManager)
function RemasterSkillSlotReset()
{
	wrappedMethod();
	GMUpdateSkillSlotsByLevel(true);
}

// SKL-01 (D43), legacy's slot fixes (bugfixes 83-84 and 179). 5.x still counts a skill in a locked slot
// as equipped (IsSkillEquipped reads every slot), but its UnequipSkill refuses a locked slot, so such a
// skill cannot be removed. A slot locks with a skill in it when a save loads below the slot's level
// (GMUpdateSkillSlotsByLevel(true)) or when the mutation is unequipped outside the character menu.
@replaceMethod(W3PlayerAbilityManager)
function UnequipSkill(slotID : int) : bool
{
	var idx : int;
	var prevColor : ESkillColor;
	var skill : ESkill;

	idx = GetSkillSlotIndex(slotID, false);	//modSigns: a skill in a locked slot can be removed too
	if(idx < 0)
		return false;
	
	
	skill = skillSlots[idx].socketedSkill;	
	if( skill == S_SUndefined )
	{
		return false;
	}
	
	
	skillSlots[idx].socketedSkill = S_SUndefined;
	prevColor = GetSkillGroupColor(skillSlots[idx].groupID);
	OnSkillUnequip(skill);
	
	return true;
}

// Legacy's CheckAdditionalSlots: the skills in locked slots are unequipped. Returns whether any was.
@addMethod(W3PlayerAbilityManager)
function GMUnequipSkillsInLockedSlots() : bool
{
	var i : int;
	var changed : bool;

	for(i = 0; i < skillSlots.Size(); i += 1)
	{
		if(!skillSlots[i].unlocked && skillSlots[i].socketedSkill != S_SUndefined)
		{
			UnequipSkill(skillSlots[i].id);
			changed = true;
		}
	}
	return changed;
}

// When the character menu opens (the new menu, which also draws the classic tree, SKL-02), before it
// builds its data.
@wrapMethod(CR4CharacterDupeMenu)
function OnConfigUI()
{
	var pam : W3PlayerAbilityManager;

	pam = (W3PlayerAbilityManager)GetWitcherPlayer().abilityManager;
	if(pam)
	{
		pam.UpdateSkillSlots();
		pam.GMUnequipSkillsInLockedSlots();
	}
	wrappedMethod();
}

// A swap that puts a skill into a mutation slot (BSS_SkillSlot1 to 4) needs the skill's colour among the
// equipped mutation's colours, as an equip does; both slots are emptied before the skills go back in,
// so each skill's bonuses are applied once (5.x equips the first skill while it still sits in the other
// slot, and the unequip from that slot then takes away what its equip had added: Sun and Stars' day and
// night abilities, for example).
@replaceMethod(CR4CharacterDupeMenu)
function OnSwapSkill(skill1 : ESkill, slotID1 : int, skill2 : ESkill, slotID2 : int)
{
	if (thePlayer.IsInCombat())
	{
		showNotification(GetLocStringByKeyExt("menu_cannot_perform_action_combat"));
		OnPlaySoundEvent("gui_global_denied");
	}
	else if(!GMSwapSkillColoursAllowed(skill1, slotID1, skill2, slotID2))	//modSigns
	{	//modSigns
		OnPlaySoundEvent("gui_global_denied");	//modSigns
	}	//modSigns
	else
	{
		thePlayer.UnequipSkill(slotID1);	//modSigns
		thePlayer.UnequipSkill(slotID2);	//modSigns
		thePlayer.EquipSkill(skill1, slotID1);
		thePlayer.EquipSkill(skill2, slotID2);
		
		UpdateAppliedSkills();
		UpdateSkillPoints();			
		UpdatePlayerStatisticsData();						
		UpdateGroupsData();
		UpdateMutagens();
		UpdateMasterMutation();
		
		OnPlaySoundEvent("gui_character_add_skill");

		m_fxPaperdollChanged.InvokeSelf();

		
		theGame.LogSkillActivated( SkillPathTypeToName(GetWitcherPlayer().GetSkillPathType(skill1)), SkillEnumToName(skill1), SkillEnumToRemasterName(skill1), slotID1 );
		theGame.LogSkillActivated( SkillPathTypeToName(GetWitcherPlayer().GetSkillPathType(skill2)), SkillEnumToName(skill2), SkillEnumToRemasterName(skill2), slotID2 );
	}
}

// Legacy's colour rule for a swap: a skill bound for a mutation slot must have one of the equipped
// mutation's colours (none equipped: no colour fits).
function GMSwapSkillColoursAllowed(skill1 : ESkill, slotID1 : int, skill2 : ESkill, slotID2 : int) : bool
{
	var witcher : W3PlayerWitcher;
	var mutationId : EPlayerMutationType;
	var mutation : SMutation;

	witcher = GetWitcherPlayer();
	mutationId = witcher.GetEquippedMutationType();
	if(mutationId != EPMT_None)
		mutation = witcher.GetMutation(mutationId);
	if(slotID1 >= BSS_SkillSlot1 && !mutation.colors.Contains(thePlayer.GetSkillColor(skill1)))
		return false;
	if(slotID2 >= BSS_SkillSlot1 && !mutation.colors.Contains(thePlayer.GetSkillColor(skill2)))
		return false;
	return true;
}

// SKL-01 (found in XP slice X5): the skill mutagen slots unlock by Geralt's level too, as in 1.32 and legacy Ghost Mode
// (their unlockedAtLevel). 5.x compares the same numbers with the total of skill points, so the new tree's smaller
// income (XP-09) and Places of Power would move them. The new character menu shows the same rule.
@replaceMethod(W3PlayerAbilityManager)
function IsSkillMutagenSlotUnlocked( eqSlot : EEquipmentSlots ) : bool
{
	var i : int;	//modSigns: no skill points read

	//modSigns: removed the skill points total (used, free, mutation research)
	i = GetMutagenSlotIndex( eqSlot );
	if( i<0 )
	{
		return false;
	}
	
	
	
	return ( ( W3PlayerWitcher ) owner ).GetLevel() >= mutagenSlots[ i ].unlockedAtLevel;	//modSigns: by level (1.32, legacy)
}

@replaceMethod(CR4CharacterDupeMenu)
function UpdateMutagens():void
{
	var idx               : int;
	var mutCount          : int;
	var slotUnlocked      : bool;
	var gfxMutSlot        : CScriptedFlashObject;
	var gfxMutSlotsList   : CScriptedFlashArray;
	var skillMutagenSlots : array<SMutagenSlot>;
	var currentMutSlot	  : SMutagenSlot;
	var invComponent      : CInventoryComponent;
	var playerInv 		  : W3GuiPlayerInventoryComponent;
	//modSigns: removed the skill points total (used, free, mutation research)
	
	invComponent = thePlayer.GetInventory();
	playerInv = new W3GuiPlayerInventoryComponent in this;
	playerInv.Initialize( invComponent );
	
	gfxMutSlotsList = m_flashValueStorage.CreateTempFlashArray();
	skillMutagenSlots = thePlayer.GetPlayerSkillMutagens();
	mutCount = skillMutagenSlots.Size();
	
	for (idx = 0; idx < mutCount; idx+=1)
	{
		currentMutSlot = skillMutagenSlots[idx];
		gfxMutSlot = m_flashValueStorage.CreateTempFlashObject();
		slotUnlocked = GetWitcherPlayer().GetLevel() >= currentMutSlot.unlockedAtLevel;	//modSigns: by level (1.32, legacy)
		
		gfxMutSlot.SetMemberFlashInt('slotId', currentMutSlot.equipmentSlot);
		gfxMutSlot.SetMemberFlashInt('groupId', currentMutSlot.skillGroupID);
		gfxMutSlot.SetMemberFlashString('slotType', currentMutSlot.equipmentSlot);
		gfxMutSlot.SetMemberFlashBool('unlocked', slotUnlocked);
		gfxMutSlot.SetMemberFlashInt('unlockedAtLevel', currentMutSlot.unlockedAtLevel);
		
		if (invComponent.IsIdValid(currentMutSlot.item))
		{
			playerInv.SetInventoryFlashObjectForItem(currentMutSlot.item, gfxMutSlot);
			gfxMutSlot.SetMemberFlashString('color', invComponent.GetSkillMutagenColor(currentMutSlot.item));
		}
		else
		{
			gfxMutSlot.SetMemberFlashString('color', SC_None);
		}
		gfxMutSlotsList.PushBackFlashObject(gfxMutSlot);
	}
	m_flashValueStorage.SetFlashArray( "character.skills.mutagens", gfxMutSlotsList);
}

// SKL-01 (XP audit F2): a locked skill or skill mutagen slot's tooltip in the new character menu (both trees) says
// the level it opens at, with 1.32's and legacy's text "Slot unlocked at level: N" (the classic menu's strings
// 1070951 and 1070952). 5.x's "Unlocked at N Ability Points acquired." is filled with the same number, which since
// SKL-01 and slice X5 is a level. The wrapper lets 5.x build its tooltip, then sets it again with the level text.
@wrapMethod(CR4CharacterDupeMenu)
function OnGetLockedTooltipData(unlockedAtLevel : int)
{
	wrappedMethod(unlockedAtLevel);
	GMSetLockedSlotTooltip(false, unlockedAtLevel);
}

@wrapMethod(CR4CharacterDupeMenu)
function OnGetMutagenLockedTooltipData(unlockedAtLevel : int)
{
	wrappedMethod(unlockedAtLevel);
	GMSetLockedSlotTooltip(true, unlockedAtLevel);
}

// The tooltip as 5.x's two events build it, with the level text.
@addMethod(CR4CharacterDupeMenu)
function GMSetLockedSlotTooltip(mutagen : bool, unlockedAtLevel : int)
{
	var resultGFxData : CScriptedFlashObject;

	resultGFxData = m_flashValueStorage.CreateTempFlashObject();
	if(mutagen)
		resultGFxData.SetMemberFlashString('skillName', GetLocStringByKeyExt("panel_character_tooltip_mutagen_locked_title"));
	else
		resultGFxData.SetMemberFlashString('skillName', GetLocStringByKeyExt("panel_character_tooltip_skill_locked_title"));
	resultGFxData.SetMemberFlashString('currentLevelDescription', GMLockedSlotDescription(mutagen, unlockedAtLevel));
	resultGFxData.SetMemberFlashString('nextLevelDescription', "");
	resultGFxData.SetMemberFlashString('skillLevelString', "");
	resultGFxData.SetMemberFlashInt('level', -1);
	resultGFxData.SetMemberFlashInt('maxLevel', -1);
	resultGFxData.SetMemberFlashNumber('requiredPointsSpent', -1);
	if(mutagen)
		resultGFxData.SetMemberFlashString('IconPath', "icons\Skills\mutagen_slot_locked.png");
	else
		resultGFxData.SetMemberFlashString('IconPath', "icons\Skills\skill_slot_locked.png");
	resultGFxData.SetMemberFlashBool('hasEnoughPoints', true);
	resultGFxData.SetMemberFlashInt('curSkillPoints', -1);
	m_flashValueStorage.SetFlashObject("context.tooltip.data", resultGFxData);
}

// 1.32's and legacy's locked-slot text (CR4CharacterMenu.OnGetLockedTooltipData, OnGetMutagenLockedTooltipData).
function GMLockedSlotDescription(mutagen : bool, unlockedAtLevel : int) : string
{
	if(mutagen)
		return GetLocStringByKeyExt("panel_character_tooltip_mutagen_locked_desc") + ": " + unlockedAtLevel;
	return GetLocStringByKeyExt("panel_character_tooltip_skill_locked_desc") + ": " + unlockedAtLevel;
}
