# Next session: trade, magic, quests, stats and skills

Written at the end of the 0.3.3.1 session (2026-11-06, ~04:00). Facts below were checked in the code and
in the running game, not guessed.

What the mod does today, relevant here: **quest states** are synchronised (StartQuest/SucceedQuest/
MakeQuestAvailable through the game's own calls), the **journal/glossary** is synchronised, **NPC health,
defeat and death** are synchronised, **inventories of chests and dropped items** are synchronised, the
**clock** is synchronised, and the **other player's avatar** is a puppet driven by pose/equipment.
There is **no** trade, **no** magic, **no** hero-attribute or skill sync of any kind (grep: 0 mentions).

---

## 1. Trade — medium difficulty, clear data model

**How the game does it.** Trading with an NPC changes three things: the NPC's `DataModule_Container`
(what they sell/buy), the trading hero's inventory, and the hero's money. The mod already knows how to
read and write a `DataModule_Container` (that is exactly what the chest sync does) and how to add items
with `Server_AddNewItem` / `Multicast_AddNewItem`.

**What is needed**

1. lock the NPC while one player trades (`InteractiveComponent::SetIsBeingUsed`, the same trick the chest
   lock uses) so both never trade the same NPC at once;
2. after a trade ends, mirror the **NPC's** container on the other copy (it is shared world state);
3. money: find where the hero's ore is stored (an inventory entry, type and definition) and mirror the
   *other* player's money only for display - each hero keeps their own purse;
4. make sure no item is duplicated: the safe pattern is "the sender says what changed, the receiver
   re-reads its own container and adjusts", never "add N items blindly".

**First experiment tomorrow:** trade one item with a merchant on the host, dump the NPC's container on
both copies before and after (`probe` + the chest tooling), and see what actually moves. That tells us
whether a delta or a full mirror is cheaper.

**Risks:** duplication (worst case), and the trade UI being a modal that fights the "in use" lock.

---

## 2. Magic — hard for the visuals, medium for the effect

**Key insight:** the *outcome* of magic on NPCs may already reach the other copy, because NPC health,
defeat and death are synchronised. What is missing is (a) the visual effect on the other copy and
(b) damage to the **other player's hero** (a hero is not an NPC we sync).

**What is feasible**

* sync the **cast** (who cast what at whom) and let the other copy apply the same **damage/effect** to
  its own copy of the target; the numbers would match even if the fireball is invisible;
* hero-to-hero damage: apply the same health delta to the other hero - but heroes are per-copy, so the
  clean way is "the caster's copy tells the victim's copy: you took N damage from spell X".

**What is not realistically feasible**

* replaying the spell's own ability on the other copy (abilities are script-bound, the same wall as the
  dialogue and the voice), so **visual effects of the other player's spells will probably stay missing**
  unless we find a native entry point.

**First experiment tomorrow:** cast a spell at an NPC on the host and watch the guest's NPC health and
death - if they already follow, half the work is done and we only need to hide the missing VFX.
Check the decompiled sources for the damage path (`gore\src\GAS\Calculations\Damage.as` exists).

---

## 3. Quests — VERIFIED (2026-11-06)

Checked in play on the same second: the host started `Instance_Quest_OldCamp_OCCHAPTER1_JOINOC` and the guest
logged, in order,

* `S quest Instance_Quest_OldCamp_OCCHAPTER1_JOINOC -> state 2 (from the other copy)` - the quest itself,
* `S quest ..._JOINOC_OBJ_HOWTOACCESS -> state 2 (from the other copy)` - its **objective**, which was an open
  question,
* `S journal: 'DocumentSegment_CH1_JOINOC_VisitThorus' unlocked here (from the other player, ok)` - the journal
  entry that comes with the quest.

The code is symmetric: quests are sent from either copy, and the only role-specific rule is "the host wins a
conflict" (`if (S.pend[idx] && S.role == 1) continue;`). **Both directions are now seen in play**: after the
host started the quest at 18:29:16, the same thing done on the guest reached the host at 18:32:11 with
`S quest ... -> state 2 (from the other copy)` for the quest and its objective.

Remaining, low priority: quest markers on the map and the "new quest" banner.



* **objectives/sub-steps** (a quest can have several objectives; do they follow the state or need their
  own sync?);
* **quest markers** on the map and the "new quest" banner;
* whether a quest that the guest starts reaches the host (the current sync is symmetric in principle -
  verify, because the earlier work only tested host -> guest).

**First experiment tomorrow:** take a quest on the guest and check the host's quest log and map.

---

## 4. Stats and skills — VERIFIED, the separation already works (2026-11-06)

The reader (`stats_poll`, level / experience / skill points / health / strength / dexterity) is in the story
module, and two runs answered the question:

* the host spent three skill points at a trainer: `skill points 100 -> 98 -> 97`, `strength 10 -> 12 -> 13`;
  **the guest's numbers did not move at all**;
* then the guest learned the same thing from the same trainer and was **not blocked**:
  `skill points 100 -> 99 -> 96 -> 93`, `strength 10 -> 11 -> 14 -> 17`.

So each hero has his own progress, and the trainer has no per-save "already taught" state that our
synchronisation would trip over. Nothing to change here; the reader stays as the way to check it.

### The second kind of skill: `GE_Skill_*` effects (also separate, verified)

Attributes are only half of it. Real skills - one-handed, two-handed, bow, lockpicking, pickpocket, alchemy,
the mage circles, orcish - are **GameplayEffect classes** (`UGE_Skill_*`), applied to the hero's ability system
component by `LearnSkill` (`GAS/GASCharacterStateMixins.as:1008`): the effect goes on the component, the skill
points and the ore are paid in the same call, and `HasLearnedSkill` is just "the component has this effect".

These are not attributes, so the stats reader in the log does not see them. The separation was checked the
honest way instead, through the trainer:

* the guest learned **pickpocket**; on the host the same skill could still be learned again;
* the host learned **lockpicking**; on the guest the same skill could still be learned again.

So both skill systems are per-copy: each hero has his own effects, and no "already learned" state crosses
over. Reading the learned effects into the log would need the component's `ActiveGameplayEffects` internals -
not worth it while the behaviour is already correct.

### The original plan section (kept for the reasoning)

**The important question:** in this co-op each copy runs its **own world with its own hero**. So skills
and attributes are *already* separate by construction: if the host learns Sword 2, nothing in the guest's
copy changes. That is what "each player has their own learned skills" means, and it is already true.

So the work here is not "split" but "make sure nothing breaks the separation and show what matters":

1. **verify** that learning a skill on one copy does not touch the other (it should not - we never sync
   attributes). A cheap test: learn a skill on the host, then read the guest hero's skill entry - it must
   be unchanged;
2. **the trainer's own state** is the real risk: if the game records "this trainer already taught X" in a
   place we *do* sync (quest state, journal/document, NPC state), the second player may be blocked from
   learning the same thing. That is the bug to look for;
3. **display**: optionally sync the other player's level, health and mana so a nameplate or the co-op HUD
   can show them. That is a small, safe addition on top of the existing npc module record (it already
   carries `hp` as uint16).

**First experiment tomorrow:** on the host learn one skill from a trainer; on the guest, dump the hero's
attribute/skill block before and after, and try to learn the same skill from the same trainer.

---

## Suggested order

1. **Quests** (verification, cheap, no code if it already works).
2. **Trade** (real work, clear data model, high value for a co-op).
3. **Stats/skills** (mostly verification plus the trainer question).
4. **Magic** (the expensive one; decide after the NPC-damage experiment whether the missing visuals are
   acceptable).

## Things to do before any of this

* both copies should run **0.3.3.1** (the core is unchanged since 0.3.3, so only `story.dll` differs);
* remember that the game clock runs ~3 in-game minutes per 10 real seconds - any timer-based logic must
  use real time, not the game clock;
* `probe nativefn` lies (see `docs/BUGS.md`); use `observe_fn`'s slot number or an actual call.
