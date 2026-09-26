# Architecture

Materials Intelligence remains a native macOS SwiftUI application (macOS 15+) with no third-party runtime. `App` opens the local database, `UI` reads records through `KnowledgeStore`, `Domain` contains value models, and `Database` owns SQLite statements and migration. Search, intelligence, research, documents, and graph exploration are future boundaries, not current implementations.

## Phase 2 domain and storage

`KnowledgeRecord` has an immutable string ID, a kind (`material`, `mechanism`, `standard`, `component`, `source`), a canonical name, a short detail, and a secondary designation. The single `records` table gives claims and relationships one stable foreign-key target across record kinds. This is intentionally a small common core; specialized properties and controlled vocabularies can be added by later migrations after their requirements are known. Names are unique within kind, case insensitively. IDs are UUIDs for new records; demo IDs are deterministic.

`EngineeringClaim` stores a statement separately from presentation or future AI narrative. It references a subject record and a source record, and stores predicate, conditions, locator (page/section), verification status, evidence level, notes, and database timestamps. A trigger requires its source target to have `source` kind. A claim is never marked verified by seeding. The `KnowledgeRelationship` table references two records and optionally a supporting claim. The foreign keys use restricted deletion to avoid orphaning evidence. Relationship triples are unique. Some relationships may lack supporting claims; these are associations, not verified engineering assertions.

SQLite is stored in the user's Application Support/MaterialsIntelligence directory. Foreign keys are enabled per connection. `PRAGMA user_version` controls sequential, transactional migrations; version 1 creates the three tables, indexes, and claim triggers. Opening a newer schema fails safely. Future changes add numbered migrations and test upgrading old files. The repository methods offer create/update through stable-ID upsert, read/list, and explicit delete. The UI is read-only in Phase 2. The small development dataset is inserted only into an empty database and clearly labels its engineering links unverified and illustrative.

Data flow: SwiftUI view → `KnowledgeStore` → SQLite → value models → SwiftUI. The app does not use network access. A future shared module may reuse domain and storage code on iPhone/iPad, but there is no mobile target or sync now.
