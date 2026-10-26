#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="$(mktemp -d)/fatfish-core-checks"
swiftc -parse-as-library -o "$OUT" \
  FatFishCall/Models/AppConfig.swift \
  FatFishCall/Models/ChatMessage.swift \
  FatFishCall/Models/TokenBudget.swift \
  FatFishCall/Models/SentenceChunker.swift \
  Scripts/CoreChecks.swift
"$OUT"
