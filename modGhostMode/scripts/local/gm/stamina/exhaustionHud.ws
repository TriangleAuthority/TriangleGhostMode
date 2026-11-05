// STAM-10 (HUD): while Geralt's max stamina is lowered (exhaustion.ws), the wolf head's stamina bar is drawn
// against the full max, and its red "stamina needed" stretch is held at the lowered max (vanilla's indication
// still shows for its 2 s, then the hold resumes). The low-stamina sound and "recharged" cue and the sign icon
// follow the lowered max: at the lowered max the icon is un-dimmed (the bar's fraction is below 1, which dims
// it in Flash); the sign-ready flash animation does not play then. Without stacks, and for Ciri, vanilla's
// behaviour. How it looks has not been seen. See docs/features/stam.md.

@addField(CR4HudModuleWolfHead)
var gmExhNeededUntil : float;		// vanilla's "stamina needed" indication shows until then

@addField(CR4HudModuleWolfHead)
var gmExhHeldFrame : int;			// the frame the red stretch is held at (0: not held, -1: to set again)

@addField(CR4HudModuleWolfHead)
var gmExhAmount : CScriptedFlashSprite;

@addField(CR4HudModuleWolfHead)
var gmExhSetSignIconDimmed : CScriptedFlashFunction;

@addField(CR4HudModuleWolfHead)
var gmExhIconUndimmed : int;		// times the icon was un-dimmed (for tests)

// The bar's full max: the full max while Geralt's max stamina is lowered, else the max given.
function GMExhHudFullMax(curMax : float) : float
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	if(!w || thePlayer != w || w.GMExhStacks() <= 0)
		return curMax;
	return w.GMFullMaxStamina();
}

@addMethod(CR4HudModuleWolfHead)
function GMExhAmountSprite() : CScriptedFlashSprite
{
	var bar : CScriptedFlashSprite;

	if(!gmExhAmount)
	{
		bar = GetModuleFlash().GetChildFlashSprite("mcStaminaBar");
		if(bar)
			gmExhAmount = bar.GetChildFlashSprite("mcAmount");
	}
	return gmExhAmount;
}

@addMethod(CR4HudModuleWolfHead)
function GMExhSignIconDimmedFn() : CScriptedFlashFunction
{
	if(!gmExhSetSignIconDimmed)
		gmExhSetSignIconDimmed = GetModuleFlash().GetMemberFlashFunction("setSignIconDimmed");
	return gmExhSetSignIconDimmed;
}

// Right after setStamina (which dims the icon below a fraction of 1): un-dimmed at the lowered max.
@addMethod(CR4HudModuleWolfHead)
function GMExhSignIcon(cur : float, loweredMax : float, fullMax : float)
{
	var fn : CScriptedFlashFunction;

	if(fullMax <= loweredMax || cur < loweredMax)
		return;
	fn = GMExhSignIconDimmedFn();
	if(fn)
	{
		fn.InvokeSelfOneArg(FlashArgBool(false));
		gmExhIconUndimmed += 1;
	}
}

// Every tick: the red stretch held at the lowered max, outside vanilla's indication; put back when the
// stacks are gone.
@addMethod(CR4HudModuleWolfHead)
function GMExhHoldOverlay(loweredMax : float, fullMax : float)
{
	var amount : CScriptedFlashSprite;
	var frame : int;

	if(theGame.GetEngineTimeAsSeconds() < gmExhNeededUntil)
	{
		if(gmExhHeldFrame != 0)
			gmExhHeldFrame = -1;
		return;
	}
	if(fullMax > loweredMax + 0.001)
		frame = Max(1, FloorF(loweredMax / fullMax * 100));
	else
		frame = 0;
	if(frame == gmExhHeldFrame)
		return;
	amount = GMExhAmountSprite();
	if(!amount)
		return;
	if(frame > 0)
		amount.GotoAndStopFrameNumber(frame);
	else
		amount.GotoAndStopFrameNumber(1);
	gmExhHeldFrame = frame;
}

// 5.x body; changes marked //modSigns.
@replaceMethod(CR4HudModuleWolfHead)
function UpdateStamina() : void
{
	var l_curStamina 				: float;
	var l_curMaxStamina 			: float;
	var l_tooLowStaminaIndication 	: float = thePlayer.GetShowToLowStaminaIndication();
	var gmFullMax					: float;	//modSigns

	thePlayer.GetStats( BCS_Stamina, l_curStamina, l_curMaxStamina );
	gmFullMax = GMExhHudFullMax( l_curMaxStamina );	//modSigns: STAM-10, the full max while max stamina is lowered, else the max

	if ( m_LastStamina != l_curStamina || m_LastMaxStamina != l_curMaxStamina )
	{
		m_fxSetStamina.InvokeSelfOneArg( FlashArgNumber ( l_curStamina / gmFullMax ) );	//modSigns: of the full max
		GMExhSignIcon( l_curStamina, l_curMaxStamina, gmFullMax );	//modSigns: STAM-10, the sign icon at the lowered max

		m_LastStamina 	 = l_curStamina;
		m_LastMaxStamina = l_curMaxStamina;

		if ( l_curStamina <= l_curMaxStamina*0.60 )
			playStaminaSoundCue = true;

		if ( l_curStamina <= 0 )
		{
			thePlayer.SoundEvent("gui_no_stamina");

		}
		else if ( l_curStamina >= l_curMaxStamina && playStaminaSoundCue )
		{
			thePlayer.SoundEvent("gui_stamina_recharged");

			playStaminaSoundCue = false;
		}
	}

	if( l_tooLowStaminaIndication > 0 )
	{
		m_fxShowStaminaNeeded.InvokeSelfOneArg( FlashArgNumber ( l_tooLowStaminaIndication / gmFullMax ) );	//modSigns: of the full max
		thePlayer.SetShowToLowStaminaIndication( 0 );
		gmExhNeededUntil = theGame.GetEngineTimeAsSeconds() + 2.0;	//modSigns: STAM-10, vanilla's indication shows for 2 s (Flash)
	}
	GMExhHoldOverlay( l_curMaxStamina, gmFullMax );	//modSigns: STAM-10, the red stretch held at the lowered max
}
