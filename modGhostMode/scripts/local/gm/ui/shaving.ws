// UI-15: shaving from the inventory (legacy, changelist 866; DU10): the razor gets a "Use" input in
// Geralt's inventory; using it shaves Geralt (vanilla's ShaveGeralt_Quest), refreshes the paperdoll and
// says "Geralt is now clean-shaven". Its description (item override, gm_ui.xml): "Used for shaving.".
// See docs/features/ui.md.

@wrapMethod(W3InventoryGridContext)
function updateInputFeedback()
{
	wrappedMethod();
	if(invMenuRef && invComponentRef && invComponentRef.IsIdValid(currentItemId) && invMenuRef.GetCurrentInventoryState() == IMS_Player
		&& invComponentRef.GetItemName(currentItemId) == 'Razor')
	{
		AddInputBinding("panel_button_hud_interaction_useitem", "enter-gamepad_A", IK_E, true);
		m_managerRef.updateInputFeedback();
	}
}

@wrapMethod(W3InventoryGridContext)
function execurePrimaryAction()
{
	if(invComponentRef.IsIdValid(currentItemId) && invMenuRef.GetCurrentInventoryState() == IMS_Player && invComponentRef.GetItemName(currentItemId) == 'Razor')
	{
		GMShaveGeralt(invMenuRef);
		return;
	}
	wrappedMethod();
}

function GMShaveGeralt(menu : CR4InventoryMenu)
{
	ShaveGeralt_Quest();
	if(menu)
	{
		menu.GMUpdateFace();
		menu.showNotification(GetLocStringByKeyExt("gm_used_razor_success"));
	}
	theSound.SoundEvent("gui_inventory_other_attach");
}

// The paperdoll with the new face (legacy's UpdateFace).
@addMethod(CR4InventoryMenu)
function GMUpdateFace()
{
	PlayPaperdollAnimation('armor');
	UpdateGuiSceneEntityItems();
}
