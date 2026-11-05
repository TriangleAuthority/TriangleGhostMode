# HORSE: horse combat

What Geralt can do from Roach's back and what it costs: the sword hit from horseback (its damage and what it does to the enemy's stamina), calming a panicking horse with Axii, and the horse running enemies down (trampling). Ghost Mode's changelist has its own section, "Horse combat" (lines 482–490); legacy's horse Axii cost is in the code only.

**The player-visible texts first.** Legacy's changelist, quoted exactly: "Attacking from horse no longer drains 100% stamina."; "Attacks from horseback drain lightAttackCost*3 stamina."; "All the attacks from horseback are considered heavy (same as vanilla)."; "Bonus damage when attacking from horseback now depends on weapon damage."; "Higher speed means higher bonus damage: up to x2 when attacking at full speed."; "Attacking at maximum speed adds knockdown to the attack." The only description involved is Adrenaline Burst's (horse Axii's adrenaline payment, HORSE-02), the same in legacy and the port: "Increases Adrenaline gain by $I$%. In addition to usual Battle Trance effect, each Adrenaline Point also decreases melee action Stamina cost by $I$%." (`gm_skill_desc_adrenaline_burst`, 2110992319; classic `perk_10`, new tree `perk_42`); it says nothing about the horse. 5.x's own texts: classic `perk_10` "Increases Adrenaline generation by 5%. Using Signs now generates Adrenaline Points.", new tree `perk_42` "Increases Adrenaline generation by 6% and allows Signs to generate Adrenaline. Vitality gain: +3%" (already replaced by legacy's text, SKL-18). No horse tutorial or tooltip states a number legacy changed.

**What 5.x did in this area** (from `vanilla-5.x`, unverified in game). The horse combat code is 1.32's: `useVehicle.ws`'s sword attack (`DealDamageToHostiles`: the victim's `DrainStamina(ESAT_FixedValue, 100, 1)` and a direct-damage bonus of 50, or 50 × (1.1 + speed) from a trot up) and its Axii state are unchanged, but for a voice line Geralt says when he calms the horse (`PlayBattleCry('ChillOutHorse')`). What moved, outside legacy's code: **trampling** (`W3HorseComponent.DealDamageToCollidedActor`, `ShouldDealDamageToActor`; HORSE-03), a horse **kick and rearing** on a key (`HorseKick`, an animation event, no damage code), the horse's own gallop stamina (it now drains from the gallop for a horse and only at a full gallop for a cart, and regenerates after 0.45 s instead of 1 s outside races; `exploration.ws`), the dead `ESAT_Sprint` drain removed (see [the sprint cost](#already-ported-by-other-areas)), carts, loot from horseback, and mount, dismount, camera and lean animations (`horseRiding.ws`, `dismountHorse.ws`, `mountHorse.ws`).

**How legacy Ghost Mode implements it.** Scripts only, all in `useVehicle.ws`: `W3VehicleCombatManagerStateSwordAttack.DealDamageToHostiles` (HORSE-01), and in the `CastSign` state the fields, `OnEnterState`, `StartCastingSign` and two new functions, `HasResourcesForAxii` and `DrainResourcesForAxii` (HORSE-02). Legacy's other horse changes belong to areas already ported (below). No XML, CSV or binary unit is HORSE's.

Unit lists: [attribution.csv](attribution.csv): mapped 2026-11-02 from the changelist's section, sweeps B and D (the provisional HORSE-NEW1 and HORSE-NEW2, gap G14), the hand-offs in stam.md, dmg.md, swd.md, skl.md (D42) and wgt.md (PW9), a script diff of every file legacy changed under `vehicles`, `horse` and the player's vehicle states (`vanilla-1.32` against `legacy-GM` and `vanilla-5.x`: only `useVehicle.ws`, `horseComponent.ws`, `exploration.ws` and `boat.ws`), the XML diff of `def_item_horse.xml` and the free DLCs' horse gear, and sweeps (`unit_sweep.py` for horse, vehicle, mount, panic, `speed_based`, `IsUsingHorse`, `HorseRiding`, `GetUsedVehicle`, `IsUsingVehicle`, dismount; scripts and XML). **6 units carry a HORSE feature**, all GM scripts with no NG+ counterpart: HORSE-01 1, HORSE-02 5 (the provisional IDs replaced). Unattributed units: 0 before and after (sweeps A to D attributed everything). Port status: **ported**: slices H1 to H3 verified on the area builds (2026-11-03), both trees by the regression (HORSE-02's checks in each tree by hand); the owner decided DH1 to DH3 as recommended and confirmed the porter's calls PH1 to PH9 (2026-11-02). **Audited** 2026-11-03 ([HORSE audit](#horse-audit-2026-11-03): 7 findings, none an owner decision; F4 to F6 fixed in H4, [close-out](#horse-audit-close-out)); **signed off** by the owner (2026-11-03). Open checks need real riding (the owner's playthrough).

**Size.** One small area, three slices and one audit: two replaced script functions and a state's Axii loop, plus one function of 5.x's trampling if DH2 restores legacy's.

## Scope

**HORSE covers** the sword hit from horseback (its damage and its effect on the enemy's stamina), horse Axii's cost in both skill trees, and trampling (the horse's collision damage, which 5.x reworked).

**Unchanged by legacy, and by 5.x** (from the code): every horseback attack is a heavy attack (`attack_heavy`, `EHRT_Heavy`); the knockdown at full gallop (speed 4); the attack's reach by speed (`GatherEntitiesInAttackRanges`); the horse combat slow motion; a hit from horseback at full gallop +100% crit chance for sword swings (`CR4Player.GetCriticalHitChance`); horse Axii keeps the horse calm for 5 s after it ends when the panic is below 5%; horse Axii has no sign cooldown and is not refused by one in legacy or the port (the cooldown is checked on the foot cast input and added by the signs' cast states, which the horse cast never enters).

### Already ported by other areas

| Subject | Ported by | What |
|---|---|---|
| A horseback sword attack costs 3 light attacks of stamina, refused without it; bombs and the crossbow refused without stamina (changelist 486) | STAM-03 (signed off) | `stamina/horseStamina.ws` (`GMHorsebackStaminaMult`); paid in `SwordAttack.DoAttack` (a deviation: legacy missed the quick swing) |
| Mutagen 25 (Nekker Warrior decoction): no horseback attack power, no horse panic immunity (DMG's hand-off "the horse-speed attack power bonus": 5.x's horse block in `GetPowerStatValue` holds only Mutagen 25's) | ALCH-12 (signed off) | `alchemy/decoctionsSustain.ws` |
| Bolts get no galloping crit chance | XBOW-06 (signed off) | `skills/oils.ws` |
| Saddlebag capacity, horse gear weights, the Toussaint and Ofir blinders' panic resistance (60 → 75, 55 → 70), the base horse's sprint cost (`HorseLevel1` `sprint_stamina_cost` 5 → 7.5) | WGT-06 (PW9, signed off) | `gen_wgt.py`. **The sprint cost is read by no code**, in legacy as in 5.x: the horse's `ESAT_Sprint` drain runs only without "simple stamina management", which is on by default (only a debug command turns it off) in 1.32 and legacy, and 5.x removed the drain; the horse's gallop costs a fixed 3.33 stamina a second. Nothing to change: legacy's value was inert too (PH8) |
| No canter or gallop while Geralt cannot sprint (overburdened) | WGT-09 (signed off) | `weight/overEncumbered.ws` |
| Horse gear and saddle prices, `mod_horse` | ECON-01, ECON-05 (signed off) | item data, price table |
| The horse's weapon, used by trampling (`mon_horse_weapon _Stats`: bludgeoning 250 → 20 + 20, rending 20) | AI-05 (signed off) | `items/gm_ai_weapons.xml` |
| Trampling gives Geralt no extra adrenaline (`attack_speed_based`'s `focus_gain` 0.025 removed; gap G12); the base 0.1 of every melee hit on a hostile that deals damage stays, as in legacy's code (**verified**, HORSE audit F3: 0.1 per trample hit) | SKL-07 (done, sweeps' decision) | one more extend in `gm_adrenaline.xml` |
| Horse trophies; contracts no longer teleport Roach (`ProcessMonsterHuntTrophyQuest`) | TRPH (signed off) | |
| Overburdened boats | WGT-10, OPT-04 (signed off) | |
| The Kaer Morhen set in the horse's inventory in NG+, the horse stash, horse items' tooltips, the Mutation Trigger refused on horseback, burning blocking the horse call | ARM-12, UI-17, ALCH-17, MUT-12, EFX (signed off) | |

**Not HORSE:**

| Subject | Area | Why |
|---|---|---|
| Rewards for horse races and horse quests (experience, gold, items) | XP-02, ECON-10, LOOT-07 | Rewards |
| The character reset leaving the horse's gear on (legacy unequips it) | SKL-01 | A recorded deviation of the reset |
| `CanPerformFinisher` (legacy's rewrite keeps "no finisher on horseback") | SKL-12 | No horse change |

## Changes at a glance

### What Ghost Mode changed

| # | Feature | Vanilla 1.32 (and 5.x) | Legacy GM | Units (main) |
|---|---|---|---|---|
| HORSE-01 | Horseback hits | Each enemy hit loses 100 stamina; the hit adds 50 direct damage (ignores armor and resistances), 50 × (1.1 + speed) from a trot up (255 at full gallop) | No stamina drain; each of the weapon's damage types gets weapon damage × speed/4 more (×1.25 walking to ×2 at full gallop; none standing) | `DealDamageToHostiles` |
| HORSE-02 | Horse Axii costs stamina | Free (only Axii's own cost must be there to start); the horse is confused 0.1 s per frame while the key is held | Starts only with 50 stamina; 0.5 stamina every 0.1 s while held (nominally 5 a second; each tick waits for the next frame, so about 4: 3.8 measured), ending at 0; with Adrenaline Burst adrenaline covers what stamina cannot (to start and while held); 0.5 s confusion per 0.1 s tick | 5 units of the `CastSign` state |
| HORSE-03 | Trampling | 1.32: head-on only (side if the enemy is down), at canter or full gallop, hostiles only: 50 × speed physical (the horse weapon adds nothing when Geralt rides) | 1.32's rule (legacy changed only the horse weapon, AI-05, and the adrenaline, SKL-07) | — (no legacy unit) |

### What 5.x changed

| # | 5.x change (from code) |
|---|---|
| HORSE-01 | None |
| HORSE-02 | A voice line on the cast (`ChillOutHorse`) |
| HORSE-03 | Trampling reworked: head-on and from the side, at any speed the horse moves (or canter and up in slow motion or with an NPC rider), hostiles and animals, living ones only: the horse weapon + force damage 15 × speed head-on, 5 × speed from the side, capped at 1/15 of the victim's maximum health |

### Classification and proposed action

| # | Feature | Class | Proposed action |
|---|---|---|---|
| HORSE-01 | Horseback hits | clean | Legacy's (PH1); its multi-enemy defect: DH1 |
| HORSE-02 | Horse Axii | clean | Legacy's, both trees (PH2, PH3); the description: DH3 |
| HORSE-03 | Trampling | overlap | DH2 |

---

### HORSE-01 Horseback hits

| | |
|---|---|
| Kind | system |
| Pillars | P1, P2 |
| 5.x class | clean |
| Flags | balance |
| Depends on | STAM-08 (NPC stamina: what the 100-point drain would take away), DMG (the weapon damage goes through the formula), STAM-03 (the cost, already ported) |
| Skill trees | n/a (tested in both trees by the regression) |
| Port form | `horse/horseCombat.ws`: `@replaceMethod(W3VehicleCombatManagerStateSwordAttack) DealDamageToHostiles`, 5.x's body (1.32's) with legacy's block, and a fresh `W3Action_Attack` per enemy (DH1 (a)) |
| Port status | **verified on the area build** (slice H1, 2026-11-03): scripted hits through the state's own hit function at speeds 0 to 4 and on two enemies (on foot and on Roach), a real standing swing by scripted input; each check failed first on a build without the port and DH1's on legacy's code. The regression: +11 checks in `gmtest_regress()` in each tree (`GMTest_horse`; the panel's fallback when no sword is in hand) |
| Open checks | a real swing at a canter or full gallop (real input: scripted input cannot set the horse's speed), owner's playthrough |
| Save impact | none (expected) |
| NG+ counterpart | none (script) |

**What it does** (changelist 485, 488–490): a sword hit from horseback no longer empties the enemy's stamina, and its bonus damage is the weapon's own: each damage type of the weapon gets a share more by the horse's speed, speed/4 (walk 1, trot 2, canter 3, full gallop 4): +25% walking, +50% trotting, +75% at a canter, double at a full gallop; standing still, no bonus. The bonus then goes through the damage formula like the rest of the hit (armor first, then attack power, resistances), where vanilla's bonus was direct damage that ignores armor and resistances. Example, a sword of 300 slashing damage at a full gallop: legacy 600 slashing, the enemy's stamina untouched; 1.32 and 5.x 300 slashing plus 255 direct damage, and the enemy loses 100 stamina, which in the port (STAM-08) stops it attacking (no attack tickets below 10% until it has 33.4% again) and from guarding or parrying for a while. At full gallop the hit still knocks the enemy down.

**Implementation (legacy):** `DealDamageToHostiles`: the `DrainStamina(ESAT_FixedValue, 100, 1)` and the direct-damage bonus commented out; after `damage.Init`, if speed > 0, for each of the action's damage types above 0 `AddDamage(type, value × ClampF(speed / 4, 0, 1))`; the knockdown applicator at speed ≥ 4, the sound, the effects and the blood trail as vanilla. The `baseDamage` parameter (50) is no longer read.

**5.x:** 1.32's function, unchanged; the call sites (`DoAttack`, its two sweeps and the slow-motion path) too. Nothing in the port: today a horseback hit drains 100 of the enemy's stamina and adds 50 to 255 direct damage.

**Decisions:** legacy's (PH1).

- **Deviation:** each enemy reached by one horseback swing gets an attack of its own, so each takes the weapon's damage × up to 2, as the changelist says; legacy's code reused one attack whose damage piled up from enemy to enemy (at a full gallop with a 300-damage sword: 600, then 1,800, then 4,200), a defect vanilla had and legacy's speed bonus multiplied (DH1 (a), owner, 2026-11-02).
- **Deviation:** 5.x's horse handling that legacy never touched is kept: the horse's gallop stamina regenerates after 0.45 s (1 s in 1.32), and 5.x's carts, loot from horseback, and mount, dismount, camera and lean animations stay as 5.x has them (PH7, owner, 2026-11-02).

**A defect (vanilla's, made worse by legacy; DH1):** the function creates one attack action and re-initialises it for each enemy in the swing, but `W3Action_Attack.Clear` does not clear the damage list (it overrides `W3DamageAction.Clear`, which does, without calling it). Each enemy's `Init` adds the weapon's damage on top of the previous enemy's, so in 1.32 and 5.x the second enemy of a swing takes the weapon damage and the direct bonus twice. Legacy's loop then multiplies the accumulated list: at a full gallop with 300 slashing, the first enemy takes 600, the second (600 + 300) × 2 = 1,800, a third 4,200 (5.x: 300 + 255, then 600 + 510). **Verified** (slice H1, 2026-11-03; a sword of 24.5 damage, two frozen dummies, one call at full gallop; the damage each hit carried before the formula): legacy's code 47 then 138, 5.x 299 then 586 (direct bonus included), the port 47 then 44.

**Slices:** see [H1](#port-order).

**Later:** —

### HORSE-02 Horse Axii costs stamina

| | |
|---|---|
| Kind | system |
| Pillars | P2, P3 |
| 5.x class | clean |
| Flags | — |
| Depends on | SKL-18 (Adrenaline Burst in both trees), STAM-03 (Axii's own cost, the `DrainStamina` replacement and its delay option) |
| Skill trees | both: Adrenaline Burst, classic `perk_10`, new tree `perk_42` (the selection `GMAdrenalineBurstCostCut` already makes) |
| Port form | `horse/horseAxii.ws`: `@replaceMethod(W3VehicleCombatManagerStateCastSign)` `OnEnterState` (the 50 check) and the entry function `StartCastingSign` (legacy's 0.1 s loop; the replaced entry function runs, PH2's probe), `@addMethod` `GMHasResourcesForAxii` and `GMDrainResourcesForAxii` on the state, the cost a function (`GMHorseAxiiCost`, no state fields), the key read through `GMHorseAxiiHeld()` (so tests can hold it) |
| Port status | **verified on the area build** (slice H2, 2026-11-03), both trees: scripted presses of the horse cast with the key held by a test wrapper; each new check failed first on a build without the replaced state functions; the regression: +1 check in `gmtest_regress()` (the resource rule, the tree's Adrenaline Burst) |
| Open checks | a real held Axii on a horse panicked by enemies (real input) |
| Save impact | none (expected) |
| NG+ counterpart | none (script) |

**What it does** (code only; the changelist does not mention it): calming Roach with Axii (the sign key while mounted) needs at least 50 stamina to start, and holding it costs 0.5 stamina a tick, every 0.1 s plus a frame (measured 0.126 to 0.136 s: about 3.8 stamina a second, legacy's code alike), with stamina regeneration paused (each drain sets a 0.5 s delay); it ends when the key is released or stamina runs out. The 50 is a threshold, not a cost: a start at 60 stamina spends nothing until the hold. With Adrenaline Burst adrenaline counts as stamina at max stamina ÷ max adrenaline per point (33.3 stamina per point at 100 stamina and 3 points): to start, stamina plus adrenaline must make 50; while held, adrenaline pays what stamina cannot (0.015 of a point per tick at those maxima). Example, without the perk: at 60 stamina Geralt can hold Axii for about 16 s; at 45 he cannot cast it. With the perk, 45 stamina and 1 adrenaline point (45 + 33.3) start it, the 45 stamina last about 12 s and the adrenaline about 9 s more. Vanilla's check that Axii's own cost (40 in legacy) is there still runs when the sign is cast (`InitCastSign`); the horse cast does not pay it (**verified**: the hold's first tick finds the stamina the cast started with), so with Adrenaline Burst alone the adrenaline only helps a start at 40 to 49 stamina, or with Rage Management (its sign casts with adrenaline). Each tick confuses the horse for 0.5 s (vanilla 0.1 s each frame), so the calm lingers up to half a second after the release.

**Implementation (legacy):** the `CastSign` state: `ON_HORSEBACK_AXII_COST` 50 and `staminaSpent` (fields); `OnEnterState` calls `StartCastingSign` only if `HasResourcesForAxii(50)`; `HasResourcesForAxii(cost)`: stamina ≥ cost, or with `S_Perk_10` stamina + adrenaline × max stamina ÷ max adrenaline ≥ cost; `DrainResourcesForAxii(cost)`: `DrainStamina(ESAT_FixedValue, cost, 0.5)` if any stamina is left, and with the perk the part above the stamina from adrenaline (`DrainFocus`); `StartCastingSign`'s loop sleeps 0.1 s instead of a frame, holds while the key is pressed and `HasResourcesForAxii(0.5)`, then `ApplyEffectOnHorse(0.5)` and `DrainResourcesForAxii(0.5)`. Leftovers with no effect: `staminaSpent` is counted but read only by a commented-out payment up to 50 at the end (`OnLeaveState`), so legacy once charged 50 per cast and no longer does.

**5.x:** 1.32's state with a voice line on the cast. The perk check names only `S_Perk_10`, which exists in 5.x's classic tree; the new tree's Adrenaline Burst is `perk_42` (`S_Perk_42`). Nothing in the port: horse Axii is free.

**Decisions:** legacy's, in both trees (PH2, PH3); Adrenaline Burst pays horse Axii, its description unchanged (DH3 (a), project owner, 2026-11-02).

- **Deviation:** Geralt's voice line when he calms the horse (5.x's `ChillOutHorse`) is kept; legacy had none (PH5, owner, 2026-11-02).

**Verified** (slice H2, 2026-11-03, classic `perk_10` and new tree `perk_42`): refused at 49 stamina (no sign cast) and without the perk at 45 stamina and 1 adrenaline; started at 50, 100, and with the perk at 45 and 1 adrenaline; held, 0.5 stamina a tick with no regen in between and Roach confused; the hold ends when stamina runs out (adrenaline 0 without the perk); with the perk adrenaline pays 0.015 a tick once the stamina is spent, and the hold ends when that runs out too; at 30 stamina and 1 adrenaline with the perk the threshold is met but Axii's own cost refuses the cast. Roach's panic from four hostile humans 4 m away fell from 0.19 to 0.07 in about 2 s of the hold and to 0 after. SKL handed it over as D42 ("a legacy leftover").

**Slices:** see [H2](#port-order).

**Later:** Adrenaline Burst's description could say it pays horse Axii (DH3 (b)).

### HORSE-03 Trampling

| | |
|---|---|
| Kind | tuning |
| Pillars | P1, P8 |
| 5.x class | overlap |
| Flags | balance, needs-decision |
| Depends on | AI-05 (the horse weapon), SKL-07 (no trampling adrenaline, G12) |
| Skill trees | n/a |
| Port form | `horse/trampling.ws`: `@replaceMethod(W3HorseComponent)` `ShouldDealDamageToActor` and `DealDamageToCollidedActor` with 1.32's rule (5.x's kick sound kept); the speed both read goes through `@addMethod` `GMTrampleSpeed()` (5.x's `InternalGetSpeed()`), so the tests can set it |
| Port status | **verified on the area build** (slice H3, 2026-11-03): the collision rule called as a collision calls it, with the speed it reads set by a test wrapper, ridden and with Roach riderless (Geralt standing in as her rider, the regression's form); each check failed first on a build without the replaced functions; the regression: +6 checks in `gmtest_panel()` |
| Open checks | a real ride into enemies at a canter and a gallop, and past one from the side (real input: scripted input cannot set the horse's speed), owner's playthrough |
| Save impact | none (expected) |
| NG+ counterpart | none (script; the weapon's NG+ copy is AI-05's) |

**What it does:** the damage Roach deals when she runs into an enemy. Legacy kept 1.32's rule and changed what goes into it: the horse weapon's bludgeoning 250 → 40 (AI-05, ported) and no adrenaline for Geralt (SKL-07). 5.x reworked the rule itself. Example, Roach ridden by Geralt at full gallop (speed 4) head-on into a bandit with 1,500 Vitality: legacy (1.32's rule, the port) deals 200 physical; 5.x dealt 60 force damage (capped at 100, a fifteenth of his Vitality) and also hit from the side (20), at lower speeds too (whenever 5.x's `distanceBasedSpeed` is 0.1 or more), and ran over animals as well. Everything goes through the damage formula. **The horse weapon adds nothing to a ridden horse's hit** (verified 2026-11-03, slice H3; 1.32, legacy and 5.x alike): the attack names the rider as the attacker, and `W3Action_Attack.FillDataFromWeapon` looks the horse weapon's item id up in the attacker's inventory, where that id names some other item of the rider's (item ids are per inventory: on the test save Roach's weapon id is Geralt's "Body feet 01", no damage; HORSE audit F1); so AI-05's horse weapon values do not reach trampling by a ridden horse, Geralt's or an enemy rider's. They reach only a **riderless** horse's trampling (the horse is then the attacker: measured 40 + 20 from the weapon on top of the 50 × speed), e.g. an enemy's horse that lost its rider, which keeps the rider's attitude group (`OnMountFinished` stores the horse's own group and nothing restores it; code only). **The same rule governs enemy riders trampling Geralt** (HORSE audit F2): head-on at a canter or full gallop, 50 × speed physical with the rider's attack power and the difficulty's damage multiplier (at speed 4 on the test save, Blood and Broken Bones, Geralt level 1: 200 physical, 336 Vitality lost); 5.x dealt 15 × speed force capped at a fifteenth of Geralt's maximum Vitality, and from the side too.

**Implementation (legacy):** no unit: 1.32's `ShouldDealDamageToActor` (hostile, not on or a horse, `InternalGetSpeed() >= 3`) and `DealDamageToCollidedActor` (the horse's weapon, `attack_speed_based`, head-on or a downed enemy, `DAMAGE_NAME_PHYSICAL` 50 × max(speed, 1), once a second per enemy).

**5.x:** `ShouldDealDamageToActor` also takes animals and calls the damage whenever `distanceBasedSpeed` ≥ 0.1 (or at speed ≥ 3 in slow motion or with an NPC rider); `DealDamageToCollidedActor` skips dead victims, takes side collisions, `DAMAGE_NAME_FORCE` 15 × max(speed, 1) head-on, 5 × from the side, at most the victim's maximum health ÷ 15, and plays a kick sound; `AST_Horizontal` instead of `AST_Jab`.

**Decisions:** legacy's (1.32's) rule restored (DH2 (a), project owner, 2026-11-02).

- **Deviation:** 5.x's kick sound plays when Roach tramples a living enemy (as 5.x's guard held it; a dead one still takes 1.32's hit, silently); 1.32 and legacy had none (DH2 (a), owner, 2026-11-02; the living-only part HORSE audit F6, confirmed by the owner, 2026-11-03).
- **Deviation:** 5.x's horse kick and rearing on their key are kept; legacy had none. They deal no damage (verified 2026-11-03: frozen hostile humans 1.5 m ahead and 2.5 m behind Roach took no hit after the key's event) (PH6, owner, 2026-11-02).

**Verified** (slice H3, 2026-11-03, ridden and riderless with Geralt standing in): a hostile head-on at speed 2 not hit; at 3 and 4 hit with 50 × speed physical (141 to 220 measured, within the melee roll), no force damage; a standing hostile from the side not hit; a knocked-down hostile from the side hit (187 to 217 at speed 4); a neutral goat not hit. Without the port (5.x's rule, with a moving horse's distance-based speed) all six cases failed: force damage instead (11, 5 from the side), and the goat was hit.

**Slices:** see [H3](#port-order).

### Dependencies on other areas

- **Done areas HORSE builds on:** STAM-03 (the horseback costs, `horseStamina.ws`, the mount test `gmtest_stam03_mount`), STAM-08 (NPC stamina), DMG (the formula the bonus goes through), SKL-18 (Adrenaline Burst in both trees, `GMAdrenalineBurstCostCut`'s skill selection), AI-05 (the horse weapon), WGT-06 and WGT-09 (horse gear, the gait).
- **Areas HORSE shares with:** SKL-07 (the trampling adrenaline; done, on master `f2d7f38d`).

### Hand-offs received

| From | Item | HORSE |
|---|---|---|
| Sweep B (HORSE-NEW1, HORSE-NEW2), sweep D (G14, Q2, decided "map HORSE as an area") | `DealDamageToHostiles`; the five `CastSign` units | HORSE-01; HORSE-02 |
| STAM (hand-off) | Horse Axii cost; no stamina drain on enemies hit from horseback; the horse sprint cost 5 → 7.5 | HORSE-02; HORSE-01; WGT-06 took the sprint cost (PW9), inert (PH8) |
| DMG (hand-off) | The horse-speed attack power bonus removed from `GetPowerStatValue` | Nothing: only Mutagen 25's is there, ALCH-12's |
| SWD (hand-off) | Horseback damage from weapon damage (changelist 488) | HORSE-01 |
| SKL (D42) | Horse Axii's adrenaline payment with Adrenaline Burst | HORSE-02 (DH3) |
| WGT (PW9) | None: the blinders' panic and the sprint cost went to WGT-06 | — |
| STAM-03's attribution notes ("HORSE: attack cost x3") | The ×3 multiplier | Nothing: STAM-03 ported it |

**Temporary deviations "until HORSE"** ([deviations.md](deviations.md)): none recorded.

### Hand-off to other areas

| Area | Changes |
|---|---|
| WGT | For the record (no change): WGT-06's sprint cost 7.5 is read by no code in legacy or 5.x (PH8) |
| AI | For the record (no change in HORSE): AI-05's horse weapon (`mon_horse_weapon _Stats`) adds nothing to trampling by a ridden horse, in 1.32, legacy and the port alike (the attack looks the horse's item id up in the rider's inventory); it reaches a riderless horse's trampling (verified 2026-11-03, slice H3 and HORSE audit F1) |

### Save impact

None expected: the functions are read live; HORSE-02's cost is a function, not a state field.

### Area decisions

**Decided** by the project owner (2026-11-02, "take the recommendations"): DH1 (a), DH2 (a), DH3 (a). The porter's calls PH1 to PH9 are confirmed.

| # | Question | Options | Recommendation |
|---|---|---|---|
| DH1 | Several enemies in one horseback swing (HORSE-01). The game reuses one attack for every enemy the swing reaches and never clears its damage, so each enemy's hit carries the previous ones' (vanilla's defect); legacy's speed bonus then multiplies the pile. At a full gallop with a 300-damage sword: legacy's code gives the first bandit 600, the second 1,800 and a third 4,200; the changelist says "up to x2" (1.32 and 5.x: 300 + 255 direct, then 600 + 510) | (a) a fresh attack for each enemy: every enemy gets the weapon damage × up to 2, as the changelist says (a fix, a deviation from legacy's code); (b) legacy's code as it is | **(a)**: the changelist states the intent, and a second enemy taking triple the first's is a defect, not a design; the cost is one line |
| DH2 | Trampling (HORSE-03). Legacy kept 1.32's rule (head-on at a canter or full gallop, hostiles only, 50 × speed physical) and cut the horse weapon to 40 bludgeoning and 20 rending. 5.x reworked it: also from the side and at any speed, animals too, 15 × speed force head-on and 5 × speed from the side, capped at 1/15 of the victim's maximum health. At a full gallop into a 1,500-Vitality bandit: legacy +200, 5.x +60 (from the side +20) | (a) legacy's (1.32's) rule; (b) 5.x's, a recorded deviation | **(a)**: legacy behaviour first, and legacy tuned the horse weapon against 1.32's rule; 5.x's side and low-speed hits make most brushes with an enemy a hit |
| DH3 | Adrenaline Burst pays horse Axii with adrenaline (HORSE-02), in neither legacy's description nor the changelist (SKL's D42 calls it a leftover). Example: at 45 stamina and 1 adrenaline point Geralt can calm Roach with the perk (and hold it about 21 s: 12 on the stamina, 9 on the adrenaline; HORSE audit F4); without it he cannot | (a) port it in both trees (`perk_10`, `perk_42`), the description unchanged (legacy's); (b) port it and add a sentence to the description (9 languages, the project has no translations); (c) leave the payment out (a deviation) | **(a)**: legacy's behaviour and text; (b) goes to Later |

**Porter's calls** (each follows legacy or has no play effect; confirmed by the owner, 2026-11-02):

| # | Call |
|---|---|
| PH1 | HORSE-01: `@replaceMethod` of `DealDamageToHostiles` with 5.x's body (1.32's) and legacy's block; the unused `baseDamage` parameter stays in the signature |
| PH2 | HORSE-02: replaced `OnEnterState` and `StartCastingSign` with legacy's lines, the two resource functions added, 50 as a function; slice H2 first checks that a replaced state `entry` function runs (a wrapper of one never runs, [development.md](../development.md)); if it does not, a timer on `W3VehicleCombatManager` started in `OnEnterState` drains and confuses every 0.1 s and ends the hold (`ForceDeactivateAction('VehicleCastSign')`) when the resources run out, the same behaviour |
| PH3 | HORSE-02 in the new tree: `perk_42` (`S_Perk_42`) counts as Adrenaline Burst, as `GMAdrenalineBurstCostCut` does; the conversion is legacy's (max stamina ÷ max adrenaline) in both trees |
| PH4 | HORSE-02: legacy's leftovers are not ported (`staminaSpent`, the commented-out payment to 50); no state fields |
| PH5 | HORSE-02: 5.x's voice line on the cast (`ChillOutHorse`) kept |
| PH6 | 5.x's horse kick and rearing (`HorseKick`) kept: no legacy counterpart, an animation with no damage code (the slice checks it deals none) |
| PH7 | 5.x's horse handling legacy never touched kept: the gallop's stamina regeneration after 0.45 s (1 s in 1.32), carts, loot from horseback, mount, dismount, camera and lean animations. Recorded as deviations when the slices land (owner, 2026-11-02) |
| PH8 | WGT-06's horse sprint cost stays as ported: inert in legacy (dead code behind the default "simple stamina management") and in 5.x (no reader), so no change |
| PH9 | HORSE is ported as one area with one audit after its last slice |

### Port order

Each slice compiles and is verified on its own in both trees (the regression in both). Tests mount Roach by script (`gmtest_stam03_mount()`) on the test save.

| # | Slice | Verified by |
|---|---|---|
| H1 | HORSE-01 (with DH1): `horse/horseCombat.ws` | Scripted: a test method on the `SwordAttack` state calls `DealDamageToHostiles` with speeds 0, 1, 2, 3, 4 against the human test dummy; a probe on the damage processor reads the action's damage types: the weapon's damage × 1, 1.25, 1.5, 1.75, 2, no direct damage; the dummy's stamina unchanged (5.x: −100); the knockdown at 4 only; two dummies in one call: each × 2 (DH1 (a)). A real swing at a canter by scripted input (as STAM-03's horseback test) |
| H2 | HORSE-02 (with DH3): `horse/horseAxii.ws` | First a probe that the replaced `entry` function runs (PH2). Scripted input on `VehicleCastSign`: refused at 49 stamina, started at 50 and 60; stamina falls about 4 a second while held, no regen; the hold ends at 0; with Adrenaline Burst (classic `perk_10`, new tree `perk_42`, each in its tree): a start at 45 stamina and 1 adrenaline, adrenaline drained after the stamina; at 30 stamina refused by Axii's own cost; the horse confused while held; its panic (raised by script) falls |
| H3 | HORSE-03 if DH2 (a): `horse/trampling.ws` | Scripted: `DealDamageToCollidedActor` on the test dummy at speeds 2, 3, 4, head-on and side: 1.32's damage (the horse weapon + 50 × speed physical), none from the side, none below speed 3; an animal not hit; then a real ride into a dummy |

**Later:** Adrenaline Burst's description mentions horse Axii (DH3 (b)).

### HORSE audit (2026-11-03)

Done by a fresh session ([audit](../feature-mapping.md#audit-signing-a-feature-off)) on the integrated master `f2d7f38d` (port) and `754ad2fd` (docs), reading code and docs, with game runs in both trees on 2026-11-03. Read: `horse/horseCombat.ws`, `horse/horseAxii.ws`, `horse/trampling.ws`, `tests/gmTestsHorse.ws`, against legacy (`legacy-GM`), 1.32 (`vanilla-1.32`) and 5.x (`vanilla-5.x`), with their callers.

**How it was checked:**
- **Code:** each replaced body line by line against legacy's and 1.32's, and against 5.x's for what 5.x added (the voice line, the kick sound, `distanceBasedSpeed`); every caller of the three functions (`DoAttack`'s sweeps and slow-motion path; the horse component's two collision events and the NPC horse's charge task, `CBTTaskHorseCharge`); `W3Action_Attack.Init` and `FillDataFromWeapon`; the attitude a horse takes from its rider (`OnMountFinished`, `Tame`); 5.x's `CanUseSkill` and `IsSkillEquipped`, and SKL's skill IDs for Adrenaline Burst.
- **Sweeps and tools:** `unit_sweep.py --unattributed` for horse, vehicle, mount, panic, `speed_based`, `IsUsingHorse`, `HorseRiding`, `GetUsedVehicle`, `IsUsingVehicle`, dismount, trampl, `VehicleCastSign`, Axii (scripts and XML): 0 units; `check_modsigns.py`: 519 bodies, 0 unmarked, no native wrap; `deviations.py --check`: up to date.
- **In game** (scripted calls; a throwaway probe on gm/horse-audit `4e7e966b`, `tests/gmTestsHorseAudit.ws`, not for integration; classic tree, beside riderless Roach, a frozen hostile human 3 m ahead): Roach's weapon id looked up in Geralt's and the human's inventories; Roach's real collision damage (`DealDamageToCollidedActor`) at speed 4 head-on with the human as the rider on Geralt, with Roach herself as the attacker on Geralt, and with Geralt as the rider on the human (his adrenaline after); the two seams without a test value.
- **Regression** on the integrated build `f2d7f38d` (`regress.py --trees both`): classic 1,562 and 163 passed, new tree 1,562 and 163 passed, 0 failed.

**Checked and holding:**
- **Both trees.** HORSE-02 is the only skill-dependent part. `perk_42` is the new tree's Adrenaline Burst (SKL-18, D49; legacy's effect in both trees), and `GMHasAdrenalineBurst` reads `perk_10` or `perk_42` as `GMAdrenalineBurstCostCut` does. New-tree perks sit in skill slots like the classic ones (5.x's `CanUseSkill` needs `IsSkillEquipped`; SKL-01's slot fixes swapped `perk_38` through the menu), so the tests' `EquipSkill` is how a player has it. HORSE-01 and HORSE-03 touch no skill. The regression ran each tree with its own perk.
- **Completeness.** The six HORSE units are ported (PH4's leftovers not, as decided); no unattributed unit. Legacy's other horse changes are the areas' in [Already ported by other areas](#already-ported-by-other-areas).
- **HORSE-01** is legacy's block in 5.x's body, plus DH1's fresh attack per enemy (deleted after its hit, as 5.x deleted the shared one after the loop); the callers are 1.32's.
- **HORSE-02** is legacy's state code with `witcher` for `thePlayer` (the same object) and 5.x's voice line, which sits in `OnProcessAnimEvent`, outside the replaced functions.
- **HORSE-03** is 1.32's rule. One harmless reordering: the port checks the 1 s per-victim memory before the horse's weapon, so a horse without a weapon records a side brush (nothing in play).
- **The test seams.** `GMTrampleSpeed()` returns `InternalGetSpeed()`, which 1.32 reads at both places the port reads the seam; `GMHorseAxiiHeld()` returns `theInput.IsActionPressed('VehicleCastSign')`, legacy's read. Neither depends on the tree. Their wrappers live in `tests/` and pass the value through while no test sets one (probe: 0 and 0, false and false).
- **The tick rate.** Legacy's loop is the same `Sleep(0.1f)`. A latent `Sleep` resumes on the first frame after its time, so a tick takes 0.1 s plus up to a frame: about 4.3 stamina a second at 60 fps and 3.75 at 30. The measured 3.8 is legacy's code at the test machine's frame rate, not a port difference.
- **Conventions.** Feature tags and `//modSigns` markers in every replaced body; no leftovers or absolute paths; the four deviations are recorded.

**Findings:**

| # | Finding | Evidence | Severity | Kind |
|---|---|---|---|---|
| F1 | **The horse weapon finding holds, but for another reason, and the weapon matters elsewhere.** The trample attack names the rider as attacker, and `FillDataFromWeapon` looks the horse weapon's item id up in the rider's inventory. Item ids are per inventory: the id is not missing there, it names some other item of the rider's. On the test save it is Geralt's "Body feet 01", which has no damage. On another save, if the id named a weapon in the rider's inventory, its damage would be added to the trample, by chance (1.32, legacy and the port alike). The horse weapon reaches only a **riderless** horse's trampling, where the horse is the attacker: Roach hitting Geralt carried 61.5 from her weapon (AI-05's 40 + 20) on top of the 213 physical. A riderless horse hostile to Geralt is plausible: a horse takes its rider's attitude group when mounted and nothing restores it (`originalAttitudeGroup` is stored and never read). So an enemy's horse that lost its rider is the case AI-05's cut (1.32's 270 → 60) was likely aimed at. That is the same in legacy, so there is no play difference and no owner decision. | probe: `HAUDIT A Geralt's inventory: valid true, name 'Body feet 01', damage types 0`; the human's: invalid; case C: weapon part 61.5, physical 213.5. Code: `attackAction.ws` `FillDataFromWeapon` (`inv = attacker.GetInventory()`), `horseComponent.ws` `OnMountFinished` | low | **doc correction** (made here: [HORSE-03](#horse-03-trampling), the AI hand-off row). *Later*, if wanted: the trample reads the weapon from the horse's inventory (a vanilla defect; it would add the horse weapon to every ridden trample, unlike legacy) |
| F2 | **DH2 also changes how hard enemy riders trample Geralt, which the entry never said.** The rule is the horse component's for every horse, so an enemy rider's horse now hits Geralt head-on at a canter or gallop for 50 × speed physical, through his armor, with the rider's attack power and the difficulty's damage multiplier. 5.x dealt 15 × speed force, capped at 1/15 of Geralt's maximum Vitality, and also from the side (5 × speed). This is legacy's behaviour, so it is covered by DH2 (a); the owner may want to know the size of it. | probe case B (Blood and Broken Bones, Geralt level 1, a bandit as rider, speed 4): 200.9 physical, 336 Vitality lost; 5.x's formula gives at most 60. Code: `ShouldDealDamageToActor` (`attacker = GetCurrentUser()`), called by `OnCharacterCollision` and `CBTTaskHorseCharge` | medium (in play; as legacy) | **doc correction** (made here: HORSE-03's "What it does") |
| F3 | **Trampling still gives Geralt adrenaline: 0.1 per hit.** The entry said SKL-07's G12 fix leaves trampling with none. The fix removed only `attack_speed_based`'s extra 0.025. The trample is a melee attack of Geralt's, so it earns the base gain of every damaging melee hit on a hostile, the same as legacy's code (`OnProcessActionPost`'s `GetAttributeValue('focus_gain')`, legacy's condition). The fix itself is in `f2d7f38d` ("being fixed now" was stale). | probe case E: adrenaline 0 → 0.1 after one trample (0.125 would mean the 0.025 was back); legacy `playerWitcher.ws` gain branch | low | **doc correction** (made here: the Already-ported row, Dependencies) |
| F4 | **The hold's rate and its examples in the docs.** The rate is about 4 a second, frame-bound (see Checked and holding). Some docs disagree with that: the Changes-at-a-glance row and H2's plan said 5 a second, and DH3's example said 45 stamina and 1 adrenaline hold "about 16 s" (it is about 21 s: 12 on the stamina, 9 on the adrenaline, as HORSE-02's "What it does" says). The same "5 a second" stands in `horseAxii.ws`'s header comment and in [open-questions.md](../open-questions.md)'s "Omissions found by HORSE". | `horseAxii.ws` lines 2–3; this entry | low (text) | **doc correction** (this entry made here; the code comment and open-questions.md left for the parent) |
| F5 | **The regression covers less of HORSE-02 and HORSE-03 than the slices did.** `gmtest_regress()` checks horse Axii's starting rule only. It does not check the drain (stamina first, the shortfall from adrenaline at max adrenaline ÷ max stamina, the 0.5 s regen delay), which is callable on a test state like the starting rule. Trampling's checks always make Geralt the rider, so nothing checks a riderless horse as attacker (F1) or an NPC rider on Geralt (F2). | `tests/gmTestsHorse.ws` `GMTestHorse02Resources`, `GMTestHorse03Cases` | low | **clear fix** (tests): `GMDrainResourcesForAxii` at 0.3 stamina and 1 adrenaline (stamina 0, adrenaline −0.006); probe cases B and C as checks (no weapon part with a rider, the horse weapon without one) |
| F6 | **5.x's kick sound now plays on a corpse.** The port dropped 5.x's `IsAlive()` guard, which also held the sound (DH2 kept the sound). 1.32 hit a downed enemy whatever its state, but had no sound. A head-on collision with a dead hostile at a canter now plays the kick, if corpses raise the horse's character collision (unchecked). | `trampling.ws` lines 233–243; 5.x `DealDamageToCollidedActor` | low (sound only, maybe never) | **clear fix**: play the sound only for a living victim |
| F7 | **Stale lines outside this entry.** [features/README.md](README.md)'s HORSE row and its "Next" paragraph say "porting". [open-questions.md](../open-questions.md) still has DH1 as open: the contradiction entry says "Open: the owner's DH1", and the legacy test says "not yet decided". | those lines | low | **doc correction** (for the parent or integration) |

**Fixed** (slice H4, 2026-11-03, verified on the area build in both trees): F6, the kick sound only for a living victim (`trampling.ws`, through `GMTrampleKickSound`, which a test wrapper counts); F5, three regression checks: the drain at 0.3 stamina and 1 adrenaline (stamina 0, adrenaline 0.994 with the tree's Adrenaline Burst, 1 without it; `GMTestHorse02Drain`, in `gmtest_regress()`), an enemy rider's horse on Geralt (no horse-weapon part, 213 physical at speed 4) and a riderless one (her weapon's 63 plus 205 physical), and the kick sound (1 for a living enemy, 0 for a dead one, still hit) (`GMTestHorse04Riders`, in `gmtest_panel()`); F4's code comment and open-questions.md line; F7's open-questions.md lines. Each new check failed first: the drain with adrenaline's payment taken out (both trees), the sound with the living check taken out, the two rider cases on 5.x's rule (force damage instead).

**Open checks** (need a cleared run or real riding): those of the three entries (a real swing at a canter or gallop, a real held Axii on a panicked Roach, a real ride into enemies head-on and from the side); an enemy rider trampling Geralt in a real fight (F2), and a riderless enemy horse's attitude after its rider dies (F1, code only); whether a corpse raises the collision (F6).

#### HORSE audit close-out

**HORSE signed off by the owner (2026-11-03).** Every finding is fixed, corrected or recorded: F4 to F6 fixed in H4 (scripted, in the regression), F1, F3 and F7 doc corrections. The owner confirmed F2 (legacy's stronger trampling also applies to enemy riders hitting Geralt, as DH2 (a) decided) and F6's porter's call (the kick sound only for a living victim). The open checks above wait for the owner's playthrough.

**Regression** on the integrated build (master `41eedb70`, `regress.py --trees both`): `gmtest_regress()` 1,584 passed and `gmtest_panel()` 166 passed, 0 failed, in each tree; saves clean.

### For the shared docs

- development.md, Testing in game: **a state's private function can be called from a test without entering the state**: a test `@addMethod` on the state (`W3VehicleCombatManagerStateSwordAttack`) calls it, reached with `mgr.GetState('SwordAttack')` and a cast; the state's own fields set in its `OnEnterState` (`rider`) must be set by the test method first (HORSE slice H1, 2026-11-03, `GMTestHorseDeal`).
- development.md, Testing in game: **horse combat off the horse**: the horse's combat manager exists only while Geralt rides (`GetUserCombatManager()`), but `new W3VehicleCombatManager in theGame` with its `rider` set by a test `@addMethod` (no `Setup`, which registers input listeners) gives the states' functions on foot (HORSE slice H1).
- development.md, Testing in game: **a sword drawn by script in `gmtest_regress()` is not always in the hand in `gmtest_panel()`** (seen 2026-11-03, classic tree, one run): a check that needs the weapon in hand (`GetItemFromSlot('r_weapon')`) runs in the regression when one is held and draws only as a fallback (`GMTest_horse`).
- development.md, Annotations: **`@replaceMethod` of a state's `entry` function runs** (declared as a plain `function`, without `entry`): `W3VehicleCombatManagerStateCastSign.StartCastingSign`, replaced with its `Sleep` loop, ran when the state called it (HORSE slice H2, 2026-11-03), unlike a wrapper of one.
- game-automation.md, Input simulation: **a held key in replaced code**: route the replaced body's `theInput.IsActionPressed(...)` through a small Ghost Mode function (`GMHorseAxiiHeld()`) that a test wrapper answers as held (HORSE slice H2); horse Axii is pressed through the combat manager's `OnCastSign` (a test `@addMethod` event on `W3VehicleCombatManager`, as STAM-03's `OnAttack`).
- game-automation.md, Horseback: hostile frozen humans 4 m ahead raise Roach's panic (0.17 to 0.19 within 5 s with four), so a calming test needs no real fight (`gmtest_horse02_threat`).
- development.md, Testing in game: **a behaviour variable set by script does not read back in the same call** (`SetBehaviorVariable('speed', 4)` on Roach, then `GetBehaviorVariable`: 0; and 5.x's `InternalGetSpeed()` reads the moving agent's speed anyway): a replaced body that needs a value the tests set reads it through a Ghost Mode method a test wrapper answers (`GMTrampleSpeed`, HORSE slice H3).
- development.md, Testing in game: **a riderless Roach is not hostile to an enemy of Geralt's**, so her collision rule does nothing; a test wrapper of `W3HorseComponent.GetCurrentUser` makes Geralt her rider for one call (HORSE slice H3, the regression's trampling checks).
- game-automation.md, Input simulation, Horseback: a real sword swing standing on Roach, by `OnAttack` with a press, hit a frozen dummy 1.8 m to Geralt's side and 0.3 m ahead (`gmtest_horse01_swing_a/b`, HORSE slice H1).
- development.md, Testing in game: **item ids are per inventory**: an id from one inventory can name another item in another (Roach's weapon id is Geralt's "Body feet 01" on the test save), so code that looks an id up in the wrong inventory reads a random item, not nothing (HORSE audit F1, 2026-11-03).
