// UI-09: the druid Yolar's map pin shows him as a herbalist (legacy). 5.x's ingredient buying in the
// alchemy menu stays as 5.x has it (Q2). See docs/features/ui.md.
@wrapMethod(W3MerchantComponent)
function GetMapPinType() : name
{
	var merchantNPC : W3MerchantNPC;

	merchantNPC = (W3MerchantNPC)GetEntity();
	if(merchantNPC && merchantNPC.HasTag('druid_yolar') && mapPinType != EMMPT_Herbalist)
		mapPinType = EMMPT_Herbalist;
	return wrappedMethod();
}
