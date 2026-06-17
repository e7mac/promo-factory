# promo-factory

Public repo with macOS-runner GitHub Actions workflows that build a fleet app for the
simulator, run the unattended promo-capture pipeline (in-engine audio tap + clapperboard
+ `shoot.sh`/`frameclip.sh`), and upload a framed promo clip as a downloadable artifact.

Public → free macOS runner minutes. Private app code is cloned at runtime via the
`FLEET_PAT` secret (Contents:Read) into the ephemeral runner — never committed here.

Vendored harness lives in `scripts/` (mirror of the `ios-promo-video` skill).
MIDI Memos audio is rig-free (MusicCore in-engine `PromoTap`) — no BlackHole/sox.
