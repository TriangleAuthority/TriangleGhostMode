// EFX-05: frost slowdown is shortened by the victim's frost resistance (legacy's default resistStat; 5.x
// and 1.32: not resisted). Its 7.5 s are in gm_effects.xml. See docs/features/efx.md.
class W3Effect_SlowdownFrost extends CBaseGameplayEffect
{
	default resistStat = CDS_FrostRes;	//modSigns
}
