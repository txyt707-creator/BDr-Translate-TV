# BDr Smart Translation — Technical Architecture v1.0

Status: **DESIGN APPROVED, NOT YET IMPLEMENTED**. Target: low-latency English-to-Arabic subtitles for PS5 through an iPhone and a Tizen TV.

## Non-negotiable constraints
- Local-first, no PC required in the final product. Development can use a PC.
- TV displays the console HDMI feed and subtitle UI; successful early TVWindow prototype on one Samsung is **not** proof of compatibility across models.
- Smartphone obtains game frames only through a legally compatible capture path. Sony's official PS Remote Play app does not provide an officially documented video-frame API for third-party apps. An independent client, supported camera capture, or capture hardware requires validation. Do not promise direct PS5 capture as implemented.
- Prefer device-local OCR and translation; cloud AI must be opt-in and budgeted.
- No raw video or PlayStation credentials go to our translation backend.
- Commercial licensing and third-party service terms must be reviewed before launch.

## Modules
1. `GameFrameProvider` (Swift protocol): supplies timestamped CVPixelBuffers from a **validated** source. Implement `SampleVideoProvider` first, then investigate `RemotePlayProvider`; optional `CameraProvider`.
2. `SubtitleRegionDetector`: crop lower subtitle region; configurable per game; dynamic crop later.
3. `OCRWorker`: Apple Vision text recognition with English setting, fast path first, accurate fallback on low confidence; sample only on material image changes.
4. `TextStabilizer`: normalize OCR, debounce partials across 2 consecutive observations, reject hallucinated OCR and duplicate frames; assign monotonic `sequence` and `validUntil`.
5. `TranslationMemory`: normalized English+context hash to cached approved Arabic; configurable glossary for characters, places, idioms.
6. `LocalTranslation`: Apple Translation Framework if en→ar is supported/downloaded; otherwise a compatible licensed on-device model or user-selected fallback. Never assume supported languages.
7. `SmartRouter`: dispatch locally immediately; optional cloud improvement if confidence/quality heuristic indicates slang, idioms, or a complex sentence; do not make cloud requests on every frame.
8. `GeminiEnhancer`: one fast model, strict 1-line JSON format, ~400-700ms timeout initially tunable by measurements; drop late responses.
9. `PremiumReview`: GPT/Claude only for optional advanced mode or offline glossary curation, never on critical path; requires explicitly budgeted API.
10. `PairingAndTransport`: TV generates rotating 6-digit PIN; phone pairs on LAN with authenticated handshake and binds to a device-specific shared key/token. A six-digit PIN **alone** is insufficient security. WebSocket preferred on compatible TVs; include heartbeat/reconnect and TLS/auth for production. Do not use wildcard CORS/insecure HTTP in commercial deployment.
11. `TVRenderer`: platform adapter (Tizen first; LG webOS, Android TV later), HDMI in-app source where available, RTL subtitles, safe margin, font size, stale subtitle clearing.
12. `Metrics`: frameAge, OCRms, localTranslationMs, cloudMs, transportMs, renderMs, glass-to-glass end-to-end latency. Never log user dialogues to analytics without clear consent.

## Example transport messages (illustrative only)
```json
{"type":"pair_request","protocol":1,"pin":"123456","device":"iphone","client_nonce":"random"}
{"type":"pair_approved","session_id":"opaque-session","token":"short-lived-bound-secret"}
{"type":"subtitle","sequence":81,"source":"ocr","language":"ar","text":"لازم نهرب من الشرطة!","is_revision":false,"valid_until_ms":1730000000000}
{"type":"clear","sequence":82}
```
Actual authentication must use cryptographically generated secrets, rate-limited PIN attempts, and a pairing confirmation on the TV. No secrets committed to GitHub.

## Translation decision policy
- If OCR text unchanged, skip all translation and refresh subtitle TTL only.
- Cache hit → send cached Arabic immediately.
- Cache miss → send local Arabic immediately (if available) and cache.
- If idiom/slang/error heuristic triggers and user enabled online enhancement → call one cloud fast model **in parallel**.
- Display revision only while `sequence` still matches the live subtitle; never replace the next line with a delayed response from a previous line.
- GPT/Claude not queried automatically per sentence; do not assume free APIs for a commercial product.
- Quality strategy: explicit game glossary + previous 1–2 lines as context, avoid translating character names literally, preserve subtitle length and tone.

## Latency budgets (aspirational; exclude PS5 streaming time)
OCR 40–100ms, local translate 30–150ms, LAN delivery/display 10–40ms. Not guaranteed; measure on the target iPhone/TV and include frame capture lag. P50/P95 and dropped/revised subtitle rate are release gates. Aim for minimal perceived lag rather than promising sub-second on every line.

## Implementation milestones
- M0 (existing): Samsung Tizen experimental HDMI + static Arabic overlay validated on one model.
- M1: replace PC-hosted relay with a phone-owned local session; TV connects by 6-digit code, authenticated messaging; manual Arabic text updates on TV.
- M2: SampleVideoProvider → Vision OCR → TextStabilizer → local translation and memory; benchmark on GTA-like clips.
- M3: add opt-in Gemini fast enhancement behind protected backend with quotas, cache and hard latency timeout.
- M4: implement and legally/technically validate an actual PS5 frame source; this is a **critical unknown**.
- M5: stabilize iOS signing, distribution and TV packaging; evaluate support for Samsung versions and then other manufacturers.
- M6: security review, privacy policy, translations QA, cost modelling, billing and store guidelines before commercialization.

## First implementation boundary
Do not modify an already-working TV overlay to implement AI or Remote Play. First develop/prove pairing and real-time text display on a separate version with an explicit rollback to the current working TV version.

## References
- Apple Vision text recognition: https://developer.apple.com/documentation/vision/recognizing-text-in-images
- Apple Translation framework: https://developer.apple.com/documentation/translation
- Samsung Tizen TV network privileges: https://developer.samsung.com/smarttv/develop/faq/networking-and-connectivity.html
- Sony Remote Play mobile support: https://www.playstation.com/en-us/support/games/playstation-remote-play-on-mobile-devices/
- Gemini API pricing/free tier: https://ai.google.dev/gemini-api/docs/pricing
