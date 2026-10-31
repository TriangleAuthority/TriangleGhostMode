// DIFF-07: when guards knock Geralt out (CR4Player.OnDeath with a guard as the attacker, the Unconscious
// state's killedByGuard branch), they take a quarter of his money on every difficulty mode, with no cap
// (legacy's rule, owner's decision DD2). 5.x: 25/40/65/85% by mode, at most 750/1,250/1,750/2,250 crowns.
// See docs/features/diff.md.
@replaceMethod(CR4PlayerStateUnconscious)
function TakeMoneyFromPlayer()
{
	var amount : float = thePlayer.GetMoney() * 0.25;	//modSigns: guards take a quarter of Geralt's money on every mode, no cap
	//modSigns: removed 5.x's finalAmount and its switch on theGame.GetDifficultyLevel() (25/40/65/85%, capped at 750/1,250/1,750/2,250)

	thePlayer.RemoveMoney((int)amount);	//modSigns
}
