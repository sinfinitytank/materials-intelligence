# Materials Intelligence — User Guide

Materials Intelligence is a local-first macOS app for organizing materials, mechanisms, standards, components, sources, claims, relationships, and research notes.

Use it as a structured research notebook. It is not an engineering approval system, a standards database, or a replacement for qualified review.

## Start the app

1. Open `Materials Intelligence.app`.
2. If macOS blocks the first launch, Control-click the app, choose **Open**, then confirm.
3. The app opens the local workspace. Your main knowledge database remains on this Mac.

The app does not require an iCloud account for normal local use.

## Main workspace

Use the sidebar to open:

- **Overview** — starting point and workspace summary.
- **Materials**, **Damage Mechanisms**, **Standards**, **Components**, and **Sources** — create and maintain structured records.
- **Claims** — record statements together with their source, locator, conditions, evidence level, and review status.
- **Relationships** — connect records with explicit predicates and optional supporting claims.
- **Search** — search stored records, claims, and documents.
- **Library** — associate local files with records. Files and bookmarks remain device-local.
- **Research** — import and review versioned JSON research packages before committing them.
- **Explorer** — follow stored relationships and inspect Why paths.
- **Engineering Tools** — run the bounded degradation-screening workflow against stored rules.
- **Engineering Agent** — run the controlled local workflow, inspect evidence and gaps, and save an audit history.
- **Personal Vault** — work with the separate personal/public vault intended for explicit sync.

## Recommended working pattern

1. Create or find the relevant records.
2. Add the source before creating a claim.
3. Write claims as narrow, source-backed statements.
4. Leave new claims **Unverified** until you check the source yourself.
5. Add conditions, locator information, and evidence level.
6. Use **Reviewed** or **Verified** only when your review standard has been met.
7. Explore relationships and search results to check the surrounding context.
8. Keep restricted or confidential work in the main local vault.

Claims supplied to Ask are limited by their review status. The local model, when available, is an explanation aid; its output remains unverified inference and must be checked against the cited evidence.

## Demo case: synthetic hydrogen-damage knowledge chain

This case is deliberately fictional and synthetic. Use it to learn the workflow; do not treat any statement below as real materials-engineering data.

### Create the records

Create these five records:

| Type | Name | Notes/detail |
|---|---|---|
| Material | `DEMO-ALLOY-001` | Synthetic demonstration material |
| Damage Mechanism | `DEMO-MECHANISM-HYDROGEN` | Synthetic demonstration mechanism |
| Standard | `DEMO-STANDARD-001` | Synthetic demonstration standard |
| Component | `DEMO-COMPONENT-VALVE` | Synthetic demonstration component |
| Source | `DEMO-SOURCE-NOTE-001` | Synthetic source created only for app testing |

Open **Materials**, **Damage Mechanisms**, **Standards**, **Components**, and **Sources** from the sidebar and use the add control on each page.

### Add a claim

Open **Claims** and add this claim:

- Subject: `DEMO-ALLOY-001`
- Predicate: `susceptibility_example`
- Statement: `Synthetic example: DEMO-ALLOY-001 is used to demonstrate a hydrogen-damage evidence link.`
- Conditions: `Synthetic test condition only`
- Source: `DEMO-SOURCE-NOTE-001`
- Locator: `demo-section-1`
- Evidence level: `Synthetic fixture`
- Status: **Unverified**

Leave it Unverified. This demonstrates the normal safe starting state for newly entered knowledge.

### Add relationships

Open **Relationships** and add:

1. `DEMO-ALLOY-001` — `susceptible_to` → `DEMO-MECHANISM-HYDROGEN`
2. `DEMO-MECHANISM-HYDROGEN` — `context_for` → `DEMO-STANDARD-001`
3. `DEMO-COMPONENT-VALVE` — `uses_material` → `DEMO-ALLOY-001`

Use the claim as supporting evidence for the first relationship if the form offers that option. Do not invent additional claims.

### Explore the result

1. Open **Explorer**.
2. Select `DEMO-ALLOY-001`.
3. Expand the relationship path to the mechanism and standard.
4. Open the source or claim from the path.
5. Use **Why** on the claim to inspect its stored evidence path.
6. Use **Search** for `DEMO-ALLOY-001` and confirm the claim and related records appear.

### Optional local tools test

Open **Engineering Tools** and use the synthetic records only. If the app reports missing inputs or unsupported conditions, that is expected behavior for data without a complete stored rule set.

Open **Engineering Agent** and run a small synthetic request. Inspect the selected tools, evidence IDs, gaps, and saved history. Do not mark the output as engineering advice.

## Personal Vault and Sync

**Personal Vault** uses a separate `personal-public.sqlite` database. It is not an automatic copy of the main local workspace.

The Reference, Ask, Sync, and Mac-only review tabs are separate workflows. The Sync tab is for explicit private iCloud synchronization and requires an Apple developer team, entitlements, CloudKit configuration, and an available iCloud account. Without those, use the vault locally and expect sync to remain unavailable.

Files, bookmarks, restricted material, and the main local database do not automatically move into the personal/public vault.

## Important limitations

- Search is lexical and metadata-based; it is not a semantic database.
- Stored properties are narrative rather than a normalized materials-property system.
- New and imported claims require deliberate review.
- The Apple on-device model may be unavailable on a particular Mac.
- CloudKit sync cannot be verified without the required signing and account setup.
- Synthetic demo data is for testing the interface only.
