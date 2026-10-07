# 173b7 - Sound

*Continues in the W client (`/mnt/mtwo/games/azeroth-core/custom-client/`), since the move on 2026-10-07 (173v): issue 1001. This issue stays as the record of how the client began; its paths are as they were then.*

## Status
- Created: 2026-10-06
- Phase: 1
- Parent: 173b (the options menu)
- Blocked by: 173b1 (the settings store), the first sound the client plays
  (not yet an issue)
- Priority: Low

## Origin

See 173b (the owner's words, 2026-10-06).

## Current Behavior

Not built. The client plays no sound.

## Intended Behavior

The original's Sound panel (reference page, *Sound & Voice* → *Sound*),
built when the client plays its first sound:

- **Volumes**, 0 to 1: Master (`Sound_MasterVolume`), Sound effects
  (`Sound_SFXVolume`), Music (`Sound_MusicVolume`), Ambience
  (`Sound_AmbienceVolume`).
- **What plays**, on/off: all sound (`Sound_EnableAllSound`), sound
  effects, music, ambience, error speech, emote sounds, pet sounds,
  sound while the window is in the background, Loop Music
  (`Sound_ZoneMusicNoDelay`).
- **Where you hear from:** Sound at Character
  (`Sound_ListenerAtCharacter`), the listener at her rather than at the
  camera.
- **Output:** device (`Sound_OutputDriverIndex`), channels (32 or 64),
  quality (0 to 2), reverb, headphone mode (`Sound_EnableSoftwareHRTF`),
  the Death Knight voice effect (`Sound_EnableDSPEffects`). The original's
  *Use Hardware* is not copied, because it is a Windows-era audio path.

**The Voice panel** (voice chat) is not copied: AzerothCore runs no voice
server, and the original's voice chat needs one.

## Suggested Implementation Steps

1. Volumes and the on/off switches with the first sound.
2. Device choice and listener position with positional sound.

## Open Questions

None yet.
