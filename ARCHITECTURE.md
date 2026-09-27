# Architecture

Materials Intelligence is a native SwiftUI macOS 26+ application with one Xcode app target and no third-party runtime. `App` opens the local database, `UI` reads and writes through `KnowledgeStore`, `Domain` holds value models, `Database` owns SQLite statements and migration, and `AI` owns local question answering. No mobile target is implemented.

## Domain and storage

`KnowledgeRecord` has an immutable string ID, kind (`material`, `mechanism`, `standard`, `component`, `source`), canonical name, detail, and secondary designation. The common `records` table gives claims, relationships, and document associations stable foreign-key targets. Names are unique within kind, case insensitively. `EngineeringClaim` is separate from UI narrative or future AI output; it stores subject/source foreign keys, predicate, statement, conditions, locator, verification state, evidence level, notes, and timestamps. States are Draft, Unverified, Reviewed, Verified, Superseded, and Archived. A trigger requires sources to have `source` kind. `KnowledgeRelationship` links records with an optional supporting-claim foreign key. SQLite RESTRICT foreign keys prevent referenced records and claims from being silently removed.

The database resides in `Application Support/MaterialsIntelligence/knowledge.sqlite`; every connection enables foreign keys. `PRAGMA user_version` selects numbered migrations. Version 1 contains records, claims, and relationships; version 2 expands claim states; version 3 adds documents, associations, and FTS5; version 4 adds persisted research-session snapshots. Fresh databases create the current version. Version 1 upgrades transactionally by copying claims and dependent relationships into replacement tables, dropping the old relationships before old claims, renaming replacement tables, recreating indexes/triggers, and checking foreign-key integrity before commit. Direct version 3 to version 4 migration is regression-tested with existing knowledge retained. A newer schema fails safely.

## UI and lifecycle

The primary `NavigationSplitView` contains Overview, Ask, Search, Research, Library, Materials, Damage Mechanisms, Standards, Components, Sources, Claims, Relationships, and Settings. Ask provides Phase 5 local answering when the on-device model is available. Record and claim forms update existing stable IDs. Claims can move through all six states, including archive without erasing provenance. Relationship creation optionally cites a claim; removal requires confirmation and leaves its records/claim intact. Record, claim, and Library deletions require confirmation. References that would be orphaned block deletion and the UI explains the dependency.

## Search

The version 3 `search_index` is a contentful SQLite FTS5 table over record names/details plus directly linked relationship and active-claim context, claims plus subject/source context, and Library metadata. This allows a material query to surface its connected standard or source without a graph UI. Each relevant repository write rebuilds this compact index. Record, claim, relationship, and document write/delete operations wrap the primary mutation, association changes where applicable, and FTS rebuild in one SQLite savepoint. A failed logical operation rolls back all of them. Seed insertion has an outer transaction.

Search turns Unicode letter/number runs into quoted prefix tokens with the `*` outside the quote, such as `"hyd"*`; punctuation cannot inject FTS operators. Tokens are joined with OR for broad engineering recall. Results rank by SQLite BM25 then title, and can be filtered by entity type, record kind, or exact claim state. Archived claims remain stored but are excluded from the search index; deleted rows are reindexed away. Results route to the matching record, claim, or Library detail. FTS is lexical and searches document metadata only. Specialized tag, material-family, standard-organization, and date fields are not yet modeled.

## Document Library

`documents` stores title, organization/author, revision/year, source type, notes, filename, and base64 security-scoped bookmark. `document_records` associates documents with knowledge records. The Library editor can update metadata and associations under the same document ID. Files stay at their original locations; content is neither copied nor extracted. On open, the app resolves the bookmark, starts scoped access, checks readability, asks macOS to open the URL, and stops scoped access. If the bookmark is stale, it refreshes and stores a replacement when possible. “Locate file…” lets the user restore a missing, moved, or inaccessible reference without changing metadata identity or associations. Broken file access never deletes engineering knowledge.

## Local question answering

Ask calls `LocalRAG`, which uses the existing `KnowledgeStore.search` FTS5 path and resolves claim hits and linked record hits to stored `EngineeringClaim`, subject, and source records. Archived and superseded claims are excluded. Only Reviewed or Verified claims enter the model context; Draft and Unverified matches remain visible as evidence gaps. The context builder limits candidates to six claims, clips field lengths, and caps the prompt at 7,000 characters. It supplies exact claim IDs, verification states, source names, and locators. Library metadata may affect FTS ranking, but PDF/document content is never supplied as evidence.

`LocalAIProvider` isolates generation; the sole implementation is `AppleLocalProvider`, using `SystemLanguageModel.default` and `LanguageModelSession` when the on-device model reports available. Unsupported or unready Apple Intelligence runtimes show a clear unavailable state. No cloud fallback, key, network request, embedding index, or second search store exists.

The model is instructed to return JSON answer points with stored claim IDs. `LocalRAG` rejects malformed responses, unknown IDs, points without citations, and excessive output. The UI maps accepted IDs back to records from the same retrieval, shows generated explanation separately from supporting claims and sources, displays verification states, and opens stored claim/source records. Citation IDs are structurally validated; semantic support still requires human engineering review. When evidence is absent or only unreviewed, Ask refuses before generation. If generation cannot produce a traceable answer, Ask shows retrieved evidence without a generated conclusion. Retrieved strings and the question are labelled untrusted; the trusted provider instruction prohibits following directions inside them.

Data flow: SwiftUI Ask → `LocalRAG` → existing `KnowledgeStore.search`/SQLite FTS5 → bounded evidence context → on-device Apple model → validated claim-ID mapping → SwiftUI. The answer is transient and never written to the knowledge database. Normal operation uses no network.

## Phase 6 backend and native Research UI

SQLite migration 4 adds `research_sessions` snapshots to the same database; original JSON, edited package, individual decisions, import metadata, status and result IDs persist without entering FTS. `ResearchPackage` validates schema v1 before staging. `KnowledgeStore` provides import, edit (invalidating approvals), deterministic matches, decisions, cancel and commit. Explicit merges reuse identities without updating stored fields. Source metadata remains in source detail and typed audit data; claims retain evidence and package provenance.

Approved dependencies must also be explicitly accepted or reused. An outer savepoint includes permanent repository mutations, existing FTS updates and committed audit. Failure rolls back knowledge and records a retryable staging error. New claims remain Unverified; existing Claims review enables the unchanged RAG eligibility gate. The Research page exposes staged sessions, typed proposal sections, match reasons, individual decisions, validated JSON editing, commit/cancel, history and result IDs. No network or research agent is added. Public/restricted labels are local session provenance, not access control. See `RESEARCH_INGESTION.md` for schema, policy and verification limits.

## Phase 7 graph

`KnowledgeGraph` creates a transient indexed snapshot from the existing repository. No second persistence layer or schema is introduced. `GraphPage` presents bounded BFS paths, exact edge/claim provenance and generic comparisons using existing UI primitives. See `PHASE_7_CHECKPOINT.md` for derivation, ranking, status and limit semantics.

## Phase 8 engineering tools

`AssessmentInput`, `DegradationReport`, and `DegradationAssessment` form a small reusable workflow boundary. Rules are source-backed existing claims, not a parallel rule store. Deterministic screening and optional local explanation are separate. `AssessmentPage` uses existing native design components and exports text. See `ENGINEERING_TOOLS.md` for the rule contract.
