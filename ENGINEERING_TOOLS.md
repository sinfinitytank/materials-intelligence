# Phase 8 — local engineering workflows

Engineering Tools provides five local workflows: material comparison, degradation assessment, vendor qualification, failure investigation, and fit-for-purpose evidence review. All reports snapshot their structured inputs and results in local Engineering Agent history and can be exported as text. They reuse the existing SQLite knowledge base, FTS5 search, graph, claim review states, and source links. No second knowledge store or network service is used.

## Material comparison

Select two or more stored materials, a component if relevant, service environment, operating conditions, and design requirements. The report groups source-backed claims by candidate, displays the authored claim category (`selection_advantage`, `selection_limit`, or `selection_exclusion`), includes exact claim status/source/locator/conditions, and lists directly linked standards for review. It does not rank materials or calculate property suitability.

An explicitly reviewed `material_selection_rule` claim can support consideration or identify an exclusion within a narrowly matched scope. Attach a source and locator using the existing Claims workflow. Put this JSON in the claim notes:

```json
{"version":1,"serviceEnvironment":"exact service","operatingConditions":"exact conditions","designRequirements":"exact requirements","outcome":"consider"}
```

`outcome` is `consider` or `exclude`. The three scope strings must match the submitted fields exactly, ignoring case and outer whitespace. Only Reviewed/Verified claims execute. Exclusion is reported for human confirmation and is never a general safety or suitability finding. Opposing matching rules are flagged as conflicting. No rule is inferred from prose.

## Degradation assessment

The form accepts material, component, exact environment scope, temperature in °C, pressure in MPa, and user assumptions. A source-backed claim with predicate `assessment_rule` stores versioned JSON in its notes:

```json
{"version":1,"mechanismID":"existing-mechanism-id","environment":"exact scope name","temperatureMinC":10,"temperatureMaxC":20,"pressureMinMPa":1,"pressureMaxMPa":2,"outcome":"relevant","mitigation":"Synthetic example only"}
```

These numbers are synthetic test data, not engineering guidance. Optional bounds and mitigation may be omitted. Outcome is `relevant` or `excluded`. Rules must be Reviewed/Verified before execution, reference an existing mechanism, and attach to the selected material or component. The environment matches exactly, ignoring case/outer whitespace. Bounds are inclusive; missing bounded input, invalid rules, unreviewed claims, and out-of-scope conditions cannot match. Pressure must be finite/nonnegative; temperature must be finite. Opposite matching outcomes are flagged as conflicts. Exclusion applies only inside the recorded scope and is not a safety approval.

Direct stored relationships and explicit scoped rules identify candidate mechanisms. Unsupported conditions remain unresolved. Narrative contradictions, semantic environment equivalence, quantitative likelihood, kinetics, automatic unit conversion, and engineering-threshold extraction are not implemented.

## Vendor qualification

Capture vendor, facility, product, material, manufacturing route, heat treatment, testing, observations, findings, corrective actions, and qualification history. The report preserves these as user-provided input, retrieves relevant local claims, identifies missing fields, and links every retrieved claim to its source. It does not approve a vendor or infer process compliance. Structured input is retained with the local run history and is excluded from personal-vault sync.

## Failure investigation

Capture component, material, environment, damage location, morphology, hardness, metallography, fracture features, chemistry, operating history, and candidate mechanisms. The report shows direct relationship-based or user-selected mechanisms and matching source-linked local claims. The user may enter observations they consider supportive or contradictory; those remain explicitly user-classified observations. The workflow does not diagnose cause, score likelihood, or automatically interpret morphology. Similar-case search is lexical local context, not a proven analogue.

## Fit-for-purpose evidence review

Capture material, component, intended service, design basis, proposed deviation, acceptance criteria, parameter values, and standards to review. Parameter values use one `key = value` line each. A source-backed `fit_for_purpose_requirement` claim may contain:

```json
{"version":1,"scope":"exact intended service","field":"heat treatment","expected":"solution annealed"}
```

Only Reviewed/Verified claims with an exact intended-service scope are checked. Submitted values are compared as text after trimming outer whitespace and ignoring case. A match, difference, or missing field is shown beside the claim ID; this is a review prompt, not a fit/compliance verdict. Numeric properties, units, code interpretation, and governing-edition selection are not calculated or inferred.

## Shared evidence and AI behavior

Every workflow report distinguishes stored evidence from user input, retains verification state, claim ID, source, locator, and recorded conditions, and lists information gaps. Draft, Unverified, Reviewed, and Verified evidence is visible with its status; only Reviewed/Verified claims may enter an optional local explanation. That explanation is labelled unverified inference, uses the existing exact citation-ID parser, and cannot change the deterministic report or stored knowledge. Without reviewed evidence, the explanation is unavailable.

Assessment runs preserve a JSON snapshot of the structured form and report in schema-6 `agent_runs`. History is local and is not part of personal-vault snapshots. Current results can link to the present record; the saved report remains an immutable text snapshot if a record is later changed or deleted.

## Verification

`Scripts/test.sh` includes deterministic synthetic tests for all five workflows, scoped material-selection and fit-for-purpose rules, missing inputs, evidence status/source locators, audit persistence, legacy history decoding, no knowledge mutation, rule bounds/conflicts, and rejected model citations. Synthetic examples do not validate engineering science. macOS visual interaction, file selection, real Apple model output, and signed CloudKit/device operation are tracked in `MANUAL_ACCEPTANCE_REMAINING.md`.
