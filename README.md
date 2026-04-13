# dartantic_gemma

Dartantic provider plugin for Flutter Gemma local LLM inference.

## Overview

This package provides a [Dartantic](https://github.com/csells/dartantic) provider implementation that uses the [flutter_gemma](https://github.com/DenesovAV/flutter_gemma) library for managing local LLM model interactions on Flutter mobile applications.

## Features

- **Local LLM Inference**: Run Gemma and other local models on-device
- **Thinking Mode**: Support for Gemma 4 E2B/E4B thinking mode via `enableThinking` parameter
- **Tool Calling**: Full function calling support for GPT-style tool usage
- **Embeddings**: Text embeddings generation for semantic search and retrieval

## Usage

```dart
import 'package:dartantic_gemma/dartantic_gemma.dart';

final provider = FlutterGemmaProvider(huggingFaceToken: 'your-token');

// Create a chat model with thinking enabled
final chatModel = provider.createChatModel(
  name: 'gemma-4b-it',
  enableThinking: true,
  temperature: 0.7,
);

// Create an embeddings model
final embeddingsModel = provider.createEmbeddingsModel(
  name: 'embedding-gemma',
);

// Stream chat responses
await for (final result in chatModel.sendStream(messages)) {
  // Handle result
}
```

## Requirements

- Dart SDK ^3.10.0
- Flutter SDK ^3.41.0 (stable)
- flutter_gemma ^0.13.2

## License

BSD 3-Clause License - see LICENSE file for details.