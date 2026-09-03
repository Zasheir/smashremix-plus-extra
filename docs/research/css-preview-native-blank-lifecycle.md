# Native CSS Preview Blank / Teardown Lifecycle

## Scope and source identity

- Working source: `3eb4077225716686a3c7119a1810b8ff87700a02`
- Source-equivalent inspected commit: `07c5becf776629275a51753cc1a77fe3a24b4d48`
- Smash Remix submodule: `5e04fe7fcd023cd43c71f25f89bb6e810d254d55`
- Control ROM: `/Users/zasheir/Downloads/Smash-Remix-Extra-v0.6.3-Full-Galleon-Debounce-Sept1.z64`
- Control SHA-256: `3c776e01a32df84dbbe0936da38e969f2720efa35b6690beefc339aa16064b27`
- Reference decomp used to name stock routines: VetriTheRetri/ssb-decomp-re, temporary checkout `/tmp/ssb-decomp-re-css-trace`

## Verdict

There is no stock Closed ↔ MAN/CPU transition that both blanks a VS panel and frees its loaded fighter model files.

- Closed is hide-only.
- Replacing a fighter destroys the old fighter instance but retains loaded model-file memory and dynamic-slot ownership.
- `CharacterSelect.reset_heap_slot_` is the operation that actually rewinds a dynamic model heap, clears owner/additional IDs, and clears the corresponding character main-file pointers.

Therefore a useful blank-preview experiment must combine the stock fighter teardown with a delayed, ownership-checked `reset_heap_slot_`. Calling the stock update routine with a Closed/NULL state, or only setting visibility flags, is cosmetic.

## VS panel structure fields

The stock `MNPlayersSlotVS` is `0xBC` bytes. Relevant fields from the decomp (`src/mn/mntypes.h:133-182`) are:

- `+0x08`: fighter/player GObj (`player`)
- `+0x10`: combined character name + series emblem GObj (`name_emblem_gobj`)
- `+0x14`: panel doors GObj
- `+0x18`: base panel GObj
- `+0x34`: persistent per-port figatree workspace
- `+0x48`: fighter kind / character ID
- `+0x4C`: costume
- `+0x50`: shade
- `+0x58`: selected flag
- `+0x84`: player kind (`MAN=0`, `CPU=1`, `Closed/Not=2`)

The figatree workspaces are allocated once per port during CSS setup and are not part of per-hover model reclamation (`mnplayersvs.c:4757-4766`).

## Stock blank behavior is hide-only

`mnPlayersVSUpdateFighter` at `0x80136128` (`mnplayersvs.c:2336-2368`) does this when a fighter object exists:

- Closed player kind: sets fighter GObj hidden and returns.
- NULL fighter kind while not selected: sets fighter GObj hidden and returns.
- Otherwise: computes shade/costume and calls `mnPlayersVSMakeFighter`.

It does not destroy the fighter and does not clear the dynamic heap slot.

`mnPlayersVSUpdateNameAndEmblem` at `0x80136300` (`mnplayersvs.c:2396-2413`) similarly hides the name/emblem GObj for Closed or an unselected NULL fighter. It does not free the object or model files.

This is the visual state seen when a panel is newly enabled, but it is not memory reclamation.

## Fighter replacement lifecycle

`mnPlayersVSMakeFighter` at `0x80134A8C` (`mnplayersvs.c:1623-1663`) performs:

1. If old fighter GObj is non-null, preserve rotation and call `ftManagerDestroyFighter(0x800D78E8)`.
2. Build `FTDesc` using the already loaded fighter files and persistent per-port figatree heap.
3. Call `ftManagerMakeFighter`.
4. Publish the new fighter GObj to panel `+0x08`.
5. Attach its CSS update process and set transform/scale.

`ftManagerDestroyFighter` (`ftmanager.c:371-396`) stops attached effects, ejects accessory GObjs, returns fighter-part and fighter-struct entries to their pools, and ejects the fighter GObj. This is genuine fighter-instance teardown, but it does not rewind the dynamic character model heap and does not clear character file pointers or heap-slot ownership.

The current generator’s commit hook at stock `0x80134BA4` correctly observes the new fighter only after panel `+0x08` has been published.

## The operation that reclaims dynamic model memory

`CharacterSelect.reset_heap_slot_`:

- Upstream source: `smashremix/src/CharacterSelect.asm:4344-4408`
- Generated source after regeneration: locate symbol in `src/CharacterSelect.asm`

Given a slot index, it:

1. Resolves `heap_slot_0 + slot * 0x10`.
2. Reads the associated heap struct.
3. Rewinds heap `current` (`+0x0C`) to heap `floor` (`+0x04`).
4. Clears the slot’s primary character ID to `Character.id.NONE`.
5. Clears the primary character’s main-file pointer.
6. Clears up to four additional/shared character IDs and their main-file pointers.
7. Preserves Tag Team preloaded pointers that are outside the reclaimed heap’s floor/ceiling range.

This is the only traced operation that makes the dynamic slot free and recycles its model-file bytes.

## Existing render-lifetime protection

Dynamic model loads publish the selected slot into `curr_slot_used_by_port[port]` (`smashremix/src/CharacterSelect.asm:2202-2215`). The render callback `sync_slot_used_by_port` copies all four current bytes into the four previous bytes once per frame (`:4462-4469`). Eviction scans both generations before resetting a slot (`:4294-4326`).

That previous/current pair is explicitly documented in source as protection against a console crash. Reclaiming a slot in the same callback that blanks its visible fighter would bypass the established render-lifetime grace interval.

## Safe equivalent blank/reclaim sequence

The candidate should use this ordering for the first `VISIBLE → BLANK_WAIT` transition:

1. Validate port before every per-port array access.
2. Record exact pending character + Classic flag and set timer 18.
3. Capture the port’s current dynamic slot as a retirement candidate; `-1` means permanent/preloaded and needs no slot reset.
4. Record the expected slot owner ID so later reclamation can reject stale/reused metadata.
5. Call `ftManagerDestroyFighter(0x800D78E8)` on panel `+0x08` when non-null.
6. Clear panel `+0x08` only after the destructor returns.
7. Set panel `+0x48` to `Character.id.NONE` and hide the GObj at panel `+0x10`; this blanks fighter, name, and series emblem/background while preserving the panel shell.
8. Set `curr_slot_used_by_port[port] = -1` so the normal frame-sync boundary can retire that reference.
9. Clear committed-preview validity only after fighter teardown completes.
10. Publish `BLANK_WAIT` last.

On a later render callback—never in the initial blank call:

1. Let the existing previous/current synchronization interval elapse.
2. Check the retirement slot is `< ACTIVE_HEAP_COUNT`.
3. Check none of the eight previous/current per-port protection bytes equals that slot.
4. Check the slot still owns the captured primary/additional character ID.
5. Only then call `reset_heap_slot_(slot)` and clear the retirement record.
6. If another port still shares/protects the slot, leave the record pending and do not reclaim it.

This reuses the stock fighter destructor and the project’s authoritative heap recycler while honoring the project’s own render-reference lifetime convention.

## Reconstruction after debounce

When the latest request ages to ready and preflight accepts it:

1. Publish `CONSTRUCTING` and the one-shot release token.
2. Restore the exact pending character and Classic flag.
3. Call stock `mnPlayersVSUpdateFighter(0x80136128)`.
4. The nested gate must accept only the exact pending ID/Classic pair.
5. After fighter construction, call `mnPlayersVSUpdateNameAndEmblem(0x80136300)` so the GObj hidden during blanking is shown and rebuilt.
6. Publish committed ID/variant/Classic and `VISIBLE` only from the existing post-object-publication commit hook.

If preflight is busy, remain blank and retain the exact request. Leaving four-player mode may remove the artificial delay but must not bypass preflight.

## Tag Team and mode notes

- `reset_heap_slot_` already contains the Tag Team exception that keeps main-file pointers outside the target custom heap.
- The blank/debounce behavior remains VS/four-active-panels only. One-, two-, and three-player direct hover construction must keep the stock flow.
- A retirement slot can be shared by another character through `additional_char_ids`; owner validation must test the primary and all four additional IDs.
- A preloaded/permanent fighter legitimately maps to slot `-1`; blanking still destroys its fighter GObj, but there is no dynamic model heap to reclaim.

## Instrumentation required for falsification

Per port expose:

- lifecycle state;
- pending ID/Classic/timer;
- retirement slot and expected owner;
- blank entered;
- fighter teardown attempted/completed;
- duplicate teardown suppressed;
- retirement busy/shared retries;
- heap reset/reclamation completed;
- ready-but-preflight-busy retries;
- construction admitted and committed.

Also observe heap floor/current/ceiling and primary/additional owner IDs. A successful experiment must show the retired dynamic heap current pointer return to floor and owner metadata clear before the next construction. Fighter pointer `NULL` by itself is insufficient.

## Abort conditions

Abort the candidate if any of these occur:

- the fighter pointer is cleared without calling the real fighter destructor;
- a dynamic heap is reset in the initial blank callback;
- a slot is reset while present in any previous/current protection byte;
- owner metadata changed before reset and the code still resets it;
- another visible port shares the slot;
- panel blanking does not hide the name/emblem GObj;
- a constructed fighter remains with name/emblem hidden;
- telemetry shows no heap rewind/owner clear for an unshared dynamic slot;
- compiled MIPS violates stack/register or branch-delay-slot assumptions.
