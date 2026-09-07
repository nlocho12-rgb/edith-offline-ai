#!/usr/bin/env bash
# Clones llama.cpp and immediately trims it to only what's needed for a
# CPU-only Android build, before it ever gets committed. Run this once
# from the repo root when setting up the project (or to update llama.cpp
# later).
set -euo pipefail

DEST="android/app/src/main/cpp/llama.cpp"

rm -rf "$DEST"
git clone --depth 1 https://github.com/ggml-org/llama.cpp.git "$DEST"

cd "$DEST"
rm -rf .git

# Remove everything not needed for a CPU-only Android library build.
rm -rf models docs tools benches common conversion gguf-py scripts media grammars requirements skills ci pocs app
rm -rf .github .devops .gemini .pi
rm -f AGENTS.md CLAUDE.md CONTRIBUTING.md AUTHORS CODEOWNERS SECURITY.md CMakePresets.json Makefile flake.nix
rm -f mypy.ini pyrightconfig.json pyproject.toml ty.toml build-xcframework.sh requirements.txt
rm -f .clang-format .clang-tidy .editorconfig .flake8 .ecrc .pre-commit-config.yaml .dockerignore .gitmodules
rm -f convert_hf_to_gguf.py convert_hf_to_gguf_update.py convert_llama_ggml_to_gguf.py convert_lora_to_gguf.py

cd ggml/src
rm -rf ggml-cuda ggml-vulkan ggml-sycl ggml-hexagon ggml-metal ggml-et ggml-webgpu ggml-openvino ggml-cann ggml-virtgpu ggml-rpc ggml-zdnn ggml-zendnn ggml-blas ggml-musa ggml-hip ggml-opencl

echo "Done. Vendored llama.cpp size:"
du -sh "$(dirname "$0")/../$DEST" 2>/dev/null || du -sh "../../$DEST"
