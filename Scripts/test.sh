#!/bin/zsh
set -eu
cd "${0:A:h:h}"
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
work=$(mktemp -d /tmp/materials-tests.XXXXXX)
trap 'rm -rf "$work"' EXIT
sources=(MaterialsIntelligence/Intelligence/KnowledgeGraph.swift MaterialsIntelligence/Domain/Knowledge.swift MaterialsIntelligence/Research/ResearchPackage.swift MaterialsIntelligence/Database/KnowledgeStore.swift)
xcrun swiftc "${sources[@]}" MaterialsIntelligenceTests/KnowledgeStoreTests.swift -o "$work/store" -lsqlite3
"$work/store"
for suite in LocalRAGTests ResearchIngestionTests KnowledgeGraphTests DegradationAssessmentTests; do
  xcrun swiftc "${sources[@]}" MaterialsIntelligence/AI/LocalRAG.swift MaterialsIntelligence/Intelligence/DegradationAssessment.swift "MaterialsIntelligenceTests/$suite.swift" -o "$work/$suite" -lsqlite3
  "$work/$suite"
done
