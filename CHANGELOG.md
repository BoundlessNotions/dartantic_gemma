# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.4] - 2026-04-30
- Added handling of Gemma 4 tool calling format parsing to properly register function executions
- Update minimum flutter_gemma version to ^0.14.0

## [0.2.3] - 2026-04-13

### Fixed
- Fixed tool call ID mapping in `GemmaChatModel.sendStream` by adding a unique `toolCallIdCounter` to ensure unique IDs for each tool call, preventing orchestration errors in multi-iteration agent loops.

## [0.2.2] - 2026-04-13

### Fixed
- Improved session management in `GemmaChatModel` by creating a fresh chat instance for each `sendStream` call, preventing "Session is closed" errors in multi-iteration agent loops.
- Enhanced tool result formatting for Gemma 2 using `<start_of_role>tool<end_of_role>` tags.

## [0.2.1] - 2026-04-13

### Fixed
- Fixed model being closed prematurely in `GemmaChatModel.dispose`, which caused errors in multi-iteration agent loops.

## [0.2.0] - 2026-04-13

### Added
- Support for selecting preferred backend (CPU/GPU) in `FlutterGemmaProvider` and `GemmaChatModelOptions`.
- Export `PreferredBackend`, `ModelType`, and `ModelFileType` from `flutter_gemma`.

## [0.1.0] - 2026-04-13

### Added
- Initial release of dartantic_gemma package
- Dartantic provider plugin for Flutter Gemma local LLM inference
- Integration with dartantic_interface ^4.0.0
- Support for Flutter Gemma ^0.13.2 and genai_primitives ^0.2.0

[0.1.0]: https://github.com/BoundlessNotions/dartantic_gemma/releases/tag/0.1.0
