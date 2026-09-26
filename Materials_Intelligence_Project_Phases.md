# Materials Intelligence — Master Project Phases

**Purpose:** This document is the master implementation roadmap for the **Materials Intelligence** project.

It is designed to be used repeatedly during development. When you are ready to start a phase:

1. Open this file.
2. Copy the complete section for the phase you want to build.
3. Paste it into a new ChatGPT chat.
4. Ask:  
   **“Using this phase definition and the current state of my project, prepare one detailed Codex execution prompt for this phase. Keep the existing architecture intact and do not implement future phases.”**
5. If available, also provide ChatGPT with the latest:
   - `CURRENT_STATE.md`
   - `MILESTONE.md`
   - `ARCHITECTURE.md`
   - `DECISIONS.md`
6. Review the generated Codex prompt.
7. Give that prompt to Codex.
8. After the phase is complete, verify the app manually before moving to the next phase.

---

# 1. Product Vision

**Materials Intelligence** is a local-first native Apple application for oil & gas materials engineering.

The long-term goal is to create a personal engineering intelligence system that grows with the user over time.

The system will capture, connect, retrieve, and reason across engineering knowledge such as:

- carbon steels
- low-alloy steels
- stainless steels
- duplex and super duplex stainless steels
- nickel alloys
- corrosion-resistant alloys
- metallurgy and microstructures
- mechanical properties
- heat treatment
- welding
- manufacturing
- corrosion
- degradation mechanisms
- CO2 corrosion
- H2S / sour-service damage
- SSC
- HIC
- SOHIC
- hydrogen embrittlement
- SCC
- pitting
- crevice corrosion
- galvanic corrosion
- erosion-corrosion
- fatigue and corrosion fatigue
- API requirements
- ASME requirements
- ASTM requirements
- ISO requirements
- NACE requirements
- API 5CT
- API 5CRA
- material selection
- fit-for-purpose assessment
- vendor qualification
- manufacturing qualification
- NACE Method A testing
- NACE Method D testing
- subsea equipment
- trees
- manifolds
- risers
- wellheads
- tubing hangers
- liner hangers
- casing
- tubing
- downhole equipment
- engineering case studies
- manufacturing deviations
- failure investigations

The application should ultimately operate primarily **offline**.

Internet access should only be needed when the user intentionally asks the system to research information that is not already present in the local knowledge base.

---

# 2. Core Product Principles

These principles apply to every phase.

## 2.1 Local-first

Normal operation should not depend on:

- an internet connection
- a cloud AI service
- paid API calls
- remote databases

The user's engineering database, search capability, document library, and eventually most AI reasoning should run locally.

## 2.2 Native Apple application

Primary technology direction:

- Swift
- SwiftUI
- native macOS APIs
- SQLite
- SQLite FTS5
- Apple Foundation Models / local models later
- shared architecture that can later support iPhone and iPad

Avoid unless specifically justified later:

- Electron
- React
- Node.js
- Docker
- PostgreSQL
- Firebase
- AWS
- separate web backend

## 2.3 Engineering traceability

The system must distinguish between:

1. source documents
2. extracted engineering claims
3. relationships between engineering objects
4. verified knowledge
5. AI-generated explanations

AI-generated text must never automatically become verified engineering knowledge.

Where practical, engineering claims should retain:

- source
- document title
- page or section
- year/revision
- date added
- verification status
- confidence or evidence level
- notes

## 2.4 AI is not the database

The project should not depend on continuously retraining a language model.

Instead, the architecture should use:

**structured knowledge + retrieval + local AI reasoning**

The intelligence grows mainly because the knowledge base grows.

## 2.5 Controlled development

Do not build the entire product at once.

Each phase should:

- have a clear scope
- preserve buildability
- avoid premature future features
- end with documentation updates
- end with a Git checkpoint
- have measurable acceptance criteria

---

# 3. Permanent Project Documentation

The repository should maintain these files throughout development:

- `AGENTS.md`
- `ARCHITECTURE.md`
- `ROADMAP.md`
- `CURRENT_STATE.md`
- `MILESTONE.md`
- `DECISIONS.md`

## AGENTS.md

Permanent instructions for future Codex sessions.

It should include rules such as:

- inspect existing architecture before changing it
- preserve native SwiftUI architecture
- prefer simple native solutions
- avoid unnecessary dependencies
- do not silently modify verified engineering knowledge
- do not implement future phases unless instructed
- maintain buildability
- update project documentation after meaningful changes
- preserve source traceability
- do not replace major architectural decisions without recording the reason

## ARCHITECTURE.md

Documents:

- application layers
- domain boundaries
- data flow
- SQLite architecture
- search architecture
- future local-AI architecture
- future research-ingestion architecture
- separation between UI, domain logic, data storage, and intelligence
- future iOS/iPadOS reuse

## ROADMAP.md

Tracks the current phase and overall roadmap.

## CURRENT_STATE.md

Describes exactly what currently exists in the project.

Future Codex sessions should be able to understand the current system without rediscovering the complete repository.

## MILESTONE.md

Tracks:

- current milestone
- completed work
- current build status
- major files changed
- known problems
- unfinished work
- exact recommended next action

## DECISIONS.md

Records significant architectural decisions and the reason behind them.

---

# 4. Codex Usage-Limit Protection

During every development phase:

When approximately **10% of the current Codex five-hour allowance remains**:

1. Do not begin another major task.
2. Finish the current safe unit of work where practical.
3. Leave the repository in a buildable state.
4. Update:
   - `CURRENT_STATE.md`
   - `MILESTONE.md`
   - `ROADMAP.md` where relevant
   - `DECISIONS.md` where relevant
5. Record the exact next task.
6. Create a clean Git checkpoint where appropriate.

The next Codex session should resume from documentation rather than re-analyzing the whole project.

---

# 5. Complete Phase Roadmap

| Phase | Name | Main Outcome |
|---|---|---|
| 0 | Project Foundation | Stable native project and development rules |
| 1 | Native Mac App Shell | Professional usable application structure |
| 2 | Engineering Knowledge Model | Structured materials-engineering data model |
| 3 | Knowledge Management | Create, edit, verify, and connect engineering knowledge |
| 4 | Local Search & Library | Fast offline search and document management |
| 5 | Local AI & RAG | Offline question answering from stored knowledge |
| 6 | Research Ingestion | New research becomes reviewed local knowledge |
| 7 | Knowledge Graph & Engineering Intelligence | Deep cross-linking and engineering exploration |
| 8 | Engineering Tools | Material selection, degradation, qualification, case workflows |
| 9 | iPhone/iPad & Sync | Portable access to the same intelligence |
| 10 | Advanced Engineering Agent | Multi-step local engineering reasoning system |

---

# Phase 0 — Project Foundation

## Objective

Create the clean technical foundation for the complete Materials Intelligence product.

This phase is about architecture and continuity, not functionality.

## Why this phase exists

The project will eventually become large.

Without a controlled foundation, later Codex sessions may:

- create inconsistent patterns
- re-analyze the repository repeatedly
- introduce unnecessary technologies
- duplicate functionality
- break architecture
- consume excessive usage allowance

Phase 0 prevents this.

## Scope

Build:

- native macOS SwiftUI project
- clean source-code organization
- basic application entry point
- project documentation
- Git repository/checkpoint
- build verification
- rules for future Codex sessions

## Suggested source structure

```text
MaterialsIntelligence/
│
├── App/
├── UI/
├── Domain/
├── Database/
├── Search/
├── Intelligence/
├── Research/
├── Documents/
└── KnowledgeGraph/
```

Only create directories/classes that are useful now. Avoid unnecessary placeholder implementation.

## Technical components

- Xcode project
- Swift
- SwiftUI
- macOS 26+ target; older macOS deployment compatibility is out of scope
- Git
- project documentation

## User-visible result

A basic native Mac application launches successfully.

It does not yet need useful engineering functionality.

## Include

- project creation/configuration
- application naming
- bundle structure
- macOS 26 deployment target for all configurations
- SwiftUI entry point
- basic placeholder root view if required
- project folders/groups
- architecture documentation
- development rules
- Git initialization
- clean initial commit
- build verification

## Explicitly exclude

Do not add:

- AI
- SQLite functionality beyond a future architectural note
- semantic search
- CloudKit
- iPhone/iPad target
- material-selection tools
- vendor qualification tools
- research agents
- knowledge graph implementation
- unnecessary third-party libraries

## Dependencies / prerequisites

- Xcode installed
- Codex available
- a local project directory
- Git available
- supported macOS development environment

## Codex execution guidance

Codex should:

1. inspect the project directory
2. create or validate the native SwiftUI project
3. establish project structure
4. create the permanent documentation files
5. document architecture decisions
6. build the project
7. fix compilation problems
8. update milestone documentation
9. commit a stable checkpoint

Codex should not start Phase 1 automatically.

## Acceptance criteria

Phase 0 is complete when:

- Xcode project opens successfully
- project compiles
- application launches
- project uses native SwiftUI
- no web runtime is present
- project structure is documented
- `AGENTS.md` exists
- `ARCHITECTURE.md` exists
- `ROADMAP.md` exists
- `CURRENT_STATE.md` exists
- `MILESTONE.md` exists
- `DECISIONS.md` exists
- Git contains a clean checkpoint
- future phases have not been prematurely implemented

## Deliverables

- working Xcode project
- project directory structure
- six permanent documentation files
- initial Git history
- buildable application

## Testing expectations

Minimum:

- clean build
- launch test

No comprehensive automated tests are required yet.

## Documentation / checkpoint requirements

Update all six project documentation files.

Record:

- Xcode/Swift versions
- deployment target
- project structure
- major architecture decisions
- build status
- exact recommended Phase 1 task

## What Phase 1 unlocks

A stable foundation for building the actual application interface.

---

# Phase 1 — Native Mac App Shell

## Objective

Create the first real version of the Materials Intelligence application interface.

The result should feel like a professional native macOS engineering application.

## Why this phase exists

Before creating complex engineering models or AI, the product needs:

- predictable navigation
- a reusable design language
- native macOS interaction patterns
- clear information architecture

This prevents every future module from developing its own inconsistent UI.

## Main sections

Create the navigation structure for:

- Home / Overview
- Ask
- Materials
- Damage Mechanisms
- Components
- Standards
- Library
- Settings

Future sections can appear later.

## UI direction

Use:

- SwiftUI
- macOS-native navigation
- system typography
- system icons/SF Symbols
- appropriate split views
- inspectors where useful
- tables/lists for engineering data
- toolbar actions
- native search placement
- contextual menus where appropriate
- Liquid Glass where supported and appropriate

Avoid:

- web dashboard appearance
- excessive rounded cards
- oversized mobile-style controls
- decorative UI that reduces information density
- inconsistent padding/fonts/icons
- custom controls when native controls already solve the problem

## Scope

Build:

- application window structure
- sidebar
- navigation
- toolbar
- page containers
- reusable design constants/components
- empty-state screens
- responsive resizing
- basic settings page

## User-visible result

The application now looks like a real product.

The user can navigate between major areas even though engineering data is still mostly empty.

## Technical components

- SwiftUI
- `NavigationSplitView` or appropriate macOS-native navigation
- reusable view components
- application state for selected section
- window/scene configuration
- system appearance handling

## Include

- polished sidebar
- major page destinations
- window resizing behavior
- empty states
- standard toolbar
- consistent spacing
- typography hierarchy
- accessibility basics
- keyboard navigation where natural
- dark/light appearance support

## Explicitly exclude

Do not implement:

- full database
- AI
- semantic search
- research ingestion
- knowledge graph
- CloudKit
- advanced engineering logic
- iPhone/iPad

Do not fill the UI with fake complex functionality.

Small demo/placeholder content is acceptable only where it improves UI validation.

## Dependencies

Phase 0 completed and buildable.

## Codex execution guidance

Codex should:

1. read architecture and milestone documentation
2. preserve Phase 0 architecture
3. implement the navigation shell
4. create a small reusable design system
5. use native controls wherever possible
6. test multiple window sizes
7. verify build
8. update documentation
9. create a Git checkpoint

## Acceptance criteria

- application launches reliably
- all primary sections are reachable
- sidebar selection works correctly
- layout behaves correctly when resized
- UI is visually consistent
- native macOS conventions are followed
- no web views are used for the main UI
- no future-phase backend functionality is unnecessarily implemented
- project builds without errors

## Deliverables

- complete Mac app shell
- reusable UI components
- defined visual design language
- navigation architecture

## Testing

- build
- launch
- navigation
- resizing
- light/dark appearance
- basic keyboard interaction

## Documentation

Update:

- `CURRENT_STATE.md`
- `MILESTONE.md`
- `ARCHITECTURE.md` if UI architecture changed
- `DECISIONS.md` for important UI choices
- `ROADMAP.md`

## What Phase 2 unlocks

The UI now has stable destinations where real engineering entities can be introduced.

---

# Phase 2 — Engineering Knowledge Model

## Objective

Design and implement the structured data model that represents materials-engineering knowledge.

This is one of the most important phases in the entire project.

## Why this phase exists

The product must not become a collection of notes.

Engineering knowledge must be represented as structured objects and relationships.

The data model should support future:

- search
- AI retrieval
- citations
- knowledge graphs
- comparisons
- material-selection logic
- vendor qualification
- failure analysis

## Core engineering entities

Initial entities should include:

### Material

Examples:

- L80
- P110
- 4130
- 8630
- 13Cr
- Super 13Cr
- 22Cr Duplex
- 25Cr Super Duplex
- Alloy 625
- Alloy 718
- Alloy 725
- Alloy 825
- Alloy 925

Potential fields:

- canonical name
- UNS designation
- common names
- material family
- description
- chemistry information
- microstructure
- strength/property information
- heat-treatment state
- typical applications
- notes

### Damage Mechanism

Examples:

- CO2 corrosion
- SSC
- HIC
- SOHIC
- hydrogen embrittlement
- chloride SCC
- pitting
- crevice corrosion
- galvanic corrosion
- corrosion fatigue

Potential fields:

- name
- category
- description
- prerequisites
- controlling parameters
- morphology
- susceptible materials
- prevention/mitigation
- testing methods

### Standard

Examples:

- API 5CT
- API 5CRA
- ISO 15156
- NACE TM0177
- ASTM G48

Potential fields:

- organization
- document number
- title
- revision/year
- scope
- notes

### Component

Examples:

- casing
- tubing
- tree
- manifold
- riser
- wellhead
- tubing hanger
- liner hanger

### Engineering Claim

A claim is an individual factual engineering statement.

Example:

> A particular material has a stated environmental limitation under a defined condition.

A claim should be separate from AI-generated narrative.

Potential fields:

- subject
- predicate/type
- value/object
- conditions
- source
- page/section
- verification status
- confidence
- notes
- date added/modified

### Source

Represents the evidence behind a claim.

Examples:

- standard
- paper
- textbook
- vendor document
- internal report
- user note

Potential fields:

- title
- author/organization
- document type
- revision
- year
- file reference
- URL where applicable
- source quality level
- notes

### Relationship

Links engineering objects.

Examples:

```text
Alloy 725
    → susceptible_to
Hydrogen Embrittlement
```

```text
SSC
    → governed_by
ISO 15156
```

```text
Tubing
    → commonly_uses
13Cr
```

## Database direction

Use SQLite.

The implementation should:

- support schema migrations
- use stable identifiers
- enforce referential integrity
- avoid unnecessarily denormalized structures
- remain understandable to future Codex sessions

## User-visible result

The UI can start displaying real structured engineering objects.

A user should be able to see a material record and its associated claims, sources, and relationships.

## Include

- database schema
- Swift domain models
- persistence layer/repositories
- schema migration strategy
- stable IDs
- core entities
- relationships
- seed/demo data for development

## Explicitly exclude

Do not yet build:

- sophisticated editing workflows
- full document ingestion
- AI
- semantic search
- external research
- material-selection decision engine
- advanced graph visualization

## Dependencies

- Phase 1 UI shell
- Phase 0 architecture

## Codex execution guidance

Codex should:

1. review existing architecture
2. propose the schema before major implementation
3. record major modeling decisions
4. implement SQLite storage
5. implement Swift domain models
6. implement repository/data-access layer
7. seed a small set of representative engineering records
8. connect read-only sample UI to the data
9. add database tests
10. verify application build

## Acceptance criteria

At minimum the system should be able to store and retrieve:

- one material
- one damage mechanism
- one standard
- one component
- one source
- multiple claims
- relationships among them

The application should demonstrate something such as:

```text
Alloy 725
  ↳ related mechanism: Hydrogen Embrittlement
  ↳ related standard: ISO 15156
  ↳ supported by source X
```

## Deliverables

- SQLite schema
- migrations
- domain models
- repository layer
- initial engineering seed dataset
- tests

## Testing

- create/read/update/delete at repository level
- relationship integrity
- migration test
- database initialization
- duplicate/stable ID behavior where relevant

## Documentation

Update architecture and decisions with:

- entity model
- database schema
- relationship strategy
- claim/source separation
- migration strategy

## What Phase 3 unlocks

The application can now become an actual knowledge-authoring system.

---

# Phase 3 — Knowledge Management

## Objective

Allow the user to create, edit, verify, organize, and connect engineering knowledge directly inside the application.

## Why this phase exists

The database should become useful even before AI exists.

The user must be able to build the knowledge base manually and maintain control over engineering facts.

## Scope

Create full knowledge-management workflows for:

- Materials
- Damage Mechanisms
- Standards
- Components
- Claims
- Sources
- Relationships

## Key functionality

### Create and edit records

Users should be able to:

- create a new material
- edit material details
- create mechanisms
- add standards
- add components
- create individual claims
- attach sources
- create relationships

### Verification state

Claims should have states such as:

- Draft
- Unverified
- Reviewed
- Verified
- Superseded / Archived where useful

Exact terminology can be refined during implementation.

### Source traceability

Every important claim should be able to point to its evidence.

### Relationship management

The user should be able to connect:

- material ↔ mechanism
- material ↔ standard
- material ↔ component
- mechanism ↔ standard
- claim ↔ source
- component ↔ material
- other useful engineering relationships

## User-visible result

The user can manually build a complete mini knowledge base.

Example:

1. Create `Alloy 725`.
2. Create `Hydrogen Embrittlement`.
3. Add `ISO 15156`.
4. Add a technical source.
5. Add an engineering claim.
6. Connect the claim to the material/mechanism/source.
7. Mark it reviewed or verified.

## Technical components

- forms/editors
- repository write operations
- validation
- relationship picker
- source picker
- verification states
- change tracking metadata
- deletion/archive handling

## Include

- CRUD UI
- sensible form validation
- edit sheets/windows/inspectors
- relationship management
- source management
- claim verification
- duplicate warnings where straightforward
- confirmation for destructive actions

## Explicitly exclude

Do not yet implement:

- AI-generated claims
- external research ingestion
- semantic/vector search
- automated material selection
- knowledge graph visualization
- mobile sync

## Dependencies

Phase 2 data model complete.

## Codex execution guidance

Codex should prioritize usability and data integrity.

Avoid building highly complex forms.

Engineering records should be efficient to edit on a Mac.

## Acceptance criteria

User can:

- create a material
- edit it
- create a mechanism
- create a source
- add a claim
- link claim to source
- create relationships
- verify/review a claim
- reopen app and see persistent data

No data should disappear after restart.

## Deliverables

- complete knowledge management UI
- persistence
- verification workflow
- relationship editor
- source editor

## Testing

- all CRUD paths
- persistence after relaunch
- delete/archive handling
- validation
- relationship creation/removal
- source linkage

## Documentation

Record:

- verification workflow
- record lifecycle
- deletion/archive strategy
- relationship editing behavior

## What Phase 4 unlocks

Once knowledge can be created reliably, the next requirement is fast local retrieval.

---

# Phase 4 — Local Search & Document Library

## Objective

Make the knowledge base immediately searchable offline and introduce a structured local technical-document library.

## Why this phase exists

A knowledge system is only useful if information can be found quickly.

This phase should already provide strong value without AI.

## Search architecture

Start with:

- SQLite FTS5
- structured field filters
- tags/categories
- relationship-aware navigation

Do not overcomplicate V1 with vector databases unless a clear need emerges.

## Global search

Search should be able to find:

- materials
- damage mechanisms
- standards
- components
- claims
- sources
- document metadata

Potential search:

> `725 hydrogen H2S`

should return relevant:

- Alloy 725 material record
- hydrogen-related claims
- applicable standards
- associated sources

## Filters

Examples:

- entity type
- material family
- source type
- verification status
- standard organization
- mechanism category
- date

## Document Library

Allow the user to register/import local documents such as:

- PDFs
- technical papers
- standards
- vendor documents
- engineering reports
- notes

The application should maintain:

- document metadata
- local file reference
- title
- organization/author
- revision/year
- source type
- associated engineering entities

Avoid copying sensitive files unnecessarily if file references/bookmarks can solve the requirement safely.

## User-visible result

The application becomes a useful offline engineering reference tool.

The user can search the entire knowledge base without internet or AI.

## Technical components

- SQLite FTS5
- indexing
- search query layer
- global search UI
- result ranking
- filters
- file import/reference handling
- document metadata database
- macOS security-scoped bookmarks if required

## Include

- fast full-text search
- search suggestions/history if simple
- result highlighting
- filters
- library screen
- document metadata
- linking documents to sources/materials/mechanisms
- open document from app

## Explicitly exclude

Do not yet add:

- AI Q&A
- semantic embeddings
- automatic PDF fact extraction
- internet research
- CloudKit sync

## Dependencies

Phases 2–3.

## Codex execution guidance

Codex should first make deterministic search excellent.

Search architecture should remain reusable by the later RAG layer.

## Acceptance criteria

- full-text search works offline
- useful results appear quickly
- filters work
- documents can be added to Library
- document metadata persists
- documents can be associated with knowledge records
- selected local documents can be opened
- application remains usable without internet

## Deliverables

- global search
- FTS indexes
- document library
- import/reference workflow
- filters

## Testing

- indexing
- update/delete reindex behavior
- representative engineering queries
- file permissions after restart
- missing/moved file handling

## Documentation

Document:

- FTS architecture
- ranking behavior
- document storage/reference strategy
- file-permission strategy

## What Phase 5 unlocks

The deterministic local search layer now becomes the retrieval engine for local AI.

---

# Phase 5 — Local AI and RAG

## Objective

Allow the user to ask natural-language engineering questions and receive answers generated locally from the existing knowledge base.

## Why this phase exists

This is where the application changes from a searchable reference database into an intelligent engineering assistant.

## Core principle

The AI should not answer engineering questions from unsupported model memory when the application is expected to answer from the user's knowledge base.

The normal flow should be:

```text
Question
  ↓
Classify intent
  ↓
Search local knowledge
  ↓
Retrieve relevant claims/sources
  ↓
Construct controlled context
  ↓
Local AI reasoning
  ↓
Answer
  ↓
Citations / evidence
```

## Local model direction

Prefer Apple's local Foundation Models when suitable.

Keep AI behind an abstraction so other local model providers can be introduced later without redesigning the application.

Example conceptual interface:

```text
AIProvider
  ├── AppleLocalProvider
  ├── FutureCoreAIProvider
  └── FutureOllamaProvider
```

## Ask interface

Provide a main natural-language interface.

Example questions:

- Why is Alloy 725 susceptible to hydrogen embrittlement?
- What degradation mechanisms should I consider for 25Cr duplex?
- Compare Alloy 625 and Alloy 825 using my stored knowledge.
- Which claims in my database discuss SSC in low-alloy steel?
- Show the evidence supporting this environmental limit.

## Evidence display

Every response should distinguish:

- generated explanation
- supporting claims
- sources
- verification status

The user should be able to open the underlying records.

## "Local" status

Clearly indicate when the answer was generated entirely from local information.

Example:

**LOCAL — no internet used**

## Insufficient knowledge

If local information is insufficient, the system should say so.

It should not automatically browse the internet yet.

Example:

> Local knowledge is insufficient to answer this confidently. External research is available in a later workflow.

## Technical components

- local AI provider
- prompt/context builder
- retrieval service
- answer model
- citation mapping
- Ask UI
- tool/function interface for database search
- token/context management

## Include

- local Q&A
- retrieval over structured knowledge
- retrieval over indexed textual content where appropriate
- citations
- evidence viewer
- insufficient-evidence handling
- local/offline status

## Explicitly exclude

Do not yet implement:

- automatic internet browsing
- autonomous research
- automatic claim insertion from AI output
- full external-research ingestion
- complex material-selection agent
- mobile

## Dependencies

Phases 2–4.

## Codex execution guidance

Build the smallest reliable RAG loop first.

Prioritize:

- determinism
- source traceability
- compact context
- clear failure when evidence is insufficient

Do not optimize prematurely for enormous document collections.

## Acceptance criteria

Given stored knowledge about Alloy 725, the user can ask:

> Why is Alloy 725 susceptible to hydrogen-related damage?

The application should:

- retrieve relevant stored claims
- use the local model
- generate a useful explanation
- cite supporting knowledge
- show underlying source records
- operate without internet

## Deliverables

- Ask interface
- AI abstraction
- local provider
- RAG pipeline
- citation/evidence display
- local status indicator

## Testing

- known-answer test cases
- unsupported-question behavior
- citation correctness
- offline behavior
- prompt injection resistance from stored documents where relevant
- context-size handling

## Documentation

Document:

- AI provider abstraction
- retrieval flow
- prompt/context strategy
- evidence requirements
- known limitations

## What Phase 6 unlocks

The application can now reason from existing knowledge. The next step is allowing new externally researched knowledge to enter the system safely.

---

# Phase 6 — Research Ingestion

## Objective

Create the controlled workflow that allows external research to become permanent local engineering knowledge.

## Why this phase exists

This is the key compounding mechanism of the entire product.

The system should be able to learn a topic once and reuse that knowledge locally forever.

## Intended workflow

```text
User asks a new question
      ↓
Local knowledge check
      ↓
Knowledge insufficient
      ↓
User intentionally starts Research
      ↓
External research performed
      ↓
Structured research package produced
      ↓
Local ingestion
      ↓
Claims extracted
      ↓
Entities identified
      ↓
Relationships proposed
      ↓
Duplicates/conflicts identified
      ↓
User reviews
      ↓
Approved knowledge written to DB
      ↓
Search indexes updated
      ↓
Knowledge available locally
```

## Research-package concept

External research should preferably arrive in a structured format.

Potential fields:

- topic
- summary
- claims
- entities
- materials
- mechanisms
- standards
- components
- conditions
- sources
- document title
- publication
- revision/year
- URL
- page/section
- confidence
- notes

JSON can be used as the interchange format.

## Example

Research topic:

**UNS N07725 / Alloy 725**

Research package may contain:

- metallurgy
- precipitation hardening
- heat treatment
- mechanical behavior
- hydrogen susceptibility
- SSC behavior
- H2S service considerations
- manufacturing controls
- applicable standards
- oil & gas applications
- cited sources

The local application should propose where each piece belongs.

## Review workflow

Nothing should automatically become verified engineering knowledge.

The app should show:

- New claim
- Existing matching claim
- Possible duplicate
- Possible contradiction
- New relationship
- New entity
- Existing entity match

Actions could include:

- Accept
- Reject
- Edit
- Merge
- Mark Unverified
- Verify later

## Local processing

Once the external research package is downloaded/imported, processing should preferably happen locally.

Local AI can:

- classify
- extract
- normalize
- map names
- identify duplicates
- suggest relationships
- generate tags

## Research boundary

Restricted/internal knowledge should not be automatically sent to external research systems.

The system should eventually support a clear separation between:

- public/personal research knowledge
- restricted work knowledge

## User-visible result

The user can research a new topic once, review the extracted information, and permanently add useful engineering knowledge to the local database.

## Technical components

- research package schema
- JSON import
- ingestion parser
- entity resolution
- duplicate detection
- conflict detection
- staging area
- review UI
- database commit transaction
- audit trail

## Include

- structured import
- staged proposed changes
- deduplication
- claim comparison
- source preservation
- relationship suggestions
- review/approval interface
- ingestion history
- rollback/cancel before commit

## Explicitly exclude

Unless separately approved, do not yet build a fully autonomous web-browsing agent inside the app.

The initial version may use ChatGPT/Astra externally and import its structured output.

Also exclude:

- automatic verification
- unattended database modification
- autonomous modification of restricted work knowledge

## Dependencies

Phases 2–5.

## Codex execution guidance

Treat ingestion as a data-integrity problem, not just an AI feature.

Use a staging layer.

Nothing from research should directly modify verified production records before review.

## Acceptance criteria

The user can:

1. import a research package about a new material
2. see proposed entities/claims/sources/relationships
3. identify duplicates
4. accept/reject individual items
5. commit approved knowledge
6. search the new knowledge
7. ask the local AI about it
8. receive a locally generated answer using the newly stored information

## Deliverables

- research interchange schema
- importer
- staging database/model
- review UI
- merge/deduplication workflow
- audit trail

## Testing

- valid/invalid package handling
- duplicate claims
- conflicting claims
- duplicate material names
- source preservation
- partial approval
- cancel/rollback
- ingestion followed by search/RAG

## Documentation

Document:

- package schema
- ingestion lifecycle
- review states
- merge logic
- conflict policy
- public/restricted knowledge boundaries

## What Phase 7 unlocks

The system now has enough structured, growing knowledge to support sophisticated relationship-based exploration.

---

# Phase 7 — Knowledge Graph & Engineering Intelligence

## Objective

Make relationships between engineering concepts visible and useful for exploration and reasoning.

## Why this phase exists

Expertise is largely about understanding relationships.

For example:

```text
Alloy 725
 → precipitation hardening
 → high strength
 → hydrogen susceptibility
 → H2S environment
 → qualification requirements
```

The application should make those connections discoverable.

## Scope

Develop:

- graph/query layer over existing relationships
- relationship explorer
- cross-navigation
- engineering comparison views
- "Why?" exploration
- potentially a visual graph where it genuinely helps

## Important principle

The graph should be built from existing structured data.

Do not create a second parallel knowledge database.

## Example exploration

Open:

**22Cr Duplex**

See:

- composition
- heat treatment
- microstructure
- associated mechanisms
- relevant standards
- applicable components
- tests
- sources
- related case histories

Open:

**Hydrogen Embrittlement**

See:

- susceptible materials
- environmental sources of hydrogen
- controlling factors
- relevant standards
- tests
- related failures

## "Why?" mode

For a claim or engineering limit, allow the user to explore:

1. the claim
2. underlying mechanism
3. contributing metallurgy
4. associated evidence
5. applicable standard
6. related materials/components

## Engineering comparison

Examples:

- Alloy 718 vs 725
- 22Cr vs 25Cr
- L80 vs P110
- 13Cr vs Super 13Cr

The comparison should primarily use structured local knowledge.

## User-visible result

The application feels less like a database and more like a connected engineering knowledge system.

## Technical components

- relationship query service
- graph traversal
- related-content ranking
- comparison engine
- graph/list/tree views
- breadcrumb/cross-navigation
- optional visual graph component

## Include

- first- and multi-hop relationship queries
- related-record panels
- comparison views
- "Why?" pathway
- provenance display
- graph browsing where useful

## Explicitly exclude

Do not turn the entire application into an uncontrolled visual graph.

Do not create an AI-generated graph without source traceability.

Do not yet implement full engineering decision automation.

## Dependencies

Phases 2–6.

## Codex execution guidance

Prioritize useful engineering navigation over visual spectacle.

Every graph edge should correspond to a real stored relationship or derived relationship with provenance.

## Acceptance criteria

The user can start from a material and navigate to:

- mechanisms
- standards
- sources
- components

and start from a mechanism and navigate back to relevant materials.

A comparison view should combine stored properties, claims, and evidence.

## Deliverables

- relationship explorer
- graph traversal service
- comparison framework
- "Why?" mode
- improved cross-navigation

## Testing

- traversal correctness
- cycles
- missing relationships
- provenance
- comparison consistency
- performance on larger datasets

## Documentation

Document:

- graph semantics
- supported relationship types
- derived relationship rules
- traversal limits
- visualization architecture

## What Phase 8 unlocks

The connected knowledge base can now power specific engineering workflows.

---

# Phase 8 — Engineering Tools

## Objective

Convert the knowledge platform into practical engineering decision-support tools.

## Why this phase exists

The purpose of the product is not only to store knowledge.

It should eventually help perform real materials-engineering work.

## Initial tool families

Develop each as a separate workflow while using the same shared knowledge base.

### 8.1 Material Selection

Inputs may include:

- component
- temperature
- pressure
- CO2
- H2S
- chloride
- pH
- water
- expected life
- stress
- production chemistry
- completion/workover fluids
- cathodic protection
- erosion/sand
- other environmental factors

Potential output:

- relevant degradation mechanisms
- candidate materials
- advantages
- limitations
- data gaps
- standards to review
- supporting evidence
- rejected options and reason
- confidence/evidence status

The tool must not pretend to replace engineering judgment.

It should show how it reached the result.

### 8.2 Degradation Assessment

Input:

- material
- environment
- component
- operating conditions

Output:

- applicable damage mechanisms
- likelihood/relevance
- controlling variables
- evidence
- prevention/mitigation considerations
- data gaps

### 8.3 Vendor Qualification

Capture:

- vendor
- facility
- product
- material
- manufacturing route
- heat treatment
- testing
- observations
- findings
- corrective actions
- qualification history

Connect findings to engineering mechanisms.

Example:

```text
Delayed quench
  ↓
intermetallic precipitation risk
  ↓
reduced toughness/corrosion resistance
  ↓
recommended verification
```

### 8.4 Failure / Case Investigation

Structured input:

- component
- material
- environment
- location of damage
- morphology
- hardness
- metallography
- fracture features
- chemistry
- operating history

Output:

- candidate mechanisms
- evidence supporting each
- evidence contradicting each
- additional information required
- applicable standards
- similar stored cases

### 8.5 Fit-for-Purpose

Use structured local knowledge to evaluate deviations or proposed conditions.

The system should distinguish:

- known evidence
- assumptions
- engineering inference
- missing information

## User-visible result

The product starts supporting actual engineering decisions and investigations rather than only knowledge retrieval.

## Technical components

- workflow-specific domain models
- engineering input forms
- reusable reasoning services
- rules/constraints where explicit
- local AI orchestration
- evidence mapping
- report view

## Include

Build tools incrementally.

Recommended order:

1. degradation assessment
2. material comparison/selection
3. vendor qualification
4. case/failure investigation
5. fit-for-purpose

Do not try to build all five simultaneously.

## Explicitly exclude

Avoid hardcoding unsupported engineering limits.

Any explicit rule should have provenance.

Avoid presenting AI conclusions as verified facts.

## Dependencies

Strong knowledge base from Phases 2–7.

## Codex execution guidance

For every engineering workflow:

- define inputs first
- define outputs
- define evidence requirements
- define deterministic calculations/rules separately from AI reasoning
- preserve source traceability
- expose assumptions and missing data

## Acceptance criteria

At least one end-to-end engineering workflow should operate using stored knowledge and produce a traceable assessment.

The result should make it easy to answer:

- What did the system conclude?
- Why?
- Which facts were used?
- Which standards/sources support it?
- What is uncertain?
- What information is missing?

## Deliverables

- engineering workflow framework
- first complete engineering tool
- reusable evidence/reasoning architecture
- exportable/printable assessment view where useful

## Testing

Use representative synthetic engineering cases.

Test:

- missing inputs
- contradictory evidence
- unsupported conditions
- boundary conditions
- source/citation correctness
- reproducibility

## Documentation

Document each tool's:

- scope
- inputs
- output
- assumptions
- evidence model
- limitations
- known non-goals

## What Phase 9 unlocks

Once the Mac product provides real engineering value, it becomes worth carrying the same system on mobile devices.

---

# Phase 9 — iPhone/iPad and Sync

## Objective

Provide portable access to the same Materials Intelligence system while preserving local-first operation.

## Why this phase exists

A materials engineer may need reference access:

- in meetings
- while travelling
- during inspections
- at vendor facilities
- away from the Mac

The iPhone/iPad application should not be a separate product.

It should be another interface to the same engineering model.

## Architecture direction

Reuse:

- domain models
- database concepts
- search logic
- intelligence abstractions where possible
- design language

Adapt UI specifically for:

- iPhone
- iPad

Do not simply shrink the Mac interface.

## Sync

Potential direction:

- CloudKit/private iCloud for permitted personal/public knowledge

Requirements:

- local copy on each device
- offline operation
- synchronization when network is available
- conflict handling
- data-version compatibility
- clear status

Restricted company information may require a different storage/sync policy.

The architecture should support separate vaults if needed.

## Mac role

The Mac remains the primary:

- authoring
- research
- review
- bulk document
- advanced engineering

workstation.

## Mobile role

Mobile emphasizes:

- search
- reading
- Ask
- quick notes
- reference
- review
- lightweight updates

## User-visible result

The user can access their engineering knowledge from Mac, iPhone, and iPad.

The system continues to function when offline.

## Technical components

- iOS/iPadOS target
- shared packages/modules
- adaptive SwiftUI views
- synchronization layer
- CloudKit or approved equivalent
- conflict resolution
- local caching/database

## Include

- mobile navigation
- local search
- material/mechanism pages
- Ask interface where local model availability permits
- sync
- offline behavior
- status/error handling

## Explicitly exclude

Do not duplicate independent databases per platform without a synchronization strategy.

Do not move the primary product to a web server merely to simplify sync.

## Dependencies

Stable Mac application and data model.

## Codex execution guidance

First separate genuinely shared logic from Mac-specific UI.

Then add iPhone/iPad targets.

Do not refactor the entire application unless necessary.

## Acceptance criteria

- same user knowledge can be accessed on supported Apple devices
- mobile works offline after sync
- changes synchronize safely
- conflicts do not silently overwrite data
- Mac remains fully functional without mobile

## Deliverables

- iPhone app
- iPad app
- shared modules
- sync layer
- conflict handling

## Testing

- fresh install
- offline launch
- two-device edits
- sync conflicts
- deletion/archiving
- large knowledge base
- migration between schema versions

## Documentation

Document:

- shared-code architecture
- sync model
- conflict rules
- restricted-data policy
- mobile limitations

## What Phase 10 unlocks

With mature knowledge, engineering tools, and portable access, the application can become a higher-level engineering agent.

---

# Phase 10 — Advanced Engineering Agent

## Objective

Create a multi-step engineering agent that can locally combine knowledge, tools, calculations, and evidence to solve structured materials-engineering problems.

## Why this phase exists

A chatbot answers questions.

An engineering agent can:

- understand the task
- determine which information is required
- retrieve evidence
- call deterministic tools
- compare alternatives
- identify missing data
- build an assessment
- preserve traceability

This is the final major evolution of the product.

## Conceptual workflow

Example user request:

> Assess material options for tubing at 120°C with high chloride, CO2, trace H2S, and a 20-year design life.

Possible internal workflow:

```text
Interpret request
     ↓
Identify missing input
     ↓
Retrieve environment knowledge
     ↓
Identify applicable mechanisms
     ↓
Retrieve candidate materials
     ↓
Check stored standard requirements
     ↓
Use engineering calculators/rules
     ↓
Compare candidate materials
     ↓
Identify uncertainties
     ↓
Generate structured recommendation
     ↓
Show evidence and assumptions
```

## Agent tools

Potential local tools:

- material search
- mechanism search
- standards lookup
- claim retrieval
- source lookup
- environment assessment
- unit conversion
- corrosion calculations
- material comparison
- qualification history search
- similar-case search
- knowledge-graph traversal
- document retrieval

## Agent behavior

The agent should:

- plan internally
- use tools rather than hallucinate
- show user-facing reasoning summaries, not hidden model chain-of-thought
- cite engineering evidence
- separate fact from inference
- state missing information
- identify assumptions
- stop when evidence is insufficient
- ask for external research only when required

## Local vs Research mode

The application should clearly distinguish:

### LOCAL

Uses:

- local database
- local documents
- local AI
- deterministic engineering tools

No internet.

### RESEARCH

Used intentionally when:

- local knowledge is insufficient
- user requests new research

Research output should still pass through Phase 6 review/ingestion before becoming verified knowledge.

## Potential advanced workflows

- material selection
- sour-service assessment
- corrosion mechanism screening
- FFP assessment
- manufacturing deviation review
- vendor qualification review
- test-plan development
- failure investigation
- technical query drafting
- engineering comparison
- gap analysis

## User-visible result

The user can describe an engineering problem in natural language and receive a structured, evidence-backed engineering assessment assembled from the complete local knowledge ecosystem.

## Technical components

- agent orchestrator
- tool registry
- task planner
- retrieval
- deterministic calculators
- workflow state
- evidence model
- local LLM
- optional research gateway
- audit/history

## Include

- limited, explicit toolset
- structured outputs
- reproducible evidence
- assumptions
- source citations
- task history
- user control before external research or sensitive operations

## Explicitly exclude

Do not create an uncontrolled autonomous agent that:

- changes verified engineering data without review
- uploads restricted information externally
- silently uses internet
- fabricates standards requirements
- hides its evidence
- performs destructive operations without user control

## Dependencies

All earlier phases should be mature enough that the agent is orchestrating reliable tools rather than compensating for missing architecture.

## Codex execution guidance

Implement one agent workflow first.

Do not start with "general autonomous materials engineer."

Recommended first workflow:

**Evidence-backed degradation assessment**

Then progressively add tools.

## Acceptance criteria

For a representative engineering case, the agent should:

- identify the task
- retrieve relevant materials knowledge
- identify applicable mechanisms
- retrieve relevant standards/claims
- use required tools
- state assumptions
- identify missing data
- generate structured conclusions
- show supporting sources
- remain functional offline where knowledge exists

## Deliverables

- agent orchestration framework
- tool registry
- first mature agent workflow
- evidence/audit trail
- Local vs Research mode

## Testing

Create a suite of benchmark engineering cases.

Assess:

- retrieval quality
- correct tool selection
- source correctness
- hallucination rate
- missing-data behavior
- contradictory-evidence behavior
- offline operation
- reproducibility

## Documentation

Document:

- available tools
- tool contracts
- agent boundaries
- local/research policies
- safety/data rules
- known limitations
- benchmark cases

## Final outcome

At the end of Phase 10, Materials Intelligence has evolved from a simple Mac application into a personal engineering intelligence system that:

- stores structured materials knowledge
- keeps source traceability
- works primarily offline
- searches locally
- answers using local AI
- grows through controlled research
- connects engineering concepts
- supports real engineering workflows
- operates across Apple devices
- performs multi-step evidence-backed engineering reasoning

---

# 6. Expected Product Evolution

## After Phase 0

You have a stable project foundation.

## After Phase 1

You have a professional native Mac application shell.

## After Phase 2

The application understands structured engineering entities.

## After Phase 3

You can manually build and maintain your materials knowledge base.

## After Phase 4

It becomes a useful offline engineering reference system.

## After Phase 5

It becomes a local engineering Q&A assistant.

## After Phase 6

Its knowledge can permanently grow from new research.

**This is the core proof of the complete concept.**

## After Phase 7

It becomes a connected engineering knowledge system.

## After Phase 8

It becomes a practical engineering decision-support platform.

## After Phase 9

It becomes available across Mac, iPhone, and iPad.

## After Phase 10

It becomes a multi-step personal materials-engineering agent.

---

# 7. Recommended Development Discipline

For every phase:

1. Start from a clean Git checkpoint.
2. Give Codex only the current phase.
3. Make Codex read:
   - `AGENTS.md`
   - `ARCHITECTURE.md`
   - `CURRENT_STATE.md`
   - `MILESTONE.md`
   - `DECISIONS.md`
4. Tell Codex not to implement later phases.
5. Prefer the smallest complete implementation.
6. Require successful build before completion.
7. Run appropriate tests.
8. Manually inspect the feature.
9. Update documentation.
10. Commit the milestone.
11. Only then move to the next phase.

---

# 8. Template to Use When Requesting a Codex Prompt From ChatGPT

When ready for a phase, copy the full phase section from this document and use a request like:

```text
I am building my Materials Intelligence native macOS application.

Below is the definition for the next development phase.

I want you to convert this into one complete, detailed Codex execution prompt.

Requirements for the Codex prompt:

- Treat the supplied phase as the only implementation scope.
- Preserve the existing native SwiftUI architecture.
- Tell Codex to inspect AGENTS.md, ARCHITECTURE.md, CURRENT_STATE.md,
  MILESTONE.md and DECISIONS.md before making changes.
- Do not implement functionality belonging to later phases.
- Require Codex to keep the project buildable.
- Require appropriate tests for this phase.
- Require documentation updates at completion.
- Require a Git checkpoint.
- Include the 10%-remaining-usage milestone protection rule.
- Make the prompt specific enough that I can paste it directly into Codex.
- Do not ask me unnecessary questions if the existing project documentation can answer them.

Here is the phase definition:

[PASTE PHASE HERE]
```

If possible, also provide the latest contents of:

- `CURRENT_STATE.md`
- `MILESTONE.md`

This lets ChatGPT generate a prompt based on what actually exists rather than only the original roadmap.

---

# 9. Important Milestone

The most important proof point is **Phase 6**.

At that point the system should be able to:

1. contain structured engineering knowledge
2. search it locally
3. answer questions locally
4. identify insufficient knowledge
5. accept an externally researched package
6. extract proposed claims and relationships
7. let the user review them
8. permanently store approved knowledge
9. answer the same topic locally in the future

Once this works reliably, the central concept of Materials Intelligence has been proven.

Everything after Phase 6 builds additional engineering capability on top of that foundation.
