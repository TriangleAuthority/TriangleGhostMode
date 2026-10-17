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
