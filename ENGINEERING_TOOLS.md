# Phase 8 — degradation screening

A complete conservative screening workflow, not a corrosion calculator or material approval system. Engineering Tools accepts stored material/component, environment, temperature in °C, pressure in MPa and user context. Assess captures a report snapshot; Share exports plain text. The report preserves conditions, sources, claim IDs/status, rule results, assumptions and gaps. Why opens the Phase 7 explorer. AI explanation is optional, local and labelled unverified inference; exact citation validation reuses LocalRAG.

## Explicit rules

Author a source-backed claim using the existing Claims editor (or Phase 6 reviewed package), predicate `assessment_rule`. Its notes contain JSON:

```json
{"version":1,"mechanismID":"existing-mechanism-id","environment":"exact scope name","temperatureMinC":10,"temperatureMaxC":20,"pressureMinMPa":1,"pressureMaxMPa":2,"outcome":"relevant","mitigation":"Synthetic example only"}
```

These numbers are SYNTHETIC test data, not engineering guidance. Optional bounds and mitigation may be omitted. Outcome is `relevant` or `excluded`. Rules must be Reviewed/Verified before execution, reference an existing mechanism and attach to the selected material or component. Existing claim review remains responsible for verifying that the rule accurately transcribes its cited source. No automatic extraction of engineering thresholds from prose occurs.

The environment matches exactly, ignoring case/outer whitespace. Bounds are inclusive; missing bounded input, invalid rules, unreviewed claims and out-of-scope conditions cannot match. Pressure must be finite/nonnegative; temperature finite. A rule with no numeric bounds makes no numeric condition assertion. Opposite matching outcomes flag a conflict and prevent an unqualified conclusion. Exclusion is limited to the rule scope, never a safety approval.

Direct stored relationships and explicit scoped rules identify candidate mechanisms. Their source-backed claims and direct material/component/mechanism standard references remain inspectable. Unverified evidence is visible but cannot execute a rule or enter AI context. Archived/superseded evidence is excluded. Unsupported conditions produce unresolved relevance, not a model-generated risk rating. Narrative contradictions, semantic environment equivalence, quantitative likelihood, kinetics, unit normalization beyond the fixed form units, vendor qualification, selection and FFP are non-goals. User notes are assumptions, not deterministic rule inputs. AI cannot alter assessment results or stored knowledge.

## Verification

KnowledgeStore, LocalRAG, ResearchIngestion, KnowledgeGraph and DegradationAssessment tests pass. Synthetic end-to-end case covers matching inclusive boundaries, outside/missing conditions, unsupported environments, opposing rules, unverified rule rejection, source locators, repeatability, invalid pressure and generated citation rejection. Release Mac build and app process launch pass. GUI screenshot failed because the display cannot be captured; visual interaction and actual on-device generation remain UNVERIFIED.

Manual: create a synthetic material, component, source and mechanism; add the synthetic rule above with its actual mechanism ID, mark Reviewed; assess at 10°C/2MPa and then outside scope; inspect evidence/Why, export text, and request optional local explanation on a model-ready device. Do not promote synthetic data as real engineering knowledge.
