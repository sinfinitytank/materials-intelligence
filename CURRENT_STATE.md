# Current State

## Scope

Phases 0 through 6 are implemented in one native SwiftUI macOS 26+ target. The app uses system SQLite/FTS5, AppKit file panels, security-scoped bookmarks, and Apple Foundation Models when available. It has no web runtime, third-party dependency, cloud fallback, network research service, embeddings store, autonomous ingestion, graph explorer, sync, or Phase 7 functionality.

The local database is `Application Support/MaterialsIntelligence/knowledge.sqlite`. Current schema version is 4: records/claims/relationships, claim lifecycle, Library/FTS, and research-session snapshots. Foreign keys are enabled on open. Version 1 and direct version 3 upgrades are regression-tested, preserve stable IDs and existing knowledge, and complete without foreign-key violations.

## Implemented product

- Native sidebar and pages for Overview, Ask, Search, Research, Library, Materials, Damage Mechanisms, Standards, Components, Sources, Claims, Relationships, and Settings.
- Stable record, claim, relationship, and document identities with source linkage, six claim states, guarded deletion, and restart persistence.
- Offline FTS5 over records, active claims, relationships, and document metadata; transactional rebuilds keep writes and indexes consistent.
- Referenced local documents with persisted security-scoped bookmarks, associations, relinking, and missing-file preservation.
- Local RAG over the existing FTS path. Only Reviewed or Verified claims enter model context; citations must resolve to retrieved claim IDs. Unverified imported claims appear as evidence gaps until reviewed.
- Phase 6 JSON schema v1, strict validation, persisted staging, deterministic duplicate/conflict suggestions, accept/reject/edit/reuse/cancel/commit actions, atomic permanent writes, provenance, original/final package audit, result mappings, history, and native review UI.

## Post-Phase-6 verification — 2026-09-27

`Scripts/test.sh` passes KnowledgeStore, LocalRAG, and ResearchIngestion suites. Coverage includes CRUD/integrity, schema 1 and schema 3 migrations, FTS update/delete/archive behavior, document association rollback, bookmark persistence, RAG evidence gating/citation validation/context bounds, malformed and invalid packages, invalid edit preservation, duplicate/conflict matching, partial approval, dependency failures, forced late rollback including FTS, cancellation, retry, stale sessions, provenance, audit reopen, imported search retrieval, and RAG use after explicit review.

A clean Release arm64 `xcodebuild clean build` from a fresh derived-data directory passes with Xcode 27.0 / Swift 6.4. The built executable remained alive during a five-second launch check with no application initialization failure. The audit restored working add/edit/delete controls on the specialized Materials screen and removed duplicate source rows from the Research Entities section.

## Verification boundary and known limits

Automated tests and process launch do not establish visual correctness or complete human interaction. Still manual: visit every screen; resize; check light/dark mode, keyboard use and VoiceOver; exercise the macOS import/export/file panels; complete import → review → edit/reuse/reject → commit/cancel → Search → Claims review → Ask; and verify a real on-device generated answer. The current Mac previously reported the Apple model as `modelNotReady`, so deterministic provider tests—not a real model response—verify RAG integration.

Search remains lexical OR-prefix FTS over structured text and document metadata, not document contents or semantic embeddings. Matching is deliberately conservative and deterministic; it does not infer numeric or semantic contradictions. Research boundary labels are provenance, not row-level authorization. Audit stores original and final snapshots, not every intermediate event. Research editing assumes the app's single-store serial UI workflow; stale revisions prevent lost updates, while multi-process collaborative review is unsupported.

## Exact next action

Perform the remaining manual GUI and eligible-device model checks listed in `PHASE_6_CHECKPOINT.md`. The repository is technically ready for Phase 7 based on build, migration, integrity, search, RAG, and ingestion evidence, but Phase 7 must not begin without an explicit request.
