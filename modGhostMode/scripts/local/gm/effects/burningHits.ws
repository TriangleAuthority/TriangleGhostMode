// EFX-07: burning and hits (docs/features/efx.md). 1.32's and legacy's rule (DX1 (a), project owner,
// 2026-10-24): every hit but Igni's plays its hit reaction on a burning actor, Geralt or an NPC, and
// breaks its flailing at once. 5.x allows no hit reaction on a burning NPC for the first half of its
// burning: the NPC branch here, and the release in W3Effect_Burning.OnUpdate, which ENCH-13's
// replacement (enchantments/aardIgniWords.ws) no longer has.
// Save impact: none (allowedHits is a saved field: an NPC burning in a save keeps 5.x's array until its
// burning ends).

// 5.x's body with 1.32's allowed hits. Changes marked //modSigns.
@replaceMethod(W3Effect_Burning)
function CacheSettings()
{
	//modSigns: removed var i : int;
	super.CacheSettings();

	//modSigns: removed if(this.IsOnPlayer()) { (EFX-07: the rule below for every target, 1.32 and legacy)
	allowedHits[EHRT_Igni] = false;	//modSigns: EFX-07, every hit but Igni's allowed on Geralt and NPCs alike
	//modSigns: removed } else { allowedHits.Grow(...); every hit disallowed on an NPC } (5.x, EFX-07)


	blockedActions.PushBack(EIAB_CallHorse);
	blockedActions.PushBack(EIAB_Jump);
	blockedActions.PushBack(EIAB_ThrowBomb);
	blockedActions.PushBack(EIAB_UsableItem);
	blockedActions.PushBack(EIAB_Parry);
	blockedActions.PushBack(EIAB_Counter);


	vibratePadLowFreq = 0.1;
	vibratePadHighFreq = 0.2;
}
