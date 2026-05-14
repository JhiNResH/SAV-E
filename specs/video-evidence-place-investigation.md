# Video Evidence Place Investigation

> Last updated: 2026-05-13

## Goal

Let SAV-E help users investigate places from videos, screenshots, and pasted social links when public metadata is not enough, while keeping the result as evidence-backed candidates instead of automatically saved places.

## Product Contract

- This is not normal metadata import.
- SAV-E may use user-provided media evidence such as:
  - shared video files
  - screenshots
  - pasted captions
  - pasted public links
- SAV-E should extract visible clues such as:
  - storefronts
  - menus
  - packaging
  - subtitles or overlay text
  - dishes and signature items
  - city/language cues
- SAV-E should cross-check candidates against external/official sources before recommending a save.
- Results must stay in review until the user chooses a candidate.

## Out of Scope

- No automatic platform video download in this patch.
- No login, cookies, private scraping, or bypassing platform restrictions.
- No automatic save to Saved Places.
- No claiming the app watched or transcribed a platform video unless the user provided the actual media file or screenshot.

## Agent Prompt Contract

The Add Spots entry should route users into this prompt shape:

```text
Investigate this video or screenshot and return candidate places with evidence.

Use only evidence from the shared media, pasted caption/link, and reliable cross-checks.
Return:
- likely place candidates
- evidence for each candidate
- confidence
- what is missing
- whether it is safe to save

Do not save anything automatically.
```

## UI

- Rename `Screenshots` in Add Spots to `Media Evidence`.
- Use copy that covers video, screenshots, and pasted links.
- The entry should populate the agent prompt rather than showing a decorative placeholder.
- The UI should make the review/candidate nature explicit.

## Acceptance Criteria

- Add Spots shows `Media Evidence`, not `Screenshots`.
- Tapping `Media Evidence` fills an investigation prompt into the agent input.
- The prompt says candidate places with evidence, confidence, missing evidence, and no automatic save.
- The app still compiles with `xcodebuild`.
