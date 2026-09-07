# Edith — Offline On-Device AI Assistant

## Status: Phase 1 (text chat only, no voice yet)

## Setup

1. Vendor a trimmed, CPU-only copy of llama.cpp (not committed as full upstream):
   ```bash
   bash tools/vendor_llama.sh
   ```

2. Download a small quantized GGUF model (e.g. Llama-3.2-1B-Instruct-Q4_K_M
   or Qwen2.5-1.5B-Instruct-Q4_K_M) and place it wherever `_modelPath` in
   `lib/main.dart` points, or update that path.

3. Build:
   ```bash
   flutter pub get
   flutter build apk --release
   ```

## Roadmap

- [x] Phase 1: Flutter shell + llama.cpp text chat
- [ ] Phase 2: sherpa-onnx ASR (mic -> text)
- [ ] Phase 3: sherpa-onnx TTS (text -> speech), Piper voice
- [ ] Phase 4: wire voice in/out into the chat UI end-to-end
