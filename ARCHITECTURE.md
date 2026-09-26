# Architecture

Materials Intelligence is a native SwiftUI macOS 15+ application with one Xcode app target and no third-party runtime. `App` opens the local database, `UI` reads and writes through `KnowledgeStore`, `Domain` holds value models, and `Database` owns SQLite statements and migration. A future iOS/iPadOS client could reuse the domain and storage concepts, but no mobile target or local AI architecture is implemented.

## Domain and storage

`KnowledgeRecord` has an immutable string ID, kind (`material`, `mechanism`, `standard`, `component`, `source`), canonical name, detail, and secondary designation. The common `records` table gives claims, relationships, and document associations stable foreign-key targets. Names are unique within kind, case insensitively. `EngineeringClaim` is separate from UI narrative or future AI output; it stores subject/source foreign keys, predicate, statement, conditions, locator, verification state, evidence level, notes, and timestamps. States are Draft, Unverified, Reviewed, Verified, Superseded, and Archived. A trigger requires sources to have `source` kind. `KnowledgeRelationship` links records with an optional supporting-claim foreign key. SQLite RESTRICT foreign keys prevent referenced records and claims from being silently removed.

The database resides in `Application Support/MaterialsIntelligence/knowledge.sqlite`; every connection enables foreign keys. `PRAGMA user_version` selects numbered migrations. Version 1 contains records, claims, and relationships; version 2 expands claim states; version 3 adds documents, associations, and FTS5. Fresh databases create the current version. Version 1 upgrades transactionally by copying claims and dependent relationships into replacement tables, dropping the old relationships before old claims, renaming replacement tables, recreating indexes/triggers, and checking foreign-key integrity before commit. The migration retains IDs and provenance. A newer schema fails safely.

## UI and lifecycle

The primary `NavigationSplitView` contains Overview, Ask, Search, Library, Materials, Damage Mechanisms, Standards, Components, Sources, Claims, Relationships, and Settings. Ask is an explicit Phase 5 placeholder. Record and claim forms update existing stable IDs. Claims can move through all six states, including archive without erasing provenance. Relationship creation optionally cites a claim; removal requires confirmation and leaves its records/claim intact. Record, claim, and Library deletions require confirmation. References that would be orphaned block deletion and the UI explains the dependency.

## Search

The version 3 `search_index` is a contentful SQLite FTS5 table over record names/details plus directly linked relationship and active-claim context, claims plus subject/source context, and Library metadata. This allows a material query to surface its connected standard or source without a graph UI. Each relevant repository write rebuilds this compact index. Record, claim, relationship, and document write/delete operations wrap the primary mutation, association changes where applicable, and FTS rebuild in one SQLite savepoint. A failed logical operation rolls back all of them. Seed insertion has an outer transaction.

Search turns Unicode letter/number runs into quoted prefix tokens with the `*` outside the quote, such as `"hyd"*`; punctuation cannot inject FTS operators. Tokens are joined with OR for broad engineering recall. Results rank by SQLite BM25 then title, and can be filtered by entity type, record kind, or exact claim state. Archived claims remain stored but are excluded from the search index; deleted rows are reindexed away. Results route to the matching record, claim, or Library detail. FTS is lexical and searches document metadata only. Specialized tag, material-family, standard-organization, and date fields are not yet modeled.

## Document Library

`documents` stores title, organization/author, revision/year, source type, notes, filename, and base64 security-scoped bookmark. `document_records` associates documents with knowledge records. The Library editor can update metadata and associations under the same document ID. Files stay at their original locations; content is neither copied nor extracted. On open, the app resolves the bookmark, starts scoped access, checks readability, asks macOS to open the URL, and stops scoped access. If the bookmark is stale, it refreshes and stores a replacement when possible. “Locate file…” lets the user restore a missing, moved, or inaccessible reference without changing metadata identity or associations. Broken file access never deletes engineering knowledge.

Data flow: SwiftUI view → `KnowledgeStore` → SQLite/FTS5 → value models → SwiftUI. Normal operation uses no network. A future Phase 5 may reuse deterministic search, but this project has no AI, embeddings, or vector store.
