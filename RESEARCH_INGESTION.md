# Phase 6 backend checkpoint — schema version 1

**INCOMPLETE:** the local backend is implemented and deterministic tests pass. There is no Research UI, file importer, review editor, or user-visible history yet. Do not treat this checkpoint as Phase 6 acceptance. No Phase 7 work is included.

## External package contract

Use UTF-8 JSON, at most 5 MB and 1000 total proposals. `Fixtures/alloy-725-research.json` is a complete synthetic example, not engineering evidence. Required top-level fields:

- `schemaVersion`: integer `1`; other versions fail safely.
- `packageID`: nonblank external identity, retained in audit; repeated imports are permitted and require fresh review.
- `topic`: nonblank string; `summary` is optional.
- `boundary`: `publicPersonal` or `restricted`. It records provenance, not authorization to export.
- `entities`, `claims`, `relationships`: arrays (empty arrays allowed if another contains proposals).

Every proposal has a nonblank package-local `id` of at most 128 characters. IDs must be unique across all three arrays. References must point inside this package; external producers cannot select permanent database IDs. Unknown additive JSON fields are ignored by the typed model; original JSON is retained in the session. They must not carry meaning required for safe interpretation; use a new schema version for semantic changes.

Entity fields: required `id`, `kind` (`material`, `mechanism`, `standard`, `component`, `source`), `name`; optional `secondary`, `detail`, `aliases` (string array). Source entities require a `source` object; its optional string fields are `organization`, `documentType`, `revisionYear`, `url`, `publication`. An empty metadata object is valid when only the title is known. URLs, if present, must be absolute HTTP(S). Other entity kinds cannot contain source metadata. Source title is `name`; use distinct titles including revision when separate source editions need separate permanent records under the existing unique-name constraint.

Claim fields: required `id`, `subjectID`, `predicate`, `statement`, `sourceID`; optional `conditions`, `locator`, `confidence` (0–1), `notes`. Subject references a non-source entity; source references a source entity. Unknown locators may be omitted; they are never invented. Confidence is external metadata, not verification. There is deliberately no accepted `verified` field.

Relationship fields: required `id`, `fromID`, `predicate`, `toID`; optional `supportingClaimID`. Endpoints must exist and differ. A supporting claim must be in the package.

Malformed JSON, missing/type-invalid fields, unsupported versions, invalid references/kinds/URLs, blank essential fields, duplicate IDs, duplicate normalized entity names, exact duplicate claim signatures and duplicate relationship triples are rejected before staging. Parse failures do not modify permanent knowledge. Content-equivalent claims with different evidence remain separate proposals.

## Lifecycle and review API

`KnowledgeStore.importResearch` validates and persists a `ResearchSession`. Schema migration 4 adds only `research_sessions` in the existing SQLite database. Its JSON snapshot contains import identity/time, original JSON, edited package, decisions, status, revision, failure note and resulting stable record IDs. It is neither a second knowledge database nor part of FTS. Pending sessions survive reopening.

`researchMatches` returns deterministic suggestions. `decideResearch` records a per-item pending/accept/reject/merge decision. No dependency is implicitly approved. `editResearch` validates the replacement package (same packageID), keeps original JSON and resets all decisions because source/entity edits can affect dependent claims. `cancelResearch` closes staging without changing permanent knowledge. `commitResearch` closes the session after inserting only accepted proposals or explicitly reusing merge targets. Pending and rejected proposals stay in the closed audit snapshot; reimport for further review. A commit with no approvals is rejected. Repeated or stale-session commits are rejected.

New claims are always **Unverified**. After ingestion, use the existing Claims editor for explicit Reviewed/Verified lifecycle changes. Phase 5 can retrieve unverified claims as evidence gaps, but only Reviewed/Verified claims enter generated answers. Approval for storage is not review of engineering validity.

## Matching, conflicts and merge policy

Entity matching compares normalized names, secondary designations and supplied aliases against same-kind records. Case, diacritics, punctuation and spaces are ignored for entity candidate discovery. Thus Alloy 725 and UNS N07725 can resolve through secondary designations; there is no material-specific logic. Imported aliases are preserved in record detail for subsequent matching. No fuzzy AI matching or automatic normalization writes are implemented.

Source title/designation matches with differing metadata are flagged as possible duplicates; reuse is allowed only when serialized source detail and secondary designation match exactly. This deliberately avoids silently conflating revisions. Near-identical sources with different titles are not currently detected.

Claims are compared by resolved subject and normalized predicate. Identical statement/conditions/source/locator can be reused; different conditions are labelled related, identical statements with differing evidence are labelled separately, and differing statements with the same conditions are labelled **possible conflict**, not proven contradiction. Numeric/negation reasoning and general semantic equivalence are not implemented. Commit rechecks exact statement, predicate, conditions, source, and locator before reuse. Different evidence must remain a separate claim. Claim notes/confidence remain in the audit when merging and do not overwrite existing notes.

Relationship candidates compare resolved endpoints and predicate; commit additionally requires the same supporting claim. Every merge means **reuse identity, preserve existing fields**. Existing Verified knowledge is never overwritten by this backend. The same-name unique constraint prevents obvious duplicate insertion; users must choose reuse or edit a genuinely distinct source/entity name. Alias-based duplicates can still be explicitly accepted as separate names; UI warnings are pending.

## Atomicity, provenance and local boundary

Commit uses the existing SQLite savepoint transaction around all repository writes, FTS rebuilds, foreign-key checks and the committed audit snapshot. Failed operations roll back knowledge and indexes, retaining a retryable failure note in staging. Commit obtains the writer lock before checking the persisted revision. Other staging operations assume the app's current single-store, serial UI usage; multi-process concurrent review editing is not a supported workflow.

Source metadata is preserved in existing source-record detail and in typed package audit data. Claims retain source ID, conditions, locator, notes, import/session identity, boundary and external confidence. No fictitious Library file/bookmark is created. Result mappings preserve proposal-to-permanent identity, including merges. Audit captures original/final package and final decisions, not an event log of every intermediate edit.

No network access, external provider call, autonomous research, or local-data export is added. Boundary labels are session provenance, not row-level access controls; both categories remain local. Future restricted access separation must be designed explicitly. Existing domain, search and RAG paths remain authoritative.

## Verification and next task

Run `Scripts/test.sh` for store/migration, LocalRAG and ingestion suites. Ingestion tests cover malformed/version/structure/reference/source URL validation, internal duplicates, designation/source matching, potential conflict, editing, partial approval/rejection, dependency failure, late forced rollback including FTS, Verified preservation, merge, cancellation, audit reopen, search and ordinary RAG stored citations following explicit claim review. Fixtures and generated test replies are synthetic; they do not verify an actual model.

**Exact next task:** add a native Research sidebar destination and JSON file picker, persisted-session browser, proposal/evidence/match inspection, individual accept/reject/edit/reuse controls, dependency error handling, explicit commit/cancel and history/result IDs. Reuse these backend APIs; do not replace prior architecture. Add focused regressions for UI-driven edits, restricted label retention, source revision differences, changed-condition claims, relationship reuse and stale reviews. Then build, launch, exercise the real import → review → commit → Search → Claims review → Ask flow, inspect appearance and make one targeted correction pass. Native interaction and actual model response are UNVERIFIED; automated process launch is not a substitute. Finish the Phase 6 architecture audit before marking complete.
