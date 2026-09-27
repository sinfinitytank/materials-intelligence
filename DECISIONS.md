# Architectural Decisions

## 2026-09-27 — Native SwiftUI macOS foundation

Use a native SwiftUI macOS application with a small Xcode project and no third-party dependencies. This follows the project’s local-first Apple direction, keeps the foundation buildable, and avoids committing to web or service infrastructure prematurely.

## 2026-09-27 — Minimal Phase 0 surface

Create only the application entry point and a root view. Future source boundaries are documented but not populated with placeholder classes, preventing Phase 0 from silently implementing later phases.

## 2026-09-27 — Development build signing

The local development target disables code signing so it can be built and verified without a configured Apple development team. This does not change the native app architecture; distribution signing remains outside Phase 0.

## 2026-09-27 — Native Phase 1 application shell

Use `NavigationSplitView`, native `List` selection, SF Symbols, system typography, native toolbar placement, and SwiftUI `ContentUnavailableView` for the first product shell. This keeps navigation predictable and information-dense on macOS without introducing a web runtime, third-party design system, or future-phase backend behavior.

## 2026-09-27 — Phase 2 common record identity

Use one `records` table for the shared identity and small common fields of materials, damage mechanisms, standards, components, and sources. This gives claims and relationships real foreign keys across kinds without five nullable targets or a parallel graph store. Keep specialized attributes out of the first migration until authoring and retrieval requirements justify them. The tradeoff is that Phase 2 does not yet represent detailed chemistry, property, or standard-revision structures.

## 2026-09-27 — Claims, sources, and relationships

Store engineering claims separately from UI prose and future AI output. Every claim references a source record and stores locator, conditions, verification status, evidence level, notes, and timestamps. Relationship edges have stable IDs and can cite a supporting claim. Database foreign keys restrict deletion of referenced data; a trigger checks source kind. Unverified illustrative seed records must not be treated as engineering evidence.

## 2026-09-27 — SQLite versioning and local repository

Use system SQLite through a small Swift repository, with `PRAGMA user_version` and transactional numbered migrations. This keeps the app offline and avoids third-party dependencies. Reject databases newer than the running app. Future migrations must preserve stable IDs and source links and include upgrade tests.

## 2026-09-27 — Phase 3 lifecycle and safe deletion

Use explicit claim states and keep record deletion restricted by SQLite foreign keys. Claims may be archived; records with live evidence or relationships remain until those references are intentionally removed. This is the smallest safe lifecycle compatible with the Phase 2 schema.

## 2026-09-27 — Phase 4 FTS rebuild and referenced documents

Use SQLite FTS5 with a compact denormalized index rebuilt after repository writes instead of partial hand-written index triggers. The local dataset is small, so this makes update/delete synchronization explicit and testable. Rank with BM25 and filter deterministically. Store document metadata and security-scoped bookmark references, not copied technical files; stale or missing files never delete engineering metadata or associations.

## 2026-09-27 — Safe claim migration with dependent relationships

The original version 1 → 2 migration dropped `claims` while `relationships.supporting_claim_id` could still reference it. SQLite `ON DELETE RESTRICT` correctly rejected that operation. Rebuild both tables in one transaction while foreign keys stay enabled: copy claims to the new schema, copy relationships referencing the replacement claim table, drop old relationships before old claims, rename replacements, recreate indexes/triggers, then run `foreign_key_check` before commit. This preserves IDs, provenance, and referential integrity.

## 2026-09-27 — Atomic FTS writes and claim archive behavior

Keep the small explicit FTS5 rebuild strategy, but put each primary write, relationship change, association update, and index rebuild in one SQLite savepoint. This prevents partial writes if indexing or association insertion fails, including inside seed transactions. Index directly linked record names and active-claim context with each record so a query can surface connected standards and sources. Parse search input to Unicode words and emit quoted FTS5 prefix tokens with `*` outside the quotes. Archived claims remain in the evidence database and leave the search index; they can be reviewed in Claims.

## 2026-09-27 — Native recovery for referenced documents

Continue storing references rather than copies. Resolve and scope access only while opening; refresh stale bookmarks where possible and expose “Locate file…” to replace a broken reference in place. Failed file access preserves metadata and associations. Real bookmark persistence/resolution has automated coverage; the final OS file-panel/open interaction requires manual verification.

## 2026-09-27 — Reference-led native UI alignment

Use a small set of SwiftUI presentation primitives—grouped sidebar navigation, page headers, bordered panels, and a neutral canvas/material treatment—to bring the working Phase 0–4 app toward the repository’s existing UI/UX references. Keep the implementation in the presentation layer and preserve native controls, existing routes, and all backend behavior. This avoids a visual rewrite of each screen and leaves future Phase 5 concepts as visual placeholders only.

## 2026-09-27 — Explicit native navigation hit targets

Replace implicit `List(selection:)` navigation and row tagging in the sidebar, record browser, claims browser, and Library browser with explicit SwiftUI buttons and stable selected-state styling. The first UI pass could build successfully while leaving the main interaction paths unverified and visually static; explicit hit targets make every current Phase 0–4 route directly clickable without changing the data model. Phase 5 Ask/research behavior remains intentionally out of scope.

## 2026-09-27 — Local RAG over existing FTS5

Reuse `KnowledgeStore.search` for candidate retrieval and resolve candidates to stored claims, subjects, and sources. Gate model context to Reviewed or Verified claims, bound it by count and characters, and require each generated answer point to reference exact retrieved claim IDs. This preserves the Phase 4 search architecture and source traceability without a second index or embeddings. Library document contents remain unavailable. ID validation prevents fabricated record links but does not prove semantic support; the UI keeps evidence inspectable.

## 2026-09-27 — Guarded Apple on-device provider

Use a small `LocalAIProvider` boundary with one `AppleLocalProvider` implementation. The app now requires macOS 26+, matching the Xcode 27 SDK APIs for `SystemLanguageModel.default` and `LanguageModelSession`; no older deployment compatibility or availability guards are retained. Show an unavailable state when the local model is absent or unready, and never fall back to cloud inference. The development Mac reported `modelNotReady`, so actual model generation remains unverified.

## 2026-09-27 — Phase 6 staged snapshots and identity reuse

Use versioned JSON interchange and a schema-4 staging/audit table in the existing SQLite database. Keep original packages and final review snapshots; avoid a second knowledge store or event-sourcing framework. Deterministic matching offers candidates; explicit merge means reuse identity without overwriting stored engineering fields. Source revisions with differing metadata remain separate; claim reuse requires identical evidence/context. Commit repository writes, indexes and audit atomically. Imported claims remain Unverified and require the existing Claims lifecycle review before generated RAG answers. Native review UI remains the next unit; this backend checkpoint is not Phase 6 completion. No architectural replacement or Phase 7 feature was introduced.

## 2026-09-27 — Native Phase 6 Research review surface

Implement the research import/review workflow as a dedicated SwiftUI navigation section over the existing staged-session APIs. Keep proposals separate from committed knowledge, require explicit accept/reject/merge decisions, preserve original JSON for audit, and show session history.

## 2026-09-27 — Post-Phase-6 consolidation

Retain the Phase 2–6 architecture after audit: one SQLite store, deterministic FTS5 retrieval, staged research snapshots, and the existing claim-review gate remain appropriate and no replacement is justified. Restore material add/edit/delete actions that were lost in the specialized material-profile presentation, keep sources in one Research review section, and add direct schema-3 migration plus invalid-import/edit regressions. No Phase 7 behavior is introduced.

## 2026-09-27 — Bounded graph over existing knowledge

Use an adjacency snapshot and shortest-path native disclosure lists rather than a second graph database or visual-graph runtime. Only active claim source references derive edges. Preserve stored predicates, direction and evidence statuses; a browseable path is not a verified causal explanation. No architecture replacement.

## 2026-09-27 — Explicit source-backed screening rules

Represent scoped deterministic rules as versioned JSON in existing claim notes with predicate assessment_rule. This preserves claim lifecycle, source traceability, research review and migration compatibility without unsupported built-in limits. Direct relationships identify candidates only. A conservative complete degradation workflow precedes other tool families.

## 2026-09-27 — Separate permitted vault and conservative snapshot sync

Share source membership rather than replace the working Mac architecture. Use one universal mobile target with native adaptive navigation. Existing work data is never automatically eligible for personal iCloud: a separate vault with opt-in is the sync boundary. Whole-snapshot CloudKit compare-and-swap and explicit review avoid silent overwrites while retaining recoverable content. This intentionally favors simple safe personal sync over background field-level merge. Documents sync metadata only, not device bookmarks/files. No architectural replacement.
