# What changed: 1.2

`classes_24232.txt` → `classes_3460.txt`

| | old | new |
|---|---|---|
| classes/structs | 48534 | 48578 |
| properties | 60922 | 64129 |
| functions | 37361 | 37569 |

New classes: **107**, removed: **63**, changed: **6**

## New classes (107)

* `3DCharacterDebug_WG_C` (class, /Game/UI/Debug/3DCharacterDebug_WG) — 0 props, 0 fns
* `AIAgentCharacter_GoblinWarrior_C` (class, /Game/AI/AIAgent/Creature/Goblin/AIAgentCharacter_GoblinWarrior) — 9 props, 0 fns
* `AIAgentCharacter_Troll_C` (class, /Game/AI/AIAgent/Creature/Troll/AIAgentCharacter_Troll) — 13 props, 0 fns
* `AdultTrollIK_AnimBP_C` (class, /Game/AnimLibrary/Creatures/AdultTroll/IK/AdultTrollIK_AnimBP) — 24 props, 5 fns
* `AdultTroll_AnimBP_C` (class, /Game/AnimLibrary/Creatures/AdultTroll/AdultTroll_AnimBP) — 315 props, 96 fns
* `BP_Brazier_02_C` (class, /Game/Assets/Environment/General/LightSources/BP_Brazier_02) — 1 props, 0 fns
* `BP_Candle_01_Wind_C` (class, /Game/Assets/Environment/General/LightSources/BP_Candle_01_Wind) — 0 props, 0 fns
* `BP_Candles_04_C` (class, /Game/Assets/Environment/General/LightSources/BP_Candles_04) — 9 props, 4 fns
* `BP_Candles_05_C` (class, /Game/Assets/Environment/General/LightSources/BP_Candles_05) — 9 props, 4 fns
* `BP_CausticsDecal_C` (class, /Game/Blueprints/CausticsDecals/BP_CausticsDecal) — 10 props, 4 fns
* `BP_EnvironmentAttack_SummonNymph_Queen_PlayerDetection_C` (class, /Game/Items/MinecrawlerQueen/BP_EnvironmentAttack_SummonNymph_Queen_PlayerDetection) — 0 props, 0 fns
* `BP_FocusStoneBridgeItem_C` (class, /Game/Environment/FocusStoneTelekinesisBridge/BP_FocusStoneBridgeItem) — 0 props, 0 fns
* `BP_FocusStoneOrb_C` (class, /Game/Assets/VFX/Particles/Magic/FocusStoneOrbBarrier/BP_FocusStoneOrb) — 32 props, 19 fns
* `BP_Fog_SwampCamp_C` (class, /Game/Assets/VFX/Particles/Ambient/SwampCamp/Volumetric/BP_Fog_SwampCamp) — 9 props, 4 fns
* `BP_ItAI_Foodbag_World_C` (class, /Game/Items/Ambient/BP_ItAI_Foodbag_World) — 0 props, 0 fns
* `BP_ItAI_Orebag_World_C` (class, /Game/Items/Ambient/BP_ItAI_Orebag_World) — 1 props, 0 fns
* `BP_ItAI_Orebag_World_Standing_C` (class, /Game/Items/Ambient/BP_ItAI_Orebag_World_Standing) — 1 props, 0 fns
* `BP_ItAt_Troll_01_World_C` (class, /Game/Items/Material/BP_ItAt_Troll_01_World) — 0 props, 0 fns
* `BP_ItFo_Cabbage_World_C` (class, /Game/Items/Food/BP_ItFo_Cabbage_World) — 0 props, 0 fns
* `BP_ItFo_Carrot_World_C` (class, /Game/Items/Food/BP_ItFo_Carrot_World) — 0 props, 0 fns
* `BP_ItFo_Crawlersoup_World_C` (class, /Game/Items/Food/BP_ItFo_Crawlersoup_World) — 0 props, 0 fns
* `BP_ItFo_Lemon_World_C` (class, /Game/Items/Food/BP_ItFo_Lemon_World) — 0 props, 0 fns
* `BP_ItFo_Muttonraw_World_C` (class, /Game/Items/Food/BP_ItFo_Muttonraw_World) — 0 props, 0 fns
* `BP_ItFo_Onion_World_C` (class, /Game/Items/Food/BP_ItFo_Onion_World) — 0 props, 0 fns
* `BP_ItFo_Plants_Ravenherb_01_Empty_World_C` (class, /Game/Items/Herb/BP_ItFo_Plants_Ravenherb_01_Empty_World) — 2 props, 0 fns
* `BP_ItFo_Plants_Ravenherb_01_World_C` (class, /Game/Items/Herb/BP_ItFo_Plants_Ravenherb_01_World) — 0 props, 0 fns
* `BP_ItFo_Plants_Stoneroot_01_Empty_World_C` (class, /Game/Items/Herb/BP_ItFo_Plants_Stoneroot_01_Empty_World) — 2 props, 0 fns
* `BP_ItFo_Plants_Stoneroot_01_World_C` (class, /Game/Items/Herb/BP_ItFo_Plants_Stoneroot_01_World) — 0 props, 0 fns
* `BP_ItFo_Plants_TrollBane_Empty_World_C` (class, /Game/Items/Herb/BP_ItFo_Plants_Trollbane_Empty_World) — 2 props, 0 fns
* `BP_ItFo_Plants_TrollBane_World_C` (class, /Game/Items/Herb/BP_ItFo_Plants_Trollbane_World) — 0 props, 0 fns
* `BP_ItFo_Sausage_World_C` (class, /Game/Items/Food/BP_ItFo_Sausage_World) — 0 props, 0 fns
* `BP_ItKe_Lockpick_World_C` (class, /Game/Items/Misc/BP_ItKe_Lockpick_World) — 0 props, 0 fns
* `BP_ItMi_Smith_Iron_World_C` (class, /Game/Items/Material/BP_ItMi_Smith_Iron_World) — 0 props, 0 fns
* `BP_ItMi_Stuff_Cup_01_World_C` (class, /Game/Items/Misc/BP_ItMi_Stuff_Cup_01_World) — 0 props, 0 fns
* `BP_ItMi_Stuff_Pan_01_World_C` (class, /Game/Items/Misc/BP_ItMi_Stuff_Pan_01_World) — 0 props, 0 fns
* `BP_ItMi_Stuff_Silverware_01_World_C` (class, /Game/Items/Misc/BP_ItMi_Stuff_Silverware_01_World) — 0 props, 0 fns
* `BP_ItMw_1H_Mace_01_Visual_C` (class, /Game/Items/Weapon/1Handed/BP_ItMw_1H_Mace_01_Visual) — 1 props, 0 fns
* `BP_ItMw_1H_Mace_01_World_C` (class, /Game/Items/Weapon/1Handed/BP_ItMw_1H_Mace_01_World) — 0 props, 0 fns
* `BP_ItMw_1H_Mace_Nailmace_01_Visual_C` (class, /Game/Items/Weapon/1Handed/BP_ItMw_1H_Mace_Nailmace_01_Visual) — 1 props, 0 fns
* `BP_ItMw_1H_Mace_Nailmace_01_World_C` (class, /Game/Items/Weapon/1Handed/BP_ItMw_1H_Mace_Nailmace_01_World) — 0 props, 0 fns
* `BP_ItMw_1H_Sword_Short_04_Visual_C` (class, /Game/Items/Weapon/1Handed/BP_ItMw_1H_Sword_Short_04_Visual) — 1 props, 0 fns
* `BP_ItMw_1H_Sword_Short_04_World_C` (class, /Game/Items/Weapon/1Handed/BP_ItMw_1H_Sword_Short_04_World) — 0 props, 0 fns
* `BP_ItMw_2H_Sword_Light_01_Visual_C` (class, /Game/Items/Weapon/2Handed/BP_ItMw_2H_Sword_Light_01_Visual) — 1 props, 0 fns
* `BP_ItMw_2H_Sword_Light_01_World_C` (class, /Game/Items/Weapon/2Handed/BP_ItMw_2H_Sword_Light_01_World) — 0 props, 0 fns
* `BP_ItRw_Bow_Small_03_Visual_C` (class, /Game/Items/Weapon/Ranged/BP_ItRw_Bow_Small_03_Visual) — 0 props, 0 fns
* `BP_ItRw_Bow_Small_03_World_C` (class, /Game/Items/Weapon/Ranged/BP_ItRw_Bow_Small_03_World) — 0 props, 0 fns
* `BP_ItRw_Crossbow_01_Visual_C` (class, /Game/Items/Weapon/Ranged/BP_ItRw_Crossbow_01_Visual) — 0 props, 0 fns
* `BP_ItRw_Crossbow_01_World_C` (class, /Game/Items/Weapon/Ranged/BP_ItRw_Crossbow_01_World) — 0 props, 0 fns
* `BP_ItWr_Scroll_1H_Sword_02_World_C` (class, /Game/Items/Writing/BP_ItWr_Scroll_1H_Sword_02_World) — 0 props, 0 fns
* `BP_ItWr_Scroll_Crawlersoup_World_C` (class, /Game/Items/Writing/BP_ItWr_Scroll_Crawlersoup_World) — 0 props, 0 fns
* `BP_OC_StairsFallenTower_01_C` (class, /Game/Assets/Environment/Stairs/Custom/OC_Custom_Stairs/BP_OC_StairsFallenTower_01) — 5 props, 0 fns
* `BP_OM_Symbols_C` (class, /Game/Blueprints/Puzzles/Symbols/BP_OM_Symbols) — 25 props, 2 fns
* `BP_OrcPit_Column_C` (class, /Game/Assets/Environment/General/LightSources/BP_OrcPit_Column) — 3 props, 1 fns
* `BP_Orc_Brazier_Metalic_C` (class, /Game/Assets/Environment/General/LightSources/BP_Orc_Brazier_Metalic) — 3 props, 1 fns
* `BP_Orc_Stairs_PitBase_01_C` (class, /Game/Assets/Environment/Stairs/Custom/Orc_Custom_Stairs/BP_Orc_Stairs_PitBase_01) — 4 props, 0 fns
* `BP_RectLight_Independent_C` (class, /Game/Blueprints/LightActors/BP_RectLight_Independent) — 9 props, 5 fns
* `BP_SH_QueenPh2NymphSpawner_C` (class, /Game/Items/MinecrawlerQueen/BP_SH_QueenPh2NymphSpawner) — 0 props, 0 fns
* `BP_SK_Sawmill_C` (class, /Game/Blueprints/Environment/BP_SK_Sawmill) — 41 props, 0 fns
* `BP_TelekinesisFocusStoneBridge_C` (class, /Game/Environment/FocusStoneTelekinesisBridge/BP_TelekinesisFocusStoneBridge) — 42 props, 17 fns
* `BP_TrollCanyon_Stairs_Entrance_01_C` (class, /Game/Assets/Environment/Stairs/Custom/TC_Custom_Stairs/BP_TrollCanyon_Stairs_Entrance_01) — 3 props, 0 fns
* `Bow_AnimBP_C` (class, /Game/AnimLibrary/Items/Weapons/Ranged/Bow_AnimBP) — 8 props, 2 fns
* `Bow_CtrlRig_C` (class, /Game/AnimLibrary/Items/Weapons/Ranged/Bow_CtrlRig) — 5 props, 0 fns
* `CR_AdultTroll_IK_C` (class, /Game/AnimLibrary/Creatures/AdultTroll/CR_AdultTroll_IK) — 33 props, 0 fns
* `CR_GreenGoblin_IK_C` (class, /Game/AnimLibrary/Creatures/Green_Goblin/CR_GreenGoblin_IK) — 33 props, 0 fns
* `Crosbow_CtrlRig_C` (class, /Game/AnimLibrary/Items/Weapons/Ranged/Crosbow_CtrlRig) — 7 props, 0 fns
* `Crossbow_AnimBP_C` (class, /Game/AnimLibrary/Items/Weapons/Ranged/Crossbow_AnimBP) — 9 props, 2 fns
* `Crow_AnimBP_Ambient_C` (class, /Game/AI/AmbientLife/Crow/Crow_AnimBP_Ambient) — 34 props, 11 fns
* `Crow_bp_C` (class, /Game/AI/AmbientLife/Crow/Crow_bp) — 0 props, 0 fns
* `GreenGoblinIK_AnimBP_C` (class, /Game/AnimLibrary/Creatures/Green_Goblin/IK/GreenGoblinIK_AnimBP) — 24 props, 5 fns
* `GreenGoblin_AnimBP_C` (class, /Game/AnimLibrary/Creatures/Green_Goblin/GreenGoblin_AnimBP) — 302 props, 79 fns
* `GrindingMachine_AnimBP_C` (class, /Game/AnimLibrary/Items/Interactuables/Machines/GrindingMachine_AnimBP) — 15 props, 6 fns
* `GrindingMill_AnimBP_C` (class, /Game/AnimLibrary/Items/Interactuables/Machines/GrindingMill_AnimBP) — 6 props, 2 fns
* `GrindingMill_Bucket_AnimBP_C` (class, /Game/AnimLibrary/Items/Interactuables/Machines/GrindingMill_Bucket_AnimBP) — 6 props, 2 fns
* `GrindingOven_AnimBP_C` (class, /Game/AnimLibrary/Items/Interactuables/Machines/GrindingOven_AnimBP) — 15 props, 7 fns
* `GrindingOven_Belows_AnimBP_C` (class, /Game/AnimLibrary/Items/Interactuables/Machines/GrindingOven_Belows_AnimBP) — 6 props, 2 fns
* `IBP_GrindingMachine_C` (class, /Game/InteractiveObjects/GrindingMachine/IBP_GrindingMachine) — 13 props, 0 fns
* `IBP_GrindingMill_Bucket_C` (class, /Game/InteractiveObjects/GrindingMill/IBP_GrindingMill_Bucket) — 2 props, 0 fns
* `IBP_GrindingMill_C` (class, /Game/InteractiveObjects/GrindingMill/IBP_GrindingMill) — 34 props, 0 fns
* `IBP_GrindingOven_Belows_C` (class, /Game/InteractiveObjects/GrindingOven/IBP_GrindingOven_Belows) — 15 props, 0 fns
* `IBP_GrindingOven_C` (class, /Game/InteractiveObjects/GrindingOven/IBP_GrindingOven) — 4 props, 3 fns
* `Interactive_Bed_C` (class, /Game/InteractiveObjects/Beds/Interactive_Bed) — 2 props, 0 fns
* `Interactive_Bed_Guard_C` (class, /Game/InteractiveObjects/Beds/Interactive_Bed_Guard) — 3 props, 0 fns
* `Interactive_Bed_Guard_Right_LeftVariant_C` (class, /Game/InteractiveObjects/Variants/Beds/Interactive_Bed_Guard_Right_LeftVariant) — 0 props, 0 fns
* `Interactive_Chair_ArtisanWoodBench_C` (class, /Game/InteractiveObjects/Chairs/Interactive_Chair_ArtisanWoodBench) — 4 props, 0 fns
* `Interactive_Chair_Stool2_C` (class, /Game/InteractiveObjects/Chairs/Interactive_Chair_Stool2) — 6 props, 0 fns
* `Interactive_Chair_Stool_C` (class, /Game/InteractiveObjects/Chairs/Interactive_Chair_Stool) — 6 props, 0 fns
* `Interactive_Chair_WoodenBox_C` (class, /Game/InteractiveObjects/Chairs/Interactive_Chair_WoodenBox) — 3 props, 0 fns
* `Interactive_Lactern_C` (class, /Game/InteractiveObjects/Interactive_Lactern) — 3 props, 0 fns
* `Interactive_Lever_OrcLever_C` (class, /Game/InteractiveObjects/Interactive_Lever_OrcLever) — 6 props, 0 fns
* `Interactive_LootBodyDigger_C` (class, /Game/InteractiveObjects/Variants/Corpses/Interactive_LootBodyDigger) — 1 props, 0 fns
* `Interactive_MiningSpotVariable_C` (class, /Game/InteractiveObjects/Interactive_MiningSpotVariable) — 11 props, 0 fns
* `Interactive_MiningSpotVariable_Left_Variant_C` (class, /Game/InteractiveObjects/Variants/MiningSpot/Interactive_MiningSpotVariable_Left_Variant) — 0 props, 0 fns
* `Interactive_MiningSpotVariable_Right_Variant_C` (class, /Game/InteractiveObjects/Variants/MiningSpot/Interactive_MiningSpotVariable_Right_Variant) — 0 props, 0 fns
* `Interactive_Rostisserie_C` (class, /Game/InteractiveObjects/Food/Interactive_Rostisserie) — 12 props, 0 fns
* `Interactive_WhetStone_C` (class, /Game/InteractiveObjects/Interactive_WhetStone) — 18 props, 0 fns
* `Interactive_WorkBench_C` (class, /Game/InteractiveObjects/Interactive_WorkBench) — 18 props, 4 fns
* `Lactern_AnimBP_C` (class, /Game/AnimLibrary/Items/Interactuables/Lactern_AnimBP) — 6 props, 2 fns
* `Normal_Attack` (class, /Engine/EngineSounds/Normal_Attack) — 0 props, 0 fns
* `OldMineExplosionCinematic_BP_C` (class, /Game/InteractiveObjects/StatuesPresets/OldMineExplosionCinematic_BP) — 0 props, 0 fns
* `RigVMMemory_Debug` (class, /Game/AnimLibrary/Items/Weapons/Ranged/Crosbow_CtrlRig) — 29 props, 0 fns
* `RigVMMemory_Literal` (class, /Game/AnimLibrary/Items/Weapons/Ranged/Crosbow_CtrlRig) — 15 props, 0 fns
* `RigVMMemory_Work` (class, /Game/AnimLibrary/Items/Weapons/Ranged/Crosbow_CtrlRig) — 17 props, 0 fns
* `Special_Attack_PSM` (class, /Engine/EngineSounds/Special_Attack_PSM) — 0 props, 0 fns
* `TrollCanyon_Door_C` (class, /Game/InteractiveObjects/Doors/TrollCanyon_Door) — 7 props, 0 fns
* `Troll_Canyon_MainDoor_Animbp_C` (class, /Game/AnimLibrary/Humanoid/Man/Actions/Levers/MainDoorMachine/Maindoor_TrollCanyon/Troll_Canyon_MainDoor_Animbp) — 18 props, 8 fns
* `dino_l_short_C` (class, /Game/AnimLibrary/FootSteps/Creatures/DinoBipeds/dino_l_short) — 0 props, 0 fns
* `dino_r_short_C` (class, /Game/AnimLibrary/FootSteps/Creatures/DinoBipeds/dino_r_short) — 0 props, 0 fns

## Removed classes (63)

* `AmbientBoxSpawner_Standing_C`
* `BP_BarrierWater_Spline_C`
* `BP_CharacterWetnessTrigger_C`
* `BP_DynamicLightBase_C`
* `BP_FallingLeaves_C`
* `BP_FirePit_C`
* `BP_FishBank_C`
* `BP_In_Area_Crab_C`
* `BP_In_Area_GrassHopper_C`
* `BP_In_DragonFlyRainfield_C`
* `BP_In_Flying_Bee_C`
* `BP_In_Idle_Beetle_C`
* `BP_In_Idle_Butterfly_B_C`
* `BP_In_Idle_Butterfly_C`
* `BP_In_Idle_Ladybug_C`
* `BP_Insect_DragonFly_C`
* `BP_ItAI_BoxMidHigh_World_C`
* `BP_ItAI_Box_World_C`
* `BP_ItAI_Plank_World_C`
* `BP_ItAI_Plank_World_Leaning_C`
* `BP_ItAm_Arrow_World_C`
* `BP_ItAt_Harpy_01_World_C`
* `BP_ItFo_Apple_World_C`
* `BP_ItFo_Meatbugragout_World_C`
* `BP_ItFo_Pear_World_C`
* `BP_ItFo_Plants_Berrys_01_Empty_World_C`
* `BP_ItFo_Plants_Berrys_01_World_C`
* `BP_ItFo_Plants_Dewleaf_Empty_World_C`
* `BP_ItFo_Plants_Dewleaf_World_C`
* `BP_ItFo_Plants_Lobelia_Empty_World_C`
* `BP_ItFo_Plants_Lobelia_World_C`
* `BP_ItFo_Potion_Strongbeer_World_C`
* `BP_ItFo_Potion_Wine_World_C`
* `BP_ItMi_Coop_World_C`
* `BP_ItMi_Joint_01_World_C`
* `BP_ItMi_JudgeHat_World_C`
* `BP_ItMi_Lute_World_C`
* `BP_ItMi_Stuff_Brush_World_C`
* `BP_ItMi_Stuff_Mug_01_World_C`
* `BP_ItMs_Scroll_WomensRevenge_World_C`
* `BP_ItRw_Bow_Small_01_World_C`
* `BP_Mine_Lamp_02_C`
* `BP_NavLink_WallClimb_C`
* `BP_RectLight_C`
* `BP_SplineTool_Deformation_C`
* `BP_WaterfallPatch_C`
* `CinematicCharacter_AnimBP_C`
* `CinematicCharacter_C`
* `FenceDoor_Abandoned_AnimBp_C`
* `FenceDoor_Abandoned_C`
* `Interactive_Bed_DiggerRight_C`
* `Interactive_Chair_01_C`
* `Interactive_Chair_Bench_02_C`
* `Interactive_Chair_Bench_3_C`
* `Interactive_Chair_RoundStool_C`
* `Interactive_MachineOrc_C`
* `Interactive_UnderWater_Chest_Right_Variant_C`
* `Interactive_Winch_OrcMachine_C`
* `MainDoor_Abandoned_Mine_Door_Puzzle_C`
* `MainDoor_Abandoned_Mine_Door_Puzzle_animbp_C`
* `Pidgeon_AnimBP_Ambient_C`
* `Pidgeon_bp_C`
* `WallAccesArea_C`

## Classes whose members changed (6)

| class | props old→new | fns old→new | new properties |
|---|---|---|---|
| `AIWorldEvent_Explicit_BartholoPlayLute` | 0 → 0 | 2 → 0 |  |
| `AbilityTask_Interaction_Human_GomezSitThrone` | 0 → 0 | 1 → 2 |  |
| `AnimBlueprintGeneratedConstantData` | 85 → 7 | 0 → 0 | `AnimGraphNode_ControlRig`, `__NameProperty_4`, `__NameProperty_5`, `__StructProperty_6` |
| `AnimBlueprintGeneratedMutableData` | 10 → 0 | 0 → 0 |  |
| `BPC_ActivablePostProcessComponent_C` | 5 → 7 | 10 → 11 | `PrePhotoModeState`, `WasPhotoModeLastActive` |
| `MainMenuWidget` | 7 → 7 | 10 → 10 |  |
