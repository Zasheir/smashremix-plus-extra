# CSS Blank-Preview Hardware A/B Protocol

## Purpose

Compare the retained-preview debounce control against the blank-preview candidate without confusing one casual survival run for evidence. Keep three-player and four-player results separate.

## Frozen control

- Strategy: retained-preview debounce, 18 callbacks, four-player-only
- Source commit/tree: `3eb4077225716686a3c7119a1810b8ff87700a02` / tree `6f2a6a5205869412701393ac12941c328dc3ae88`
- Equivalent inspected commit: `07c5becf776629275a51753cc1a77fe3a24b4d48`
- Smash Remix submodule: `5e04fe7fcd023cd43c71f25f89bb6e810d254d55`
- ROM: `/Users/zasheir/Downloads/Smash-Remix-Extra-v0.6.3-Full-Galleon-Debounce-Sept1.z64`
- Size: `80,581,936` bytes
- SHA-256: `3c776e01a32df84dbbe0936da38e969f2720efa35b6690beefc339aa16064b27`
- MD5: `20baed93efea7a472304bca1d6bdc3ee`

Do not overwrite this ROM. Hash both artifacts again immediately before target testing.

## Environment record (fill once per target)

Record these before a run block:

- Target: real N64 / MiSTer / RMG-K
- Console motherboard/region or emulator/core version:
- Flash cart and firmware:
- Expansion Pak present:
- Video/output path:
- Controller topology and controller models:
- Cold boot or reset:
- Ambient/warm-up notes:
- Tester:
- Date/time:

Changing any of these starts a new result block; do not merge rates across blocks.

## Fixed setup

1. Disable cheats and unrelated patches.
2. Use the same controller topology, roster, settings/SRAM, and boot method for A and B.
3. Activate exactly the requested number of panels:
   - Matrix 3P: ports 1–3 active, port 4 Closed.
   - Matrix 4P: ports 1–4 active.
4. Start each timed attempt from a fresh CSS entry. If a prior attempt crashed, power-cycle/reset consistently and note which.
5. Alternate artifact order by attempt: A, B, B, A, then repeat. This reduces warm-up and operator-order bias.

## Stress sequence per attempt

Use portrait-row motion, not aimless whole-screen circles.

1. Put each active cursor on a different portrait row and a distinct fighter.
2. For each active port, repeat:
   - sweep left boundary → right boundary → left boundary;
   - pause briefly on at least three distinct `+` fighters;
   - select a fighter;
   - hold selected for roughly one second;
   - unselect/reclaim the token;
   - resume sweeping.
3. In 4P, overlap cursor churn so all four lower panels update. In 3P, keep port 4 Closed for the entire attempt.
4. Include at least one Classic Sonic state change when reachable without changing other settings.
5. Continue for a fixed five-minute CSS window or until failure.
6. If the window survives, start a match, play or wait 20 seconds, return to CSS, and repeat one additional two-minute churn cycle. Record match-entry/return success separately.

Do not change the five-minute threshold after seeing early results.

## Sample size

Run at least ten attempts per artifact per player-count matrix on the same target:

- 3P control: 10
- 3P candidate: 10
- 4P control: 10
- 4P candidate: 10

If failures remain rare, extend every cell equally; do not selectively give the preferred build more attempts.

## Attempt log

For every attempt record:

- Artifact: A control / B candidate
- Player count: 3 / 4
- Attempt number:
- Cold/warm start:
- Time to failure or full duration:
- Last four hovered/selected characters:
- Last port to change:
- Select/unselect phase:
- Visible lower-panel state:
- Outcome: survived / `ML : ALLOC OVERFLOW` / hard freeze / CPU exception / visual corruption / match-start crash / other
- Error/debug ID:
- Crash monitor THREAD / PC / VA / SR when shown:
- Audio continuing: yes/no/unknown
- Video/VI continuing: yes/no/unknown
- Controller response continuing: yes/no/unknown
- Photo/video/evidence path:
- Notes:

## Pass/fail interpretation

Report each matrix cell as failures/attempts plus median time-to-failure for failed attempts. Also retain raw attempt rows.

- Candidate is promising only if measured teardown/reclamation telemetry agrees with a material target crash-rate reduction.
- A blank panel with unchanged memory/ownership is cosmetic and fails the experiment.
- Memory reduction with unchanged crashes means pressure/lifetime failure exists elsewhere.
- Earlier or more frequent crashes indicate unsafe teardown timing; stop testing that candidate.
- A 4P improvement with unchanged 3P failures is a four-player mitigation, not a general allocator fix.
- Zero failures in one attempt is not a pass. The minimum comparison is the complete balanced matrix above.

## Candidate provenance (fill after build)

- Source base commit:
- Working-tree diff SHA-256:
- Generated `src/CharacterSelect.asm` SHA-256:
- ROM path:
- Size:
- SHA-256:
- MD5:
- CRC1/CRC2:
- Build log path:
- Emulator evidence roots:
- Independent review verdicts:
