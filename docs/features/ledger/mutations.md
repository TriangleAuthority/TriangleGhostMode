# Ledger: mutations

What each mutation scales, which build it serves and what it costs, in legacy Ghost Mode and in 5.x. **Unverified:** from the data and the code, not tested in game. The details and the implementation are in [mut.md](../mut.md), and the texts at base stats in the [tree files](../../skill-trees/).

**When they arrive.** Mutations come with Blood and Wine: late game, and only after the player has the greater mutagens. The research tree, the mutagen costs and the 2/4/8/12 thresholds for the extra skill slots are the same in 1.32, Ghost Mode and 5.x. Ghost Mode cut the skill-point cost of researching all twelve from 53 to 29 (not in the changelist; DM1).

| Mutation | Tier | SP: Ghost Mode / 5.x | Ghost Mode: what it scales | Build | 5.x vanilla |
|---|---|---|---|---|---|
| Magic Sensibilities (M2) | 1 | 1 / 2 | Sign crit chance and crit power from sign intensity (5%/25% at 0%, 35%/166% at 100%, 85%/400% at 500%) | Signs (cornerstone) | Vanilla's 30% chance and 100% crit power per 100% intensity; explodes on a supercharged Sign too |
| Deadly Counter (M8) | 1 | 1 / 2 | Countered enemies at 15% health or less die with a finisher; +33.3% melee damage per adrenaline point against countered enemies | Sword, counters | Vanilla: +25% sword damage against monsters, finisher on humans below 25% |
| Toxic Blood (M4) | 1 | 1 / 2 | Attackers take acid of 1.5 × current toxicity per second for 5 s and lose 10% stamina regen; toxicity decays 50% slower | Alchemy, defence | Vanilla's acid, doubled |
| Piercing Cold (M6) | 2 | 2 / 3 | Aard freezes at 30% × (1 − frost resistance); frozen and knocked down means an instant kill; otherwise 250 force damage scaled by intensity | Signs, control | Freeze chance = adrenaline × 10%; three Wild Hunt bosses cannot be killed this way |
| Bloodbath (M3) | 2 | 2 / 3 | Attack power from equipped skills at combat start (+10% per sword skill, +5% per other), lost with Vitality, restored and raised by kills; max 250% | Sword (cornerstone) | Vanilla: +5% per hit, lost on any damage |
| Euphoria (M10) | 2 | 2 / 3 | While overdosed in combat, the overdose drain (raised by toxicity) is added to sword and Sign base damage | Alchemy (cornerstone) | Vanilla: +0.75% sword damage and intensity per toxicity point |
| Conductors of Magic (M1) | 3 | 3 / 5 | Signs gain 30% of the drawn sword's base damage | Signs | Vanilla 50% of the sword's damage attribute |
| Adrenaline Rush (M7) | 3 | 3 / 5 | 30 s cycles: adrenaline gain ×2 and +50% attack power and intensity per point, then gain ÷2 and −50% per point gained | Sword and Signs on adrenaline | Vanilla: +30% per extra enemy at combat start, then a penalty |
| Cat Eyes (M9) | 3 | 3 / 5 | Bolt base damage ×2; slow motion while aiming with toxicity above 0 | Crossbow | Vanilla: +150 bolt damage, +50% crossbow crit chance |
| Mutated Skin (M5) | 3 | 3 / 5 | Incoming damage spread over 5 s per adrenaline point, while adrenaline drains | Defence, adrenaline | Vanilla: −15% damage per adrenaline point |
| Life Leech (M11) | 4 | 4 / 7 | With the Mutation Catalyst potion: drain up to 3 enemies for 6 s (weapon damage, attack power, intensity × adrenaline), immortal and free Quen meanwhile; 90 s cooldown | Hybrid, late sustain | Second Life: death save, 120 s |
| Metamorphosis (M12) | 4 | 4 / 7 | Up to 3 decoctions without toxicity; each raises the chance of critical effects by 10% | Alchemy, decoctions | Vanilla: critical effects start random decoctions, up to 5 |

Hard stats (B2) in the mutations: adrenaline gain (Adrenaline Rush ×2/÷2), adrenaline spent or used as a multiplier (Deadly Counter, Mutated Skin, Life Leech, Adrenaline Rush), toxicity (Toxic Blood's slower decay, Metamorphosis's free decoctions, Euphoria and Cat Eyes needing toxicity), stamina (Toxic Blood cuts enemies' regen).
