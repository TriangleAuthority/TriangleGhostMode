// UI-10 and UI-11: the bestiary (UI-11 below).
// UI-10: the bestiary's kill count (legacy's, changelist 1167; DU6: ported with UI, counting from the
// mod's installation): a saved count per enemy type on Geralt, incremented where a kill would give
// experience (CNewNPC.CalculateExperiencePoints; guards count as humans without experience), and a "Kill
// count" entry in the bestiary with the totals (humans with Wild Hunt warriors, animals, monsters, unique
// creatures) and the kills by type. Legacy's enemy types and their names (gm_generic.ws, shared with XP),
// with the GM prefix. Save impact: a new saved field (counts start at 0 on an existing save).
// See docs/features/ui.md.

enum EGMEnemyType
{
	GMENT_GENERIC,
	GMENT_ANIMAL,
	GMENT_BOSS,
	//BASE:
	GMENT_HUMAN,
	GMENT_DOG,
	GMENT_WOLF,
	GMENT_BEAR,
	GMENT_BEAR_BERSERKER,
	GMENT_WILD_HUNT_WARRIOR,
	GMENT_WILD_HUNT_MINION,
	GMENT_NEKKER,
	GMENT_DROWNER,
	GMENT_ROTFIEND,
	GMENT_GHOUL,
	GMENT_ALGHOUL,
	GMENT_GRYPHON,
	GMENT_BASILISK,
	GMENT_COCKATRICE,
	GMENT_WYVERN,
	GMENT_FORKTAIL,
	GMENT_WATERHAG,
	GMENT_GRAVEHAG,
	GMENT_FOGLING,
	GMENT_WRAITH,
	GMENT_NIGHTWRAITH,
	GMENT_NOONWRAITH,
	GMENT_ENDRIAGA_WORKER,
	GMENT_ENDRIAGA_SOLDIER,
	GMENT_ENDRIAGA_TRUTEN,
	GMENT_FUGAS,
	GMENT_GARGOYLE,
	GMENT_ARACHAS,
	GMENT_ARACHAS_ARMORED,
	GMENT_ARACHAS_POISON,
	GMENT_WEREWOLF,
	GMENT_KATAKAN,
	GMENT_EKIMMA,
	GMENT_TROLL,
	GMENT_TROLL_ICE,
	GMENT_GOLEM,
	GMENT_ELEMENTAL,
	GMENT_ELEMENTAL_FIRE,
	GMENT_ELEMENTAL_ICE,
	GMENT_BIES,
	GMENT_CZART,
	GMENT_CYCLOPS,
	GMENT_SIREN,
	GMENT_HARPY,
	GMENT_ERYNIA,
	GMENT_LESSOG,
	//EP1:
	GMENT_BOAR,
	GMENT_BLACK_SPIDER,
	//EP2:
	GMENT_PANTHER,
	GMENT_SHARLEY,
	GMENT_DRACOLIZARD,
	GMENT_KIKIMORA_WORKER,
	GMENT_KIKIMORA_WARRIOR,
	GMENT_SCOLOPENDROMORPH,
	GMENT_ARCHESPOR,
	GMENT_SPRIGAN,
	GMENT_WIGHT,
	GMENT_BARGHEST,
	GMENT_NIGHTWRAITH_BANSHEE,
	GMENT_BRUXA,
	GMENT_ALP,
	GMENT_GRAVIER,
	GMENT_FLEDER,
	GMENT_PROTOFLEDER,
	GMENT_GARKAIN,
	GMENT_MAX_TYPES
};

function GMGetEnemyTypeByAbility( actor : CActor ) : EGMEnemyType
{
	//BOSSES:
	
	if(actor.HasAbility('mon_knight_giant')) return GMENT_BOSS;
	if(actor.HasAbility('mon_cloud_giant')) return GMENT_BOSS;
	if(actor.HasAbility('mon_fairytale_witch')) return GMENT_BOSS;
	if(actor.HasAbility('mon_broom_base')) return GMENT_BOSS;
	if(actor.HasAbility('mon_dettlaff_base')) return GMENT_BOSS;
	if(actor.HasAbility('mon_dettlaff_vampire_base')) return GMENT_BOSS;
	if(actor.HasAbility('mon_dettlaff_monster_base')) return GMENT_BOSS;
	if(actor.HasAbility('mon_dettlaff_construct_base')) return GMENT_BOSS;
	if(actor.HasAbility('mon_toad_base')) return GMENT_BOSS;
	if(actor.HasAbility('q604_caretaker')) return GMENT_BOSS;
	if(actor.HasAbility('olgierd_default_stats')) return GMENT_BOSS;
	if(actor.HasAbility('ethereal_default_stats')) return GMENT_BOSS;
	if(actor.HasAbility('mon_ice_giant')) return GMENT_BOSS;
	if(actor.HasAbility('mon_greater_miscreant')) return GMENT_BOSS;
	if(actor.HasAbility('mon_him')) return GMENT_BOSS;
	if(actor.HasAbility('mon_witch1')) return GMENT_BOSS;
	if(actor.HasAbility('mon_witch2')) return GMENT_BOSS;
	if(actor.HasAbility('mon_witch3')) return GMENT_BOSS;
	if(actor.HasAbility('mon_djinn')) return GMENT_BOSS;
	if(actor.HasAbility('mon_heart_miniboss')) return GMENT_BOSS;
	if(actor.HasAbility('WildHunt_Eredin')) return GMENT_BOSS;
	if(actor.HasAbility('WildHunt_Imlerith')) return GMENT_BOSS;
	if(actor.HasAbility('WildHunt_Caranthir')) return GMENT_BOSS;

	//EP2:
	
	if(actor.HasAbility('mon_sharley_young')) return GMENT_SHARLEY;
	if(actor.HasAbility('mon_sharley')) return GMENT_SHARLEY;
	if(actor.HasAbility('mon_sharley_base')) return GMENT_SHARLEY;

	if(actor.HasAbility('mon_bruxa')) return GMENT_BRUXA;
	if(actor.HasAbility('mon_alp')) return GMENT_BRUXA;
	if(actor.HasAbility('mon_vampiress_base')) return GMENT_BRUXA;

	if(actor.HasAbility('mon_draco_base')) return GMENT_DRACOLIZARD;

	if(actor.HasAbility('mon_barghest')) return GMENT_BARGHEST;
	if(actor.HasAbility('mon_barghest_wight_minion')) return GMENT_BARGHEST;
	if(actor.HasAbility('mon_barghest_base')) return GMENT_BARGHEST;

	if(actor.HasAbility('mon_black_spider_ep2_large')) return GMENT_BLACK_SPIDER;
	if(actor.HasAbility('mon_black_spider_ep2')) return GMENT_BLACK_SPIDER;
	if(actor.HasAbility('mon_black_spider_ep2_base')) return GMENT_BLACK_SPIDER;

	if(actor.HasAbility('mon_kikimora_warrior')) return GMENT_KIKIMORA_WARRIOR;
	if(actor.HasAbility('mon_kikimora_worker')) return GMENT_KIKIMORA_WORKER;
	if(actor.HasAbility('mon_kikimore_base')) return GMENT_KIKIMORA_WORKER;

	if(actor.HasAbility('mon_scolopendromorph_base')) return GMENT_SCOLOPENDROMORPH;

	if(actor.HasAbility('mon_archespor_hard')) return GMENT_ARCHESPOR;
	if(actor.HasAbility('mon_archespor')) return GMENT_ARCHESPOR;
	//if(actor.HasAbility('mon_archespor_turret')) return GMENT_ARCHESPOR;
	//if(actor.HasAbility('mon_archespor_petals')) return GMENT_ARCHESPOR;
	if(actor.HasAbility('mon_archespor_base')) return GMENT_ARCHESPOR;

	if(actor.HasAbility('mon_sprigan')) return GMENT_SPRIGAN;
	if(actor.HasAbility('mon_sprigan_base')) return GMENT_SPRIGAN;

	if(actor.HasAbility('mon_spooncollector')) return GMENT_WIGHT;
	if(actor.HasAbility('mon_wight')) return GMENT_WIGHT;

	if(actor.HasAbility('mon_gravier')) return GMENT_GRAVIER;

	if(actor.HasAbility('mon_nightwraith_banshee')) return GMENT_NIGHTWRAITH_BANSHEE;
	//if(actor.HasAbility('banshee_summons')) return GMENT_NIGHTWRAITH;

	if(actor.HasAbility('mon_fleder')) return GMENT_FLEDER;
	if(actor.HasAbility('q704_mon_protofleder')) return GMENT_PROTOFLEDER;
	if(actor.HasAbility('mon_garkain')) return GMENT_GARKAIN;

	if(actor.HasAbility('mon_panther')) return GMENT_PANTHER;
	if(actor.HasAbility('mon_panther_ghost')) return GMENT_PANTHER;
	if(actor.HasAbility('mon_panther_base')) return GMENT_PANTHER;

	if(actor.HasAbility('mon_boar_ep2_base')) return GMENT_BOAR;

	//EP1:

	if(actor.HasAbility('mon_nightwraith_iris')) return GMENT_NIGHTWRAITH;
	
	if(actor.HasAbility('HaklandMage')) return GMENT_HUMAN;
	if(actor.HasAbility('HaklandMagePhase1')) return GMENT_HUMAN;

	if(actor.HasAbility('mon_boar_base')) return GMENT_BOAR;

	if(actor.HasAbility('mon_black_spider_large')) return GMENT_BLACK_SPIDER;
	if(actor.HasAbility('mon_black_spider')) return GMENT_BLACK_SPIDER;
	if(actor.HasAbility('mon_black_spider_base')) return GMENT_BLACK_SPIDER;

	//Base game:
	
	if(actor.HasAbility('mon_endriaga_soldier_tailed')) return GMENT_ENDRIAGA_SOLDIER;
	if(actor.HasAbility('mon_endriaga_soldier_spikey')) return GMENT_ENDRIAGA_TRUTEN;
	if(actor.HasAbility('mon_endriaga_worker')) return GMENT_ENDRIAGA_WORKER;
	if(actor.HasAbility('mon_endriaga_base')) return GMENT_ENDRIAGA_WORKER;

	if(actor.HasAbility('mon_fugas')) return GMENT_FUGAS;
	if(actor.HasAbility('mon_fugas_lesser')) return GMENT_FUGAS;
	if(actor.HasAbility('mon_gargoyle')) return GMENT_GARGOYLE;
	if(actor.HasAbility('mon_fugas_base')) return GMENT_FUGAS;

	if(actor.HasAbility('mon_poison_arachas')) return GMENT_ARACHAS_POISON;
	if(actor.HasAbility('mon_arachas_armored')) return GMENT_ARACHAS_ARMORED;
	if(actor.HasAbility('mon_arachas')) return GMENT_ARACHAS;
	if(actor.HasAbility('mon_arachas_base')) return GMENT_ARACHAS;

	if(actor.HasAbility('mon_bear_berserker')) return GMENT_BEAR_BERSERKER;
	if(actor.HasAbility('mon_bear_black')) return GMENT_BEAR;
	if(actor.HasAbility('mon_bear_grizzly')) return GMENT_BEAR;
	if(actor.HasAbility('mon_bear_white')) return GMENT_BEAR;
	if(actor.HasAbility('mon_bear_fistfight')) return GMENT_BEAR;
	if(actor.HasAbility('mon_bear_base')) return GMENT_BEAR;

	if(actor.HasAbility('mon_werewolf_lesser')) return GMENT_WEREWOLF;
	if(actor.HasAbility('mon_werewolf')) return GMENT_WEREWOLF;
	if(actor.HasAbility('mon_lycanthrope')) return GMENT_WEREWOLF;
	if(actor.HasAbility('mon_katakan')) return GMENT_KATAKAN;
	if(actor.HasAbility('mon_katakan_large')) return GMENT_KATAKAN;
	if(actor.HasAbility('mon_ekimma')) return GMENT_EKIMMA;
	if(actor.HasAbility('mon_werewolf_base')) return GMENT_WEREWOLF;

	if(actor.HasAbility('mon_ice_troll')) return GMENT_TROLL_ICE;
	if(actor.HasAbility('mon_black_troll')) return GMENT_TROLL;
	if(actor.HasAbility('mon_cave_troll_young')) return GMENT_TROLL;
	if(actor.HasAbility('mon_cave_troll')) return GMENT_TROLL;
	if(actor.HasAbility('mon_troll_fistfight')) return GMENT_TROLL;
	if(actor.HasAbility('mon_troll_base')) return GMENT_TROLL;

	if(actor.HasAbility('mon_golem_lvl1')) return GMENT_GOLEM;
	if(actor.HasAbility('mon_golem')) return GMENT_GOLEM;
	if(actor.HasAbility('mon_elemental_dao_lesser')) return GMENT_ELEMENTAL;
	if(actor.HasAbility('mon_elemental_dao')) return GMENT_ELEMENTAL;
	if(actor.HasAbility('mon_ice_golem')) return GMENT_ELEMENTAL_ICE;
	if(actor.HasAbility('mon_elemental_fire')) return GMENT_ELEMENTAL_FIRE;
	if(actor.HasAbility('mon_elemental_fire_q211')) return GMENT_ELEMENTAL_FIRE;
	if(actor.HasAbility('mon_golem_base')) return GMENT_GOLEM;

	if(actor.HasAbility('mon_bies')) return GMENT_BIES;
	if(actor.HasAbility('mon_bies_lesser')) return GMENT_BIES;
	if(actor.HasAbility('mon_czart')) return GMENT_CZART;
	if(actor.HasAbility('mon_bies_base')) return GMENT_BIES;

	if(actor.HasAbility('mon_cyclops')) return GMENT_CYCLOPS;
	
	if(actor.HasAbility('mon_lamia')) return GMENT_SIREN;
	if(actor.HasAbility('mon_lamia_stronger')) return GMENT_SIREN;
	if(actor.HasAbility('mon_siren')) return GMENT_SIREN;
	if(actor.HasAbility('mon_siren_base')) return GMENT_SIREN;

	if(actor.HasAbility('mon_erynia')) return GMENT_ERYNIA;
	if(actor.HasAbility('mon_harpy')) return GMENT_HARPY;
	if(actor.HasAbility('mon_harpy_base')) return GMENT_HARPY;

	if(actor.HasAbility('mon_wraith')) return GMENT_WRAITH;
	if(actor.HasAbility('mon_wraith_mh')) return GMENT_WRAITH;
	if(actor.HasAbility('mon_wraith_base')) return GMENT_WRAITH;

	if(actor.HasAbility('mon_nightwraith')) return GMENT_NIGHTWRAITH;
	if(actor.HasAbility('mon_nightwraith_mh')) return GMENT_NIGHTWRAITH;
	if(actor.HasAbility('mon_pesta')) return GMENT_NOONWRAITH;
	if(actor.HasAbility('mon_noonwraith_mh')) return GMENT_NOONWRAITH;
	if(actor.HasAbility('mon_noonwraith')) return GMENT_NOONWRAITH;
	//if(actor.HasAbility('mon_noonwraith_doppelganger')) return GMENT_NOONWRAITH;
	if(actor.HasAbility('mon_noonwraith_base')) return GMENT_NOONWRAITH;

	if(actor.HasAbility('mon_nekker_warrior')) return GMENT_NEKKER;
	if(actor.HasAbility('mon_nekker')) return GMENT_NEKKER;
	if(actor.HasAbility('mon_nekker_base')) return GMENT_NEKKER;

	if(actor.HasAbility('mon_rotfiend_large')) return GMENT_ROTFIEND;
	if(actor.HasAbility('mon_rotfiend')) return GMENT_ROTFIEND;
	if(actor.HasAbility('mon_drowneddead')) return GMENT_DROWNER;
	if(actor.HasAbility('mon_drowner_underwater')) return GMENT_DROWNER;
	if(actor.HasAbility('mon_drowner')) return GMENT_DROWNER;
	if(actor.HasAbility('mon_drowner_base')) return GMENT_DROWNER;

	if(actor.HasAbility('mon_wild_hunt_minionMH')) return GMENT_WILD_HUNT_MINION;
	if(actor.HasAbility('mon_wild_hunt_minion')) return GMENT_WILD_HUNT_MINION;
	if(actor.HasAbility('mon_wild_hunt_minion_lesser')) return GMENT_WILD_HUNT_MINION;
	if(actor.HasAbility('mon_wild_hunt_minion_weak')) return GMENT_WILD_HUNT_MINION;
	if(actor.HasAbility('mon_alghoul')) return GMENT_ALGHOUL;
	if(actor.HasAbility('mon_ghoul_stronger')) return GMENT_GHOUL;
	if(actor.HasAbility('mon_ghoul')) return GMENT_GHOUL;
	if(actor.HasAbility('mon_ghoul_lesser')) return GMENT_GHOUL;
	if(actor.HasAbility('mon_ghoul_base')) return GMENT_GHOUL;

	if(actor.HasAbility('mon_gryphon_volcanic')) return GMENT_GRYPHON;
	if(actor.HasAbility('mon_gryphon_stronger')) return GMENT_GRYPHON;
	if(actor.HasAbility('mon_gryphon')) return GMENT_GRYPHON;
	if(actor.HasAbility('mon_gryphon_lesser')) return GMENT_GRYPHON;
	if(actor.HasAbility('mon_basilisk')) return GMENT_BASILISK;
	if(actor.HasAbility('mon_cockatrice')) return GMENT_COCKATRICE;
	if(actor.HasAbility('mon_gryphon_base')) return GMENT_GRYPHON;

	if(actor.HasAbility('mon_lessog_ancient')) return GMENT_LESSOG;
	if(actor.HasAbility('mon_lessog')) return GMENT_LESSOG;
	if(actor.HasAbility('mon_lessog_base')) return GMENT_LESSOG;

	if(actor.HasAbility('mon_forktail_mh')) return GMENT_FORKTAIL;
	if(actor.HasAbility('mon_forktail')) return GMENT_FORKTAIL;
	if(actor.HasAbility('mon_forktail_young')) return GMENT_FORKTAIL;
	if(actor.HasAbility('mon_wyvern')) return GMENT_WYVERN;
	if(actor.HasAbility('mon_wyvern_base')) return GMENT_WYVERN;

	//if(actor.HasAbility('mon_baronswife')) return GMENT_GRAVEHAG;
	if(actor.HasAbility('mon_gravehag')) return GMENT_GRAVEHAG;
	if(actor.HasAbility('mon_fogling_mh')) return GMENT_FOGLING;
	if(actor.HasAbility('mon_fogling_stronger')) return GMENT_FOGLING;
	if(actor.HasAbility('mon_fogling')) return GMENT_FOGLING;
	if(actor.HasAbility('mon_fogling_lesser')) return GMENT_FOGLING;
	//if(actor.HasAbility('mon_fogling_doppelganger')) return GMENT_FOGLING;
	if(actor.HasAbility('mon_waterhag_greater')) return GMENT_WATERHAG;
	if(actor.HasAbility('mon_waterhag')) return GMENT_WATERHAG;
	if(actor.HasAbility('mon_gravehag_base')) return GMENT_GRAVEHAG;

	if(actor.HasAbility('mon_wild_hunt_default')) return GMENT_WILD_HUNT_WARRIOR;

	if(actor.HasAbility('ConDefault')) return GMENT_HUMAN;
	if(actor.HasAbility('ConAverage')) return GMENT_HUMAN;
	if(actor.HasAbility('ConAthletic')) return GMENT_HUMAN;
	if(actor.HasAbility('ConFrail')) return GMENT_HUMAN;
	if(actor.HasAbility('ConFat')) return GMENT_HUMAN;
	if(actor.HasAbility('ConPudzian')) return GMENT_HUMAN;
	if(actor.HasAbility('ConWitcher')) return GMENT_HUMAN;
	if(actor.HasAbility('ConImmortal')) return GMENT_HUMAN;

	if(actor.HasAbility('mon_evil_dog_lvl12')) return GMENT_DOG;
	if(actor.HasAbility('wild_dog_lvl9')) return GMENT_DOG;
	if(actor.HasAbility('mon_evil_dog')) return GMENT_DOG;
	if(actor.HasAbility('mon_wolf')) return GMENT_WOLF;
	if(actor.HasAbility('mon_wolf_summon')) return GMENT_WOLF;
	if(actor.HasAbility('mon_wolf_summon_were')) return GMENT_WOLF;
	if(actor.HasAbility('mon_wolf_alpha')) return GMENT_WOLF;
	if(actor.HasAbility('mon_wolf_alpha_weak')) return GMENT_WOLF;
	if(actor.HasAbility('mon_wolf_white')) return GMENT_WOLF;
	if(actor.HasAbility('mon_wolf_base')) return GMENT_WOLF;

	if(actor.HasAbility('animal_rat_base')) return GMENT_ANIMAL;
	if(actor.HasAbility('animal_default_animal')) return GMENT_ANIMAL;

	return GMENT_GENERIC;
}

function GMGetLocStringByEnemyType( et : EGMEnemyType ) : string
{
	switch(et)
	{
		case GMENT_HUMAN:
			return GetLocStringByKeyExt("gm_kills_humans");
		case GMENT_WILD_HUNT_WARRIOR:
			return GetLocStringByKeyExt("gm_kills_wh_warriors");
		case GMENT_WILD_HUNT_MINION:
			return GetLocStringById(1077934);		//Hounds of the Wild Hunt
		case GMENT_DOG:
			return GetLocStringById(1077512);		//Dogs
		case GMENT_WOLF:
			return GetLocStringById(1077510);		//Wolves
		case GMENT_BEAR:
			return GetLocStringById(1077511);		//Bears
		case GMENT_BEAR_BERSERKER:
			return GetLocStringById(1077471);		//Berserkers
		case GMENT_ENDRIAGA_WORKER:
			return GetLocStringById(1077475);		//Endrega workers
		case GMENT_ENDRIAGA_SOLDIER:
			return GetLocStringById(339456);		//Endrega warriors
		case GMENT_ENDRIAGA_TRUTEN:
			return GetLocStringById(1077474);		//Endrega drones
		case GMENT_FUGAS:
			return GetLocStringById(1077882);		//Sylvans
		case GMENT_GARGOYLE:
			return GetLocStringById(1082623);		//Gargoyles
		case GMENT_ARACHAS:
			return GetLocStringById(1077760);		//Arachasae
		case GMENT_ARACHAS_ARMORED:
			return GetLocStringById(1077472);		//Armored Arachasae
		case GMENT_ARACHAS_POISON:
			return GetLocStringById(1077473);		//Venomous arachasae
		case GMENT_WEREWOLF:
			return GetLocStringById(593528);		//Werewolves
		case GMENT_KATAKAN:
			return GetLocStringById(354496);		//Katakans
		case GMENT_EKIMMA:
			return GetLocStringById(1077304);		//Ekimmaras
		case GMENT_TROLL_ICE:
			return GetLocStringById(1077498);		//Ice trolls
		case GMENT_TROLL:
			return GetLocStringById(1077612);		//Rock trolls
		case GMENT_GOLEM:
			return GetLocStringById(339451);		//Golems
		case GMENT_ELEMENTAL:
			return GetLocStringById(354371);		//Earth Elementals
		case GMENT_ELEMENTAL_FIRE:
			return GetLocStringById(1077469);		//Fire Elementals
		case GMENT_ELEMENTAL_ICE:
			return GetLocStringById(1077468);		//Ice Elementals
		case GMENT_BIES:
			return GetLocStringById(1077880);		//Fiends
		case GMENT_CZART:
			return GetLocStringById(1077881);		//Chorts
		case GMENT_CYCLOPS:
			return GetLocStringById(1077494);		//Cyclopses
		case GMENT_SIREN:
			return GetLocStringById(1077508);		//Sirens
		case GMENT_HARPY:
			return GetLocStringById(1077506);		//Harpies
		case GMENT_ERYNIA:
			return GetLocStringById(1077504);		//Erynias
		case GMENT_WRAITH:
			return GetLocStringById(1077489);		//Wraiths
		case GMENT_NIGHTWRAITH:
			return GetLocStringById(397223);		//Nightwraiths
		case GMENT_NOONWRAITH:
			return GetLocStringById(354483);		//Noonwraiths
		case GMENT_NEKKER:
			return GetLocStringById(1077497);		//Nekkers
		case GMENT_DROWNER:
			return GetLocStringById(1077480);		//Drowners
		case GMENT_ROTFIEND:
			return GetLocStringById(1077608);		//Rotfiends
		case GMENT_ALGHOUL:
			return GetLocStringById(339457);		//Alghouls
		case GMENT_GHOUL:
			return GetLocStringById(548214);		//Ghouls
		case GMENT_GRYPHON:
			return GetLocStringById(1077505);		//Griffins
		case GMENT_BASILISK:
			return GetLocStringById(339458);		//Basilisks
		case GMENT_COCKATRICE:
			return GetLocStringById(354425);		//Cockatrices
		case GMENT_LESSOG:
			return GetLocStringById(1077879);		//Leshens
		case GMENT_WYVERN:
			return GetLocStringById(1077487);		//Wyverns
		case GMENT_FORKTAIL:
			return GetLocStringById(1077488);		//Forktails
		case GMENT_GRAVEHAG:
			return GetLocStringById(1077483);		//Grave hags
		case GMENT_FOGLING:
			return GetLocStringById(1077481);		//Foglets
		case GMENT_WATERHAG:
			return GetLocStringById(1077484);		//Water hags
		//EP1:
		case GMENT_BOAR:
			return GetLocStringById(1139394);		//Wild Boars
			return GetLocStringById(1214837);		//Wild Boars
		case GMENT_BLACK_SPIDER:
			return GetLocStringById(1139683);		//Arachnomorph
			return GetLocStringById(1214635);		//Arachnomorph
		//EP2:
		case GMENT_SHARLEY:
			return GetLocStringById(1203524);		//Shaelmaars
		case GMENT_BRUXA:
			return GetLocStringById(1188873);		//Bruxae
		case GMENT_ALP:
			return GetLocStringById(1208707);		//Alps
		case GMENT_DRACOLIZARD:
			return GetLocStringById(1201766);		//Slyzards
		case GMENT_BARGHEST:
			return GetLocStringById(1208635);		//Barghests
		case GMENT_KIKIMORA_WORKER:
			return GetLocStringById(1208686);		//Kikimore Workers
		case GMENT_KIKIMORA_WARRIOR:
			return GetLocStringById(1208683);		//Kikimore Warrior
		case GMENT_SCOLOPENDROMORPH:
			return GetLocStringById(1203529);		//Giant Centipedes
		case GMENT_ARCHESPOR:
			return GetLocStringById(1208713);		//Archespores
		case GMENT_SPRIGAN:
			return GetLocStringById(1170003);		//Spriggans
		case GMENT_WIGHT:
			return GetLocStringById(1207197);		//Wights
		case GMENT_GRAVIER:
			return GetLocStringById(1190589);		//Scurvers
		case GMENT_NIGHTWRAITH_BANSHEE:
			return GetLocStringById(1213774);		//Beann'shies
		case GMENT_FLEDER:
			return GetLocStringById(1208893);		//Fleders
		case GMENT_PROTOFLEDER:
			return GetLocStringById(1206787);		//Protofleders
		case GMENT_GARKAIN:
			return GetLocStringById(1176357);		//Garkains
		case GMENT_PANTHER:
			return GetLocStringById(1208643);		//Panthers
		case GMENT_BOSS:
		case GMENT_GENERIC:
		case GMENT_ANIMAL:
		default:
			return "";
	}
	/*
			return 1077509;		//Succubi
			return 1078140;		//Godlings
			return 1082146;		//Doppler
	*/
}

@addField(W3PlayerWitcher)
saved var gmEnemiesKilledByType : array<int>;

@addMethod(W3PlayerWitcher)
function GMIncKills(et : EGMEnemyType)
{
	if(gmEnemiesKilledByType.Size() < (int)GMENT_MAX_TYPES)
		gmEnemiesKilledByType.Resize((int)GMENT_MAX_TYPES);
	gmEnemiesKilledByType[et] += 1;
}

@addMethod(W3PlayerWitcher)
function GMGetKills(et : EGMEnemyType) : int
{
	if((int)et >= gmEnemiesKilledByType.Size())
		return 0;
	return gmEnemiesKilledByType[et];
}

// A kill counts where it would give experience (legacy's CalculateExperiencePoints; the debug log's call
// with skipLog does not count).
@wrapMethod(CNewNPC)
function CalculateExperiencePoints(optional skipLog : bool) : int
{
	if(!skipLog && !grantNoExperienceAfterKill && !HasAbility('Zero_XP'))
	{
		if(GetNPCType() == ENGT_Guard)
			GetWitcherPlayer().GMIncKills(GMENT_HUMAN);
		else
			GetWitcherPlayer().GMIncKills(GMGetEnemyTypeByAbility(this));
	}
	return wrappedMethod(skipLog);
}

// The entry's text: the totals, then the kills by type.
function GMKillCountText() : string
{
	var description, finalDescription, locStr : string;
	var i, kills, total, humans, animals, monsters, bosses : int;
	var witcher : W3PlayerWitcher;

	witcher = GetWitcherPlayer();
	for(i = (int)GMENT_HUMAN; i < (int)GMENT_MAX_TYPES; i += 1)
	{
		kills = witcher.GMGetKills(i);
		if(kills > 0)
		{
			locStr = GMGetLocStringByEnemyType(i);
			if(locStr != "")
				description += locStr + ": " + kills + "<br>";
		}
		total += kills;
	}
	humans = witcher.GMGetKills(GMENT_HUMAN) + witcher.GMGetKills(GMENT_WILD_HUNT_WARRIOR);
	animals = witcher.GMGetKills(GMENT_DOG) + witcher.GMGetKills(GMENT_WOLF) + witcher.GMGetKills(GMENT_BEAR) + witcher.GMGetKills(GMENT_BOAR) + witcher.GMGetKills(GMENT_PANTHER);
	monsters = total - humans - animals;
	bosses = witcher.GMGetKills(GMENT_BOSS);
	total += bosses;
	finalDescription = GetLocStringByKeyExt("gm_kills_total") + ": " + total + "<br>" +
		GetLocStringByKeyExt("gm_kills_humans_total") + ": " + humans + "<br>" +
		GetLocStringByKeyExt("gm_kills_animals_total") + ": " + animals + "<br>" +
		GetLocStringByKeyExt("gm_kills_monsters_total") + ": " + monsters + "<br>" +
		GetLocStringByKeyExt("gm_kills_bosses_total") + ": " + bosses;
	if(description != "")
		finalDescription += "<br><br>" + GetLocStringByKeyExt("gm_kills_by_type") + ":<br>" + description;
	return finalDescription;
}

// The bestiary's list with the "Kill count" entry after the creatures (legacy). 5.x body; changes marked
// //modSigns.
@replaceMethod(CR4GlossaryBestiaryMenu)
function PopulateData()
{
	var l_DataFlashArray		: CScriptedFlashArray;
	var l_DataFlashObject 		: CScriptedFlashObject;

	var i, length				: int;
	var l_creature 				: CJournalCreature;
	var l_creatureGroup			: CJournalCreatureGroup;


	var l_Title					: string;
	var l_Tag					: name;
	var l_CategoryTag			: name;
	var l_IconPath				: string;
	var l_GroupTitle			: string;
	var l_IsNew					: bool;

	var expandedBestiaryCategories : array< name >;

	expandedBestiaryCategories = GetWitcherPlayer().GetExpandedBestiaryCategories();

	l_DataFlashArray = m_flashValueStorage.CreateTempFlashArray();
	length = allCreatures.Size();

	for( i = 0; i < length; i+= 1 )
	{
		l_creature = allCreatures[i];

		l_creatureGroup = (CJournalCreatureGroup)m_journalManager.GetEntryByGuid( l_creature.GetLinkedParentGUID() );
		l_GroupTitle = GetLocStringById( l_creatureGroup.GetNameStringId() );
		l_CategoryTag = l_creatureGroup.GetUniqueScriptTag();

		l_Title = GetLocStringById( l_creature.GetNameStringId() );
		l_Tag = l_creature.GetUniqueScriptTag();
		l_IconPath = thePlayer.ProcessGlossaryImageOverride( l_creature.GetImage(), l_Tag );
		l_IsNew	= m_journalManager.IsEntryUnread( l_creature );

		l_DataFlashObject = m_flashValueStorage.CreateTempFlashObject();

		l_DataFlashObject.SetMemberFlashUInt(  "tag", NameToFlashUInt(l_Tag) );
		l_DataFlashObject.SetMemberFlashString(  "dropDownLabel", l_GroupTitle );
		l_DataFlashObject.SetMemberFlashUInt(  "dropDownTag",  NameToFlashUInt(l_CategoryTag) );
		l_DataFlashObject.SetMemberFlashBool(  "dropDownOpened", expandedBestiaryCategories.Contains( l_CategoryTag ) );
		l_DataFlashObject.SetMemberFlashString(  "dropDownIcon", "icons/monsters/ICO_MonsterDefault.png" );

		l_DataFlashObject.SetMemberFlashBool( "isNew", l_IsNew );
		l_DataFlashObject.SetMemberFlashBool( "selected", ( l_Tag == currentTag ) );
		l_DataFlashObject.SetMemberFlashString(  "label", l_Title );
		l_DataFlashObject.SetMemberFlashString(  "iconPath", "icons/monsters/"+l_IconPath );

		l_DataFlashArray.PushBackFlashObject(l_DataFlashObject);
	}

	l_GroupTitle = "* " + GetLocStringByKeyExt("gm_kills_kill_count");	//modSigns: UI-10, the kill count entry (legacy)
	l_CategoryTag = 'KillCountCat';	//modSigns
	l_Title = GetLocStringByKeyExt("gm_kills_kill_count");	//modSigns
	l_Tag = 'KillCount';	//modSigns
	l_DataFlashObject = m_flashValueStorage.CreateTempFlashObject();	//modSigns
	l_DataFlashObject.SetMemberFlashUInt( "tag", NameToFlashUInt(l_Tag) );	//modSigns
	l_DataFlashObject.SetMemberFlashString( "dropDownLabel", l_GroupTitle );	//modSigns
	l_DataFlashObject.SetMemberFlashUInt( "dropDownTag",  NameToFlashUInt(l_CategoryTag) );	//modSigns
	l_DataFlashObject.SetMemberFlashBool( "dropDownOpened", expandedBestiaryCategories.Contains( l_CategoryTag ) );	//modSigns
	l_DataFlashObject.SetMemberFlashString( "dropDownIcon", "icons/monsters/ICO_MonsterDefault.png" );	//modSigns
	l_DataFlashObject.SetMemberFlashBool( "isNew", false );	//modSigns
	l_DataFlashObject.SetMemberFlashBool( "selected", ( l_Tag == currentTag ) );	//modSigns
	l_DataFlashObject.SetMemberFlashString( "label", l_Title );	//modSigns
	l_DataFlashObject.SetMemberFlashString( "iconPath", "icons/monsters/bestiary_leshen_locked.png" );	//modSigns
	l_DataFlashArray.PushBackFlashObject( l_DataFlashObject );	//modSigns

	if( l_DataFlashArray.GetLength() > 0 )
	{
		m_flashValueStorage.SetFlashArray( DATA_BINDING_NAME, l_DataFlashArray );
		m_fxShowSecondaryModulesSFF.InvokeSelfOneArg(FlashArgBool(true));
	}
	else
	{
		m_fxShowSecondaryModulesSFF.InvokeSelfOneArg(FlashArgBool(false));
	}
}

@wrapMethod(CR4GlossaryBestiaryMenu)
function UpdateImage( entryName : name )
{
	if(entryName == 'KillCount')
	{
		ShowRenderToTexture("");
		m_fxSetImage.InvokeSelfOneArg(FlashArgString("bestiary_leshen_locked.png"));
		return;
	}
	wrappedMethod(entryName);
}

@wrapMethod(CR4GlossaryBestiaryMenu)
function UpdateDescription( entryName : name )
{
	if(entryName == 'KillCount')
	{
		m_fxSetTitle.InvokeSelfOneArg(FlashArgString(GetLocStringByKeyExt("gm_kills_kill_count")));
		m_fxSetText.InvokeSelfOneArg(FlashArgString(GMKillCountText()));
		return;
	}
	wrappedMethod(entryName);
}

// UI-11: the bestiary's "used against" lists follow Ghost Mode's bombs (legacy's eight journals, DU7):
// Silver Dust instead of Dimeritium against the leshen, the ancient leshen, hunt mh302, the grottore and
// the spriggan; Dimeritium added against the succubus and hunt mh303; Yrden and Axii against the djinn.
// Applied to the list the journal gives, by the creature entry's tag (a script form of legacy's journal
// edits: the creatures' own lists, in their entity data, are AI's).
function GMBestiaryItemsUsedAgainst(creature : CJournalCreature) : array<name>
{
	return GMBestiaryItemsFor(NameToString(creature.GetUniqueScriptTag()), creature.GetItemsUsedAgainstCreature());
}

// The list for a creature entry's tag (as a string: the tags hold characters a name literal cannot).
function GMBestiaryItemsFor(tag : string, items : array<name>) : array<name>
{
	var i : int;

	if(tag == "Leszy" || tag == "sq204 Ancient Leszen 920DD44F-4640510C-A48A8EAB-F8003E1D" || tag == "mh302 : Leszy 8CCA7A96-4BD5C339-42B6F291-07412A2D"
		|| tag == "mq7002 Grottore E96773DE-48D2D0D5-974018A2-1E1EF657" || tag == "mq7002 : Spriggan F281E002-49FFDC37-8398DAA6-BD22C527")
	{
		for(i = 0; i < items.Size(); i += 1)
			if(items[i] == 'Dwimeritium Bomb 1')
				items[i] = 'Silver Dust Bomb 1';
	}
	else if(tag == "Succubus" || tag == "mh303 : Succubus D68E01B9-4EA4564C-2F363DA3-3A813843")
	{
		if(!items.Contains('Dwimeritium Bomb 1'))
			items.PushBack('Dwimeritium Bomb 1');
	}
	else if(tag == "Dzinn")
	{
		if(!items.Contains('Yrden'))
			items.PushBack('Yrden');
		if(!items.Contains('Axii'))
			items.PushBack('Axii');
	}
	return items;
}

// The entry's "used against" panel: none for the kill count (UI-10); the creatures' lists as Ghost Mode's
// (UI-11). 5.x body; changes marked //modSigns.
@replaceMethod(CR4GlossaryBestiaryMenu)
function UpdateItems( tag : name )
{
	var itemsFlashArray			: CScriptedFlashArray;
	var l_creature : CJournalCreature;
	var l_creatureParams : SJournalCreatureParams;
	var l_creatureEntityTemplateFilename : string;

	if(tag == 'KillCount')	//modSigns: UI-10, the kill count has no list
	{	//modSigns
		m_flashValueStorage.SetFlashBool("journal.rewards.panel.visible", false);	//modSigns
		return;	//modSigns
	}	//modSigns

	l_creature = (CJournalCreature)m_journalManager.GetEntryByTag( tag );

	itemsNames = GMBestiaryItemsUsedAgainst(l_creature);	//modSigns: UI-11, Ghost Mode's lists
	itemsFlashArray = CreateItems(itemsNames);

	if( itemsFlashArray && itemsFlashArray.GetLength() > 0 )
	{
		m_flashValueStorage.SetFlashBool("journal.rewards.panel.visible",true);
		m_flashValueStorage.SetFlashArray(DATA_BINDING_NAME_SUBLIST, itemsFlashArray );
	}
	else
	{
		m_flashValueStorage.SetFlashBool("journal.rewards.panel.visible", false);
	}
}
