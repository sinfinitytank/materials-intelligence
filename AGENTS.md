# Codex instructions

- **Small/local** (UI, spacing, colors, typography, icons, labels, assets, isolated bugs): inspect directly relevant files only; no repo-wide audits or roadmap, phase, history, architecture, database, RAG, research, sync, or unrelated code unless required. Make the smallest safe patch; use targeted validation.
- **Larger/architectural:** inspect relevant code and documents only.
- Preserve native SwiftUI/macOS; prefer simple native solutions and avoid unnecessary dependencies or web runtimes. Do not silently modify verified engineering knowledge; preserve source traceability. Keep the project buildable, update permanent docs after meaningful changes, and record major architecture replacements and reasons in `DECISIONS.md`.
- **Read on demand:** architecture/state → relevant parts of `ARCHITECTURE.md`, `CURRENT_STATE.md`, and `DECISIONS.md`; setup/build/manual checks → `README.md` and linked guides. Scope future features individually; completed phase plans are retained in Git history.
