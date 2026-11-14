# HORSE: horse combat

What Geralt can do from Roach's back and what it costs: the sword hit from horseback (its damage and what it does to the enemy's stamina), calming a panicking horse with Axii, and the horse running enemies down (trampling). Ghost Mode's changelist has its own section, "Horse combat" (lines 482–490); legacy's horse Axii cost is in the code only.

**The player-visible texts first.** Legacy's changelist, quoted exactly: "Attacking from horse no longer drains 100% stamina."; "Attacks from horseback drain lightAttackCost*3 stamina."; "All the attacks from horseback are considered heavy (same as vanilla)."; "Bonus damage when attacking from horseback now depends on weapon damage."; "Higher speed means higher bonus damage: up to x2 when attacking at full speed."; "Attacking at maximum speed adds knockdown to the attack." The only description involved is Adrenaline Burst's (horse Axii's adrenaline payment, HORSE-02), the same in legacy and the port: "Increases Adrenaline gain by $I$%. In addition to usual Battle Trance effect, each Adrenaline Point also decreases melee action Stamina cost by $I$%." (`gm_skill_desc_adrenaline_burst`, 2110992319; classic `perk_10`, new tree `perk_42`); it says nothing about the horse. 5.x's own texts: classic `perk_10` "Increases Adrenaline generation by 5%. Using Signs now generates Adrenaline Points.", new tree `perk_42` "Increases Adrenaline generation by 6% and allows Signs to generate Adrenaline. Vitality gain: +3%" (already replaced by legacy's text, SKL-18). No horse tutorial or tooltip states a number legacy changed.

**What 5.x did in this area** (from `vanilla-5.x`, unverified in game). The horse combat code is 1.32's: `useVehicle.ws`'s sword attack (`DealDamageToHostiles`: the victim's `DrainStamina(ESAT_FixedValue, 100, 1)` and a direct-damage bonus of 50, or 50 × (1.1 + speed) from a trot up) and its Axii state are unchanged, but for a voice line Geralt says when he calms the horse (`PlayBattleCry('ChillOutHorse')`). What moved, outside legacy's code: **trampling** (`W3HorseComponent.DealDamageToCollidedActor`, `ShouldDealDamageToActor`; HORSE-03), a horse **kick and rearing** on a key (`HorseKick`, an animation event, no damage code), the horse's own gallop stamina (it now drains from the gallop for a horse and only at a full gallop for a cart, and regenerates after 0.45 s instead of 1 s outside races; `exploration.ws`), the dead `ESAT_Sprint` drain removed (see [the sprint cost](#already-ported-by-other-areas)), carts, loot from horseback, and mount, dismount, camera and lean animations (`horseRiding.ws`, `dismountHorse.ws`, `mountHorse.ws`).

**How legacy Ghost Mode implements it.** Scripts only, all in `useVehicle.ws`: `W3VehicleCombatManagerStateSwordAttack.DealDamageToHostiles` (HORSE-01), and in the `CastSign` state the fields, `OnEnterState`, `StartCastingSign` and two new functions, `HasResourcesForAxii` and `DrainResourcesForAxii` (HORSE-02). Legacy's other horse changes belong to areas already ported (below). No XML, CSV or binary unit is HORSE's.

Unit lists: [attribution.csv](attribution.csv). **6 units carry a HORSE feature**, all GM scripts with no NG+ counterpart: HORSE-01 1, HORSE-02 5. Port status: **signed off** by the owner (2026-11-03). Open checks need real riding (the owner's playthrough).

## Scope

**HORSE covers** the sword hit from horseback (its damage and its effect on the enemy's stamina), horse Axii's cost in both skill trees, and trampling (the horse's collision damage, which 5.x reworked).

**Unchanged by legacy, and by 5.x** (from the code): every horseback attack is a heavy attack (`attack_heavy`, `EHRT_Heavy`); the knockdown at full gallop (speed 4); the attack's reach by speed (`GatherEntitiesInAttackRanges`); the horse combat slow motion; a hit from horseback at full gallop +100% crit chance for sword swings (`CR4Player.GetCriticalHitChance`); horse Axii keeps the horse calm for 5 s after it ends when the panic is below 5%; horse Axii has no sign cooldown and is not refused by one in legacy or the port (the cooldown is checked on the foot cast input and added by the signs' cast states, which the horse cast never enters).

### Already ported by other areas

| Subject | Ported by | What |
|---|---|---|
| A horseback sword attack costs 3 light attacks of stamina, refused without it; bombs and the crossbow refused without stamina (changelist 486) | STAM-03 (signed off) | `stamina/horseStamina.ws` (`GMHorsebackStaminaMult`); paid in `SwordAttack.DoAttack` (a deviation: legacy missed the quick swing) |
| Mutagen 25 (Nekker Warrior decoction): no horseback attack power, no horse panic immunity (5.x's horse block in `GetPowerStatValue` holds only Mutagen 25's) | ALCH-12 (signed off) | `alchemy/decoctionsSustain.ws` |
| Bolts get no galloping crit chance | XBOW-06 (signed off) | `skills/oils.ws` |
| Saddlebag capacity, horse gear weights, the Toussaint and Ofir blinders' panic resistance (60 → 75, 55 → 70), the base horse's sprint cost (`HorseLevel1` `sprint_stamina_cost` 5 → 7.5) | WGT-06 (PW9, signed off) | `gen_wgt.py`. **The sprint cost is read by no code**, in legacy as in 5.x: the horse's `ESAT_Sprint` drain runs only without "simple stamina management", which is on by default (only a debug command turns it off) in 1.32 and legacy, and 5.x removed the drain; the horse's gallop costs a fixed 3.33 stamina a second. Nothing to change: legacy's value was inert too (PH8) |
| No canter or gallop while Geralt cannot sprint (overburdened) | WGT-09 (signed off) | `weight/overEncumbered.ws` |
| Horse gear and saddle prices, `mod_horse` | ECON-01, ECON-05 (signed off) | item data, price table |
| The horse's weapon, used by trampling (`mon_horse_weapon _Stats`: bludgeoning 250 → 20 + 20, rending 20); it reaches only a riderless horse's trampling (HORSE-03) | AI-05 (signed off) | `items/gm_ai_weapons.xml` |
| Trampling gives Geralt no extra adrenaline (`attack_speed_based`'s `focus_gain` 0.025 removed; gap G12); the base 0.1 of every melee hit on a hostile that deals damage stays, as in legacy's code (**verified**: 0.1 per trample hit) | SKL-07 (done, sweeps' decision) | one more extend in `gm_adrenaline.xml` |
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
| HORSE-02 | Horse Axii costs stamina | Free (only Axii's own cost must be there to start); the horse is confused 0.1 s per frame while the key is held | Starts only with 50 stamina; 0.5 stamina every 0.1 s while held (each tick waits for the next frame, so about 4 a second), ending at 0; with Adrenaline Burst adrenaline covers what stamina cannot (to start and while held); 0.5 s confusion per 0.1 s tick | 5 units of the `CastSign` state |
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
| Port status | signed off |
| Open checks | a real swing at a canter or full gallop (real input: scripted input cannot set the horse's speed), owner's playthrough |
| Save impact | none (expected) |
| NG+ counterpart | none (script) |

**What it does** (changelist 485, 488–490): a sword hit from horseback no longer empties the enemy's stamina, and its bonus damage is the weapon's own: each damage type of the weapon gets a share more by the horse's speed, speed/4 (walk 1, trot 2, canter 3, full gallop 4): +25% walking, +50% trotting, +75% at a canter, double at a full gallop; standing still, no bonus. The bonus then goes through the damage formula like the rest of the hit (armor first, then attack power, resistances), where vanilla's bonus was direct damage that ignores armor and resistances. Example, a sword of 300 slashing damage at a full gallop: legacy 600 slashing, the enemy's stamina untouched; 1.32 and 5.x 300 slashing plus 255 direct damage, and the enemy loses 100 stamina, which in the port (STAM-08) would stop it attacking (no attack tickets below 10% until it has 33.4% again) and from guarding or parrying for a while. At full gallop the hit still knocks the enemy down.

**Implementation (legacy):** `DealDamageToHostiles`: the `DrainStamina(ESAT_FixedValue, 100, 1)` and the direct-damage bonus commented out; after `damage.Init`, if speed > 0, for each of the action's damage types above 0 `AddDamage(type, value × ClampF(speed / 4, 0, 1))`; the knockdown applicator at speed ≥ 4, the sound, the effects and the blood trail as vanilla. The `baseDamage` parameter (50) is no longer read.

**5.x:** 1.32's function, unchanged; the call sites (`DoAttack`, its two sweeps and the slow-motion path) too.

**Decisions:** legacy's (PH1).

- **Deviation:** each enemy reached by one horseback swing gets an attack of its own, so each takes the weapon's damage × up to 2, as the changelist says; legacy's code reused one attack whose damage piled up from enemy to enemy (at a full gallop with a 300-damage sword: 600, then 1,800, then 4,200), a defect vanilla had and legacy's speed bonus multiplied (DH1 (a), owner, 2026-11-02).
- **Deviation:** 5.x's horse handling that legacy never touched is kept: the horse's gallop stamina regenerates after 0.45 s (1 s in 1.32), and 5.x's carts, loot from horseback, and mount, dismount, camera and lean animations stay as 5.x has them (PH7, owner, 2026-11-02).

**The defect behind DH1 (vanilla's, made worse by legacy):** the function creates one attack action and re-initialises it for each enemy in the swing, but `W3Action_Attack.Clear` does not clear the damage list (it overrides `W3DamageAction.Clear`, which does, without calling it). Each enemy's `Init` adds the weapon's damage on top of the previous enemy's, so in 1.32 and 5.x the second enemy of a swing takes the weapon damage and the direct bonus twice, and legacy's loop multiplies the accumulated list. **Verified** in game for legacy's code, 5.x and the port.

**Slices:**

1. **H1, horseback hits.** Verified 2026-11-03, both trees (scripted calls of the state's own hit function at speeds 0 to 4 and on two enemies; a real standing swing by scripted input; `GMTest_horse` in `gmtest_regress()`): the weapon's damage × 1 to 2 by speed, no direct damage, the enemy's stamina untouched, the knockdown at 4 only, and each of two enemies × 2.

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
| Port form | `horse/horseAxii.ws`: `@replaceMethod(W3VehicleCombatManagerStateCastSign)` `OnEnterState` (the 50 check) and the entry function `StartCastingSign` (legacy's 0.1 s loop; a replaced entry function runs, PH2), `@addMethod` `GMHasResourcesForAxii` and `GMDrainResourcesForAxii` on the state, the cost a function (`GMHorseAxiiCost`, no state fields), the key read through `GMHorseAxiiHeld()` (so tests can hold it) |
| Port status | signed off |
| Open checks | a real held Axii on a horse panicked by enemies (real input) |
| Save impact | none (expected) |
| NG+ counterpart | none (script) |

**What it does** (code only; the changelist does not mention it): calming Roach with Axii (the sign key while mounted) needs at least 50 stamina to start, and holding it costs 0.5 stamina a tick, every 0.1 s plus up to a frame (a latent `Sleep` resumes on the first frame after its time: about 4.3 stamina a second at 60 fps, 3.75 at 30; legacy's code alike), with stamina regeneration paused (each drain sets a 0.5 s delay); it ends when the key is released or stamina runs out. The 50 is a threshold, not a cost: a start at 60 stamina spends nothing until the hold. With Adrenaline Burst adrenaline counts as stamina at max stamina ÷ max adrenaline per point (33.3 stamina per point at 100 stamina and 3 points): to start, stamina plus adrenaline must make 50; while held, adrenaline pays what stamina cannot (0.015 of a point per tick at those maxima). Example, without the perk: at 60 stamina Geralt can hold Axii for about 16 s; at 45 he cannot cast it. With the perk, 45 stamina and 1 adrenaline point (45 + 33.3) start it, the 45 stamina last about 12 s and the adrenaline about 9 s more. Vanilla's check that Axii's own cost (40 in legacy) is there still runs when the sign is cast (`InitCastSign`); the horse cast does not pay it (**verified**), so with Adrenaline Burst alone the adrenaline only helps a start at 40 to 49 stamina, or with Rage Management (its sign casts with adrenaline). Each tick confuses the horse for 0.5 s (vanilla 0.1 s each frame), so the calm lingers up to half a second after the release.

**Implementation (legacy):** the `CastSign` state: `ON_HORSEBACK_AXII_COST` 50 and `staminaSpent` (fields); `OnEnterState` calls `StartCastingSign` only if `HasResourcesForAxii(50)`; `HasResourcesForAxii(cost)`: stamina ≥ cost, or with `S_Perk_10` stamina + adrenaline × max stamina ÷ max adrenaline ≥ cost; `DrainResourcesForAxii(cost)`: `DrainStamina(ESAT_FixedValue, cost, 0.5)` if any stamina is left, and with the perk the part above the stamina from adrenaline (`DrainFocus`); `StartCastingSign`'s loop sleeps 0.1 s instead of a frame, holds while the key is pressed and `HasResourcesForAxii(0.5)`, then `ApplyEffectOnHorse(0.5)` and `DrainResourcesForAxii(0.5)`. Leftovers with no effect: `staminaSpent` is counted but read only by a commented-out payment up to 50 at the end (`OnLeaveState`), so legacy once charged 50 per cast and no longer does.

**5.x:** 1.32's state with a voice line on the cast. The perk check names only `S_Perk_10`, which exists in 5.x's classic tree; the new tree's Adrenaline Burst is `perk_42` (`S_Perk_42`).

**Decisions:** legacy's, in both trees (PH2, PH3); Adrenaline Burst pays horse Axii, its description unchanged (DH3 (a), project owner, 2026-11-02).

- **Deviation:** Geralt's voice line when he calms the horse (5.x's `ChillOutHorse`) is kept; legacy had none (PH5, owner, 2026-11-02).

**Slices:**

1. **H2, horse Axii.** Verified 2026-11-03, both trees (scripted presses of the horse cast with the key held by a test wrapper; `GMTestHorse02Resources` and `GMTestHorse02Drain` in `gmtest_regress()`): refused below 50 stamina and without the perk at 45 stamina and 1 adrenaline; started at 50 and with the perk at 45 and 1 adrenaline; held, 0.5 stamina a tick with no regeneration, then adrenaline with the perk, ending when the resources run out; at 30 stamina and 1 adrenaline Axii's own cost refuses the cast; Roach's panic from nearby hostiles falls to 0 while held.

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
| Port form | `horse/trampling.ws`: `@replaceMethod(W3HorseComponent)` `ShouldDealDamageToActor` and `DealDamageToCollidedActor` with 1.32's rule (5.x's kick sound kept for a living victim, through `GMTrampleKickSound`); the speed both read goes through `@addMethod` `GMTrampleSpeed()` (5.x's `InternalGetSpeed()`), so the tests can set it |
| Port status | signed off |
| Open checks | a real ride into enemies at a canter and a gallop, and past one from the side (real input: scripted input cannot set the horse's speed); an enemy rider trampling Geralt in a real fight; a riderless enemy horse's attitude after its rider dies (code only); whether a corpse raises the horse's character collision (the kick sound); owner's playthrough |
| Save impact | none (expected) |
| NG+ counterpart | none (script; the weapon's NG+ copy is AI-05's) |

**What it does:** the damage Roach deals when she runs into an enemy. Legacy kept 1.32's rule and changed what goes into it: the horse weapon's bludgeoning 250 → 40 (AI-05, ported) and no adrenaline for Geralt (SKL-07). 5.x reworked the rule itself. Example, Roach ridden by Geralt at full gallop (speed 4) head-on into a bandit with 1,500 Vitality: legacy (1.32's rule, the port) deals 200 physical; 5.x dealt 60 force damage (capped at 100, a fifteenth of his Vitality) and also hit from the side (20), at lower speeds too (whenever 5.x's `distanceBasedSpeed` is 0.1 or more), and ran over animals as well. Everything goes through the damage formula.

**The horse weapon adds nothing to a ridden horse's hit** (**verified**; 1.32, legacy and 5.x alike): the attack names the rider as the attacker, and `W3Action_Attack.FillDataFromWeapon` looks the horse weapon's item id up in the attacker's inventory, where that id names some other item of the rider's (item ids are per inventory), usually one without damage; if it named a weapon, its damage would be added by chance. So AI-05's horse weapon values do not reach trampling by a ridden horse, Geralt's or an enemy rider's. They reach only a **riderless** horse's trampling (the horse is then the attacker: about 60 from the weapon on top of the 50 × speed, verified), e.g. an enemy's horse that lost its rider, which keeps the rider's attitude group (`OnMountFinished` stores the horse's own group and nothing restores it; code only).

**The same rule governs enemy riders trampling Geralt** (verified by script): head-on at a canter or full gallop, 50 × speed physical with the rider's attack power and the difficulty's damage multiplier (at speed 4 on "Blood and Broken Bones!" against a level-1 Geralt: 200 physical, 336 Vitality lost); 5.x dealt 15 × speed force capped at a fifteenth of Geralt's maximum Vitality, and from the side too. The owner confirmed this as part of DH2 (a) (2026-11-03).

**Implementation (legacy):** no unit: 1.32's `ShouldDealDamageToActor` (hostile, not on or a horse, `InternalGetSpeed() >= 3`) and `DealDamageToCollidedActor` (the horse's weapon, `attack_speed_based`, head-on or a downed enemy, `DAMAGE_NAME_PHYSICAL` 50 × max(speed, 1), once a second per enemy).

**5.x:** `ShouldDealDamageToActor` also takes animals and calls the damage whenever `distanceBasedSpeed` ≥ 0.1 (or at speed ≥ 3 in slow motion or with an NPC rider); `DealDamageToCollidedActor` skips dead victims, takes side collisions, `DAMAGE_NAME_FORCE` 15 × max(speed, 1) head-on, 5 × from the side, at most the victim's maximum health ÷ 15, and plays a kick sound; `AST_Horizontal` instead of `AST_Jab`.

**Decisions:** legacy's (1.32's) rule restored (DH2 (a), project owner, 2026-11-02). One harmless reordering: the port checks the 1 s per-victim memory before the horse's weapon, so a horse without a weapon records a side brush (nothing in play).

- **Deviation:** 5.x's kick sound plays when Roach tramples a living enemy (as 5.x's guard held it; a dead one still takes 1.32's hit, silently); 1.32 and legacy had none (DH2 (a), owner, 2026-11-02; the living-only part HORSE audit F6, confirmed by the owner, 2026-11-03).
- **Deviation:** 5.x's horse kick and rearing on their key are kept; legacy had none. They deal no damage (verified 2026-11-03: frozen hostile humans 1.5 m ahead and 2.5 m behind Roach took no hit after the key's event) (PH6, owner, 2026-11-02).

**Slices:**

1. **H3, trampling.** Verified 2026-11-03, both trees (the collision rule called as a collision calls it, the speed set by a test wrapper, ridden and riderless; `GMTestHorse03Cases` in `gmtest_panel()`): a hostile head-on not hit at speed 2, hit at 3 and 4 with 50 × speed physical, no force damage; a standing hostile from the side not hit, a knocked-down one hit; a neutral animal not hit.
2. **H4, riders and the kick sound.** Verified 2026-11-03, both trees (scripted; `GMTestHorse04Riders` in `gmtest_panel()`): an enemy rider's horse on Geralt deals 1.32's damage with no horse-weapon part, a riderless one adds her weapon; the kick sound plays for a living enemy, not a dead one (still hit).

**Later:** the trample could read the weapon from the horse's inventory (a vanilla defect; it would add the horse weapon to every ridden trample, unlike legacy).

### Dependencies on other areas

- **Done areas HORSE builds on:** STAM-03 (the horseback costs, `horseStamina.ws`, the mount test `gmtest_stam03_mount`), STAM-08 (NPC stamina), DMG (the formula the bonus goes through), SKL-18 (Adrenaline Burst in both trees, `GMAdrenalineBurstCostCut`'s skill selection), AI-05 (the horse weapon), WGT-06 and WGT-09 (horse gear, the gait), SKL-07 (the trampling adrenaline).

### Save impact

None expected: the functions are read live; HORSE-02's cost is a function, not a state field.

### Area decisions

**Decided** by the project owner (2026-11-02, "take the recommendations"): DH1 (a), DH2 (a), DH3 (a). The porter's calls PH1 to PH9 are confirmed.

| # | Question | Options | Recommendation |
|---|---|---|---|
| DH1 | Several enemies in one horseback swing (HORSE-01). The game reuses one attack for every enemy the swing reaches and never clears its damage, so each enemy's hit carries the previous ones' (vanilla's defect); legacy's speed bonus then multiplies the pile. At a full gallop with a 300-damage sword: legacy's code gives the first bandit 600, the second 1,800 and a third 4,200; the changelist says "up to x2" (1.32 and 5.x: 300 + 255 direct, then 600 + 510) | (a) a fresh attack for each enemy: every enemy gets the weapon damage × up to 2, as the changelist says (a fix, a deviation from legacy's code); (b) legacy's code as it is | **(a)**: the changelist states the intent, and a second enemy taking triple the first's is a defect, not a design; the cost is one line |
| DH2 | Trampling (HORSE-03). Legacy kept 1.32's rule (head-on at a canter or full gallop, hostiles only, 50 × speed physical) and cut the horse weapon to 40 bludgeoning and 20 rending. 5.x reworked it: also from the side and at any speed, animals too, 15 × speed force head-on and 5 × speed from the side, capped at 1/15 of the victim's maximum health. At a full gallop into a 1,500-Vitality bandit: legacy +200, 5.x +60 (from the side +20) | (a) legacy's (1.32's) rule; (b) 5.x's, a recorded deviation | **(a)**: legacy behaviour first, and legacy tuned the horse weapon against 1.32's rule; 5.x's side and low-speed hits make most brushes with an enemy a hit |
| DH3 | Adrenaline Burst pays horse Axii with adrenaline (HORSE-02), in neither legacy's description nor the changelist (SKL's D42 calls it a leftover). Example: at 45 stamina and 1 adrenaline point Geralt can calm Roach with the perk (and hold it about 21 s: 12 on the stamina, 9 on the adrenaline); without it he cannot | (a) port it in both trees (`perk_10`, `perk_42`), the description unchanged (legacy's); (b) port it and add a sentence to the description (9 languages, the project has no translations); (c) leave the payment out (a deviation) | **(a)**: legacy's behaviour and text; (b) goes to Later |

**Porter's calls** (each follows legacy or has no play effect; confirmed by the owner, 2026-11-02):

| # | Call |
|---|---|
| PH1 | HORSE-01: `@replaceMethod` of `DealDamageToHostiles` with 5.x's body (1.32's) and legacy's block; the unused `baseDamage` parameter stays in the signature |
| PH2 | HORSE-02: replaced `OnEnterState` and `StartCastingSign` with legacy's lines, the two resource functions added, 50 as a function; a replaced state `entry` function runs (a wrapper of one never runs, [development.md](../development.md)) |
| PH3 | HORSE-02 in the new tree: `perk_42` (`S_Perk_42`) counts as Adrenaline Burst, as `GMAdrenalineBurstCostCut` does; the conversion is legacy's (max stamina ÷ max adrenaline) in both trees |
| PH4 | HORSE-02: legacy's leftovers are not ported (`staminaSpent`, the commented-out payment to 50); no state fields |
| PH5 | HORSE-02: 5.x's voice line on the cast (`ChillOutHorse`) kept |
| PH6 | 5.x's horse kick and rearing (`HorseKick`) kept: no legacy counterpart, an animation with no damage code (verified: it deals none) |
| PH7 | 5.x's horse handling legacy never touched kept: the gallop's stamina regeneration after 0.45 s (1 s in 1.32), carts, loot from horseback, mount, dismount, camera and lean animations. Recorded as deviations (owner, 2026-11-02) |
| PH8 | WGT-06's horse sprint cost stays as ported: inert in legacy (dead code behind the default "simple stamina management") and in 5.x (no reader), so no change |
| PH9 | HORSE is ported as one area with one audit after its last slice |
