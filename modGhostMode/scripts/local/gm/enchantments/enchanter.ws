// ENCH-02: the enchanter, as legacy. Legacy's 23 schematics (fee, enchanter level, runes or glyphs)
// are in Ghost Mode's DLC under <custom><gm_enchantment_schematics> (gm_ench.xml, tools/gen_ench.py):
// a schematic cannot be overridden, so the three readers below take a word's schematic from there
// before the vanilla one. The upgrade prices (3000/6000/9000) are binary edits of the enchanter's
// dialogue scenes and quest phase (tools/cr2w_patch.py); the quest objectives' text says 3000 here.
// 5.x bodies; changes marked //modSigns. See docs/features/ench.md.

// Ghost Mode's schematic of the word, or the vanilla node given.
function GMEnchantmentSchematicNode(schemName : name, vanillaNode : SCustomNode) : SCustomNode
{
	var dm : CDefinitionsManagerAccessor;
	var main : SCustomNode;
	var tmpName : name;
	var i : int;

	dm = theGame.GetDefinitionsManager();
	main = dm.GetCustomDefinition('gm_enchantment_schematics');
	for(i = 0; i < main.subNodes.Size(); i += 1)
	{
		if(dm.GetCustomNodeAttributeValueName(main.subNodes[i], 'name_name', tmpName) && tmpName == schemName)
			return main.subNodes[i];
	}
	return vanillaNode;
}

// The enchanter's word list by level.
@replaceMethod(W3CraftsmanComponent)
function LoadSchematicsXMLData() : array<SEnchantmentSchematic>
{
	var dm : CDefinitionsManagerAccessor;
	var main, ingredients : SCustomNode;
	var node : SCustomNode;	//modSigns
	var tmpName : name;
	var tmpInt : int;
	var schem : SEnchantmentSchematic;
	var i : int;
	var schematics : array<SEnchantmentSchematic>;

	dm = theGame.GetDefinitionsManager();
	main = dm.GetCustomDefinition('crafting_schematics');

	for(i=0; i<main.subNodes.Size(); i+=1)
	{
		dm.GetCustomNodeAttributeValueName(main.subNodes[i], 'name_name', tmpName);

		if(!StrContains(NameToString(tmpName), "Runeword") && !StrContains(NameToString(tmpName), "Glyphword"))
			continue;

		schem.schemName = tmpName;
		node = GMEnchantmentSchematicNode(tmpName, main.subNodes[i]);	//modSigns: Ghost Mode's schematic first

		if(dm.GetCustomNodeAttributeValueInt(node, 'level', tmpInt))	//modSigns
			schem.level = tmpInt;

		schematics.PushBack(schem);


		schem.level = -1;
		schem.schemName = '';
		tmpName = '';
	}

	return schematics;
}

// The enchanting menu's schematics.
@replaceMethod(W3EnchantmentManager)
function LoadSchematicsXMLData( schematicsNames : array<name> ) : void
{
	var dm : CDefinitionsManagerAccessor;
	var main, ingredients : SCustomNode;
	var node : SCustomNode;	//modSigns
	var tmpName : name;
	var tmpString : string;
	var tmpInt : int;
	var schem : SEnchantmentSchematic;
	var i,j,k : int;
	var ing : SItemParts;

	dm = theGame.GetDefinitionsManager();
	main = dm.GetCustomDefinition('crafting_schematics');

	for(i=0; i<main.subNodes.Size(); i+=1)
	{
		dm.GetCustomNodeAttributeValueName(main.subNodes[i], 'name_name', tmpName);

		for(j=0; j<schematicsNames.Size(); j+=1)
		{
			if(tmpName == schematicsNames[j])
			{
				node = GMEnchantmentSchematicNode(tmpName, main.subNodes[i]);	//modSigns: Ghost Mode's schematic first
				if(dm.GetCustomNodeAttributeValueName(node, 'localisation_key_name', tmpName))	//modSigns
					schem.localizedName = tmpName;
				if(dm.GetCustomNodeAttributeValueString(node, 'localisation_key_description', tmpString))	//modSigns
					schem.localizedDescriptionName = tmpString;
				if(dm.GetCustomNodeAttributeValueInt(node, 'price', tmpInt))	//modSigns
					schem.baseCraftingPrice = tmpInt;
				if(dm.GetCustomNodeAttributeValueInt(node, 'level', tmpInt))	//modSigns
					schem.level = tmpInt;


				ingredients = dm.GetCustomDefinitionSubNode(node,'ingredients');	//modSigns
				for(k=0; k<ingredients.subNodes.Size(); k+=1)
				{
					ing.itemName = '';
					ing.quantity = -1;

					if(dm.GetCustomNodeAttributeValueName(ingredients.subNodes[k], 'item_name', tmpName))
						ing.itemName = tmpName;
					if(dm.GetCustomNodeAttributeValueInt(ingredients.subNodes[k], 'quantity', tmpInt))
						ing.quantity = tmpInt;

					schem.ingredients.PushBack(ing);
				}

				schem.schemName = schematicsNames[j];

				schematics.PushBack(schem);


				schem.baseCraftingPrice = -1;
				schem.ingredients.Clear();
				schem.schemName = '';
				break;
			}
		}
	}
}

// One schematic by name (pinned recipes in the inventory and tooltips).
@replaceMethod
function getEnchantmentSchematicFromName(schematicName : name):SEnchantmentSchematic
{
	var dm : CDefinitionsManagerAccessor;
	var main, ingredients : SCustomNode;
	var node : SCustomNode;	//modSigns
	var tmpName : name;
	var tmpString : string;
	var tmpInt : int;
	var schem : SEnchantmentSchematic;
	var i,j,k : int;
	var ing : SItemParts;

	dm = theGame.GetDefinitionsManager();
	main = dm.GetCustomDefinition('crafting_schematics');

	for(i=0; i<main.subNodes.Size(); i+=1)
	{
		dm.GetCustomNodeAttributeValueName(main.subNodes[i], 'name_name', tmpName);
		if(tmpName == schematicName)
		{
			node = GMEnchantmentSchematicNode(tmpName, main.subNodes[i]);	//modSigns: Ghost Mode's schematic first
			if(dm.GetCustomNodeAttributeValueName(node, 'localisation_key_name', tmpName))	//modSigns
				schem.localizedName = tmpName;
			if(dm.GetCustomNodeAttributeValueString(node, 'localisation_key_description', tmpString))	//modSigns
				schem.localizedDescriptionName = tmpString;
			if(dm.GetCustomNodeAttributeValueInt(node, 'price', tmpInt))	//modSigns
				schem.baseCraftingPrice = tmpInt;
			if(dm.GetCustomNodeAttributeValueInt(node, 'level', tmpInt))	//modSigns
				schem.level = tmpInt;


			ingredients = dm.GetCustomDefinitionSubNode(node,'ingredients');	//modSigns
			for(k=0; k<ingredients.subNodes.Size(); k+=1)
			{
				ing.itemName = '';
				ing.quantity = -1;

				if(dm.GetCustomNodeAttributeValueName(ingredients.subNodes[k], 'item_name', tmpName))
					ing.itemName = tmpName;
				if(dm.GetCustomNodeAttributeValueInt(ingredients.subNodes[k], 'quantity', tmpInt))
					ing.quantity = tmpInt;

				schem.ingredients.PushBack(ing);
			}

			schem.schemName = schematicName;


			break;
		}
	}

	return schem;
}

// The two enchanter objectives name 3000 crowns, not 5000 (legacy). 5.x body; changes marked //modSigns.
@replaceMethod(CR4JournalQuestMenu)
function UpdateObjectives( tag : name )
{	
	var l_objectivesTotal				: int;
	var l_questObjectivesFlashArray		: CScriptedFlashArray;
	var l_questObjectiveDataFlashObject	: CScriptedFlashObject;
	
	var l_objective						: CJournalQuestObjective;
	var questEntry 						: CJournalQuest;
	var l_questPhase 					: CJournalQuestPhase;
	
	var l_objectiveStatus				: EJournalStatus;
	var l_objectiveTitle				: string;
	var l_objectiveProgress				: string;
	var l_objectiveIsNew				: bool;
	var l_objectiveIsTracked			: bool;
	var l_objectiveTag					: name;
	var i, j							: int;
	var locID							: int;
	var l_objectiveOrder				: int;
	var highlightedObjective			: CJournalQuestObjective;
	
	if (m_initialSelectionsToIgnore == 0)
	{
		m_initialSelectionsToIgnore = 1;
	}
	
	l_questObjectivesFlashArray = m_flashValueStorage.CreateTempFlashArray();
	
	questEntry = (CJournalQuest)m_journalManager.GetEntryByTag(tag);
	
	if (!questEntry)
	{
		return;
	}
	
	highlightedObjective = m_journalManager.GetHighlightedObjective();

	for( i = 0; i < questEntry.GetNumChildren(); i += 1 )
	{
		l_questPhase = (CJournalQuestPhase) questEntry.GetChild(i);
		if(l_questPhase)
		{				
			for( j = 0; j < l_questPhase.GetNumChildren(); j += 1 )
			{
				l_objective =( CJournalQuestObjective ) l_questPhase.GetChild(j);
				l_objectiveStatus 	= ( m_journalManager.GetEntryStatus( l_objective ) );
				if( l_objectiveStatus != JS_Inactive )
				{						
					l_questObjectiveDataFlashObject = m_flashValueStorage.CreateTempFlashObject();
					l_objectiveProgress = "";
					
					if( l_objective.GetCount() > 0 )
					{
						l_objectiveProgress =  " " + m_journalManager.GetQuestObjectiveCount( l_objective.guid ) + "/" + l_objective.GetCount();
					}
					l_objectiveTitle = GetLocStringById( l_objective.GetTitleStringId()  );
					l_objectiveIsNew = m_journalManager.IsEntryUnread( l_objective );
					l_objectiveIsTracked = ( highlightedObjective == l_objective );
					l_objectiveOrder = m_journalManager.GetEntryIndex( l_objective );
					
					
					l_objectiveTag = l_objective.GetUniqueScriptTag();
					if( NameToString(l_objectiveTag) == "Gather 5000 crowns for the enchanter 95C07E63-41549B12-5866D9AB-89B00199" ||	//modSigns: the enchanter's 3000 crowns (legacy)
						NameToString(l_objectiveTag) == "Deliver 5000 crowns to the enchanter 7EFEF80B-483E7F6F-BB78AEB6-8AC302D1" )	//modSigns
						l_objectiveTitle = StrReplace( l_objectiveTitle, "5000", "3000" );	//modSigns
					l_questObjectiveDataFlashObject.SetMemberFlashUInt(  "tag", NameToFlashUInt(l_objectiveTag) ); 
					l_questObjectiveDataFlashObject.SetMemberFlashBool( "isNew", l_objectiveIsNew );
					l_questObjectiveDataFlashObject.SetMemberFlashBool( "tracked", l_objectiveIsTracked );
					l_questObjectiveDataFlashObject.SetMemberFlashBool( "isLegend", false );
					l_questObjectiveDataFlashObject.SetMemberFlashInt( "status", l_objectiveStatus );
					
					l_questObjectiveDataFlashObject.SetMemberFlashString(  "label", l_objectiveTitle + l_objectiveProgress );
					l_questObjectiveDataFlashObject.SetMemberFlashInt( "phaseIndex", 1 );
					l_questObjectiveDataFlashObject.SetMemberFlashInt( "objectiveIndex", l_objectiveOrder );
					l_questObjectiveDataFlashObject.SetMemberFlashBool( "isMutuallyExclusive", l_objective.IsMutuallyExclusive() );
					
					l_questObjectivesFlashArray.PushBackFlashObject(l_questObjectiveDataFlashObject);
				}
			}
		}
	}
	
	locID = questEntry.GetTitleStringId();
	m_flashValueStorage.SetFlashArray( DATA_BINDING_NAME_SUBLIST, l_questObjectivesFlashArray );
	m_flashValueStorage.SetFlashString( DATA_BINDING_NAME_SUBLIST+".questname", GetLocStringById(locID));
	
	m_fxUpdateExpansionIcon.InvokeSelfOneArg( FlashArgInt( questEntry.GetContentType() ) );
}
