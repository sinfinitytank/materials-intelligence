# Phase 10 — controlled local degradation agent

Engineering Agent accepts a short natural-language degradation/corrosion/damage/cracking request and structured operating conditions. It resolves one exact stored material/component name when a picker is blank; ambiguity remains missing. Structured inputs control environment, temperature and pressure. It does not infer numbers or chemistry from prose. Tasks outside this bounded workflow stop without an engineering conclusion.

## Tool contracts

- `recordLookup`: resolves local stable IDs; no knowledge writes.
- `localSearch`: existing SQLite FTS context retrieval; lexical hits are not evidence conclusions.
- `graphTraversal`: existing depth-2/100-result snapshot traversal; original edge provenance retained.
- `claimAndSourceRetrieval`: active assessment/context claims and their exact sources, locators, states and standard references.
- `degradationAssessment`: existing Phase 8 deterministic rule service, including assumptions, gaps and explicit conflicts.
- `localExplanation`: optional existing on-device provider and citation parser; unavailable/invalid generation preserves deterministic output.
- `researchHandoff`: deliberate Research mode creates a brief only. No network retrieval or automatic ingestion.

This fixed plan is the limited registry. No arbitrary model-selected functions, shell, internet, knowledge mutation or fabricated calculator exists. The agent uses stored rules where available and qualifies unsupported conditions. Only high-level tool summaries, evidence and results are shown, never hidden chain-of-thought.

## Local/research boundary

Local execution has no CloudKit or networking call and remains functional without a model. Ask/explanation uses only Apple on-device Foundation Models. AI text is separately labelled unverified inference, and cited IDs must resolve to retrieved evidence; this does not prove semantic support.

Research mode never silently browses. Export the brief only deliberately and without restricted information. External findings must be imported using Phase 6 schema-v1 staging, review and commit. Imported claims remain Unverified and require explicit review. Agent execution never calls knowledge mutation or research commit APIs.

## Audit and storage

Schema 6 adds `agent_runs` snapshots to the same SQLite repository. A started run is written before work; final state contains request, mode, timestamp, bounded tool summaries, full assessment text/source references, claim IDs and optional explanation. An interrupted process may leave `started`; rerun explicitly. UI shows the latest 100 runs; retained database history is not deleted. History is local and intentionally excluded from personal-vault synchronization because tasks may contain restricted context. Reports snapshot evidence text while Why links resolve current records and may become unavailable after subsequent explicit edits/deletion.

## Benchmark and verification boundary

Nine synthetic runs exercise: normal assessment with exact material/component resolution, expected tool sequence, source/locator/standard retrieval, repeatability, missing inputs, unsupported task, unavailable local model, fabricated citation rejection, research handoff, contradictory rules and unsupported operating conditions. Several checks share a run. Tests verify no knowledge mutation and durable audit across reopen. Prior six suites also run. No network adapter is used by these tests or by the deterministic agent.

These benchmarks measure structural correctness and deterministic behavior, not a zero hallucination rate or scientific validation. The same synthetic end-to-end workflow is executable via `Scripts/test.sh`. Real on-device generation, GUI workflow and mobile/iCloud runtime checks remain UNVERIFIED because of this environment.

Manual: create/import reviewed synthetic rule data using `ENGINEERING_TOOLS.md`; open Engineering Agent, describe degradation and select the material/component/conditions; run with explanation off, inspect gaps, tools and Why citations, export, reopen history; repeat with explanation on using a model-ready device. Switch Research mode and verify only a brief is produced, then import any obtained package through Research review. Do not treat synthetic data as verified real-world engineering knowledge.

Non-goals: autonomous general engineering, semantic contradiction detection, interpreting arbitrary numbers in task prose, material optimization, quantitative corrosion prediction, web research, automatic verified-knowledge changes and arbitrary tool execution.
