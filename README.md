# Materials Intelligence

Materials Intelligence is a native macOS workspace for organizing, reviewing, and exploring materials-engineering knowledge.

It is designed for engineers and researchers who need a focused place to keep material records, technical claims, supporting references, and research notes together—so important decisions remain easier to find, understand, and revisit.

> Early development release — the project is actively evolving and is not yet intended for production-critical engineering decisions.

![Materials Intelligence overview](UI-UX%20Sketches/01-overview.png)

## Highlights

- Native macOS experience with a clean, focused workspace
- Structured material and engineering-knowledge records
- Searchable claims, references, and supporting evidence
- Document library for associating local research files with knowledge
- Review-oriented workflows that help distinguish established information from work in progress
- Privacy-conscious, local-first design for research conducted on the desktop
- Guarded local retrieval-augmented Ask workflow using Apple’s on-device model when available

## Screenshots

| Overview | Material profile |
| --- | --- |
| ![Overview](UI-UX%20Sketches/01-overview.png) | ![Material profile](UI-UX%20Sketches/02-material-profile.png) |

| Local workspace | Document library |
| --- | --- |
| ![Local workspace](UI-UX%20Sketches/03-local-ask.png) | ![Document library](UI-UX%20Sketches/04-document-library.png) |

## Requirements

- macOS 26 or later
- Xcode 27 or later
- Mac supported by the selected macOS SDK

## Getting started

1. Clone the repository.
2. Open `MaterialsIntelligence.xcodeproj` in Xcode.
3. Select the `MaterialsIntelligence` scheme.
4. Choose a Mac destination and run the application.

The repository includes illustrative sample content so the workspace can be explored immediately. Treat sample information as demonstration content, not as engineering guidance or a substitute for qualified review.

## Current verification

The current Phase 5 implementation has passed the repository’s deterministic tests and a Release arm64 build. Ask uses local SQLite/FTS5 retrieval and only supplies Reviewed or Verified claims to the on-device model; it has no cloud fallback, network service, embeddings index, or third-party runtime. Actual Apple model generation and full visual/interactive GUI review remain dependent on the local Mac’s model availability and manual verification.

To run the deterministic test suite from the repository root:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./Scripts/test.sh
```

For normal development, open `MaterialsIntelligence.xcodeproj` in Xcode and run the `MaterialsIntelligence` scheme on a Mac running macOS 26 or later.

## Project status

Materials Intelligence is being developed in public. Core workspace, knowledge-management, search, document-library, and review foundations are available today. Additional refinement, accessibility review, and broader workflow coverage are ongoing.

The project deliberately favors clear, reviewable engineering information and a dependable native desktop experience. Capabilities may change between releases while the product is being shaped.

## Contributing

Issues and pull requests are welcome. Before contributing:

- Keep changes focused and explain the user benefit.
- Preserve the native SwiftUI/macOS direction.
- Do not add unverified engineering claims or remove source context.
- Update documentation when a user-visible capability or project decision changes.
- Avoid committing credentials, private research files, generated build products, or personal Xcode data.

For substantial changes, please open an issue first so the intended scope can be discussed.

## License

Copyright © 2026 Siddharth Tank.

Materials Intelligence is released under the [MIT License](LICENSE). See the license file for the complete terms.

## Author

Created and maintained by [Siddharth Tank](https://github.com/sinfinitytank).
