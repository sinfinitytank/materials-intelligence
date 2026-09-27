# Phase 10 — controlled local engineering agent

Engineering Agent runs one explicitly selected, bounded workflow: degradation assessment, material comparison, vendor qualification, failure investigation, or fit-for-purpose evidence review. It uses structured form inputs; natural-language task prose never silently overrides operating values. The agent does not choose arbitrary tools or manufacture engineering conclusions.

## Tool contracts

- `recordLookup`: resolves selected stable IDs; degradation may resolve one unique exact stored material/component name from the task.
- `localSearch`: existing SQLite FTS context retrieval; lexical hits are not evidence conclusions.
- `graphTraversal`: existing depth-2/100-result snapshot traversal; original relationship and claim provenance remain intact.
- `claimAndSourceRetrieval`: retrieves active claims with their subjects, sources, locators, review states, and conditions.
- `degradationAssessment`: Phase 8 deterministic, source-backed scoped rules.
- `materialComparison`: groups candidate materials' local claims and may apply an explicitly reviewed exact-scope selection rule.
- `vendorQualification`: records submitted manufacturing/inspection history and local evidence without issuing approval.
- `failureInvestigation`: organizes observations, candidate mechanisms, and local evidence without diagnosing cause.
- `fitForPurpose`: compares submitted key/value text with explicit Reviewed/Verified source-backed requirements in exact service scope; it does not issue compliance approval.
- `localExplanation`: optional Apple on-device provider and citation parser; unavailable/invalid generation preserves deterministic output.
- `researchHandoff`: deliberate Research mode creates a brief only. No network retrieval or automatic ingestion.

The tool sequence is fixed. No arbitrary model-selected functions, shell, internet, knowledge mutation, or fabricated calculator exists. Only high-level tool summaries, evidence, and results are shown, never hidden chain-of-thought.

## Local/research boundary

Local execution makes no CloudKit or networking call and remains functional without a model. Ask/explanation uses only Apple on-device Foundation Models. AI text is separately labelled unverified inference; cited IDs must resolve to retrieved evidence, but that does not prove semantic support.

Research mode never silently browses. Export the brief only deliberately and without restricted information. External findings must be imported using Phase 6 schema-v1 staging, review, and commit. Imported claims remain Unverified and require explicit review. Agent execution never calls knowledge mutation or research commit APIs.

## Audit and storage

Schema 6 adds `agent_runs` snapshots to the existing SQLite repository. A started run is written before work; final state contains workflow, only that workflow's structured input JSON, mode, timestamp, bounded tool summaries, report/evidence text, claim IDs, and optional explanation. Inputs retained in another form while switching workflows are omitted from the audit snapshot. A failed or interrupted process may leave a `started` entry; rerun explicitly. The UI displays up to the latest 100 runs. History is local and excluded from personal-vault synchronization because tasks may contain restricted context. Reports snapshot evidence text while links resolve current records and may become unavailable after explicit edits/deletion.

New optional workflow/input fields decode older schema-6 history records safely. No new database migration is needed.

## Benchmark and verification boundary

Nine established agent benchmark runs exercise degradation tool selection, source/locator/standard retrieval, repeatability, missing inputs, unsupported tasks, unavailable local model, fabricated citation rejection, research handoff, contradictory rules, unsupported conditions, and knowledge immutability. `EngineeringWorkflowTests` covers all Phase 8 workflows, source traceability, scoped rules, structured audit persistence, legacy history decoding, size limits, and no knowledge mutation. No network adapter is used by the deterministic agent.

These benchmarks measure structural correctness and deterministic behavior, not a zero hallucination rate or scientific validation. Real on-device generation, visual GUI review, and mobile/iCloud runtime checks remain environment-dependent; see `MANUAL_ACCEPTANCE_REMAINING.md`.

Manual: use only synthetic test data. Open Engineering Agent, select each workflow, enter its structured fields, inspect tool/evidence history and gaps, export a report, and reopen its audit entry. Switch to Research mode and verify only a brief is produced, then import any obtained package through Research review. Do not treat synthetic data as verified real-world engineering knowledge.

Non-goals: autonomous general engineering, semantic contradiction detection, parsing arbitrary numbers from task prose, quantitative corrosion prediction, web research, automatic verified-knowledge changes, and arbitrary tool execution.
