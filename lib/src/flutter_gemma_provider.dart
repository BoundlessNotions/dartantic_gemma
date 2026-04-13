import 'dart:async';

import 'package:dartantic_interface/dartantic_interface.dart';
import 'package:flutter_gemma/core/model.dart' as fg;
import 'package:flutter_gemma/flutter_gemma.dart' hide Tool;
import 'package:logging/logging.dart';

import 'chat/gemma_chat_model.dart';
import 'chat/gemma_chat_model_options.dart';
import 'embeddings/gemma_embeddings_model.dart';
import 'embeddings/gemma_embeddings_model_options.dart';

class _GemmaMediaGenerationModelOptions implements MediaGenerationModelOptions {
  const _GemmaMediaGenerationModelOptions();
}

// Placeholder for unimplemented media generation
// ignore: unused_element
const MediaGenerationModelOptions _mediaOptions =
    _GemmaMediaGenerationModelOptions();

const String _defaultChatModelName = 'gemma-2b-it';
const String _defaultEmbeddingsModelName = 'embedding-gemma';

class FlutterGemmaProvider
    extends
        Provider<
          GemmaChatModelOptions,
          GemmaEmbeddingsModelOptions,
          MediaGenerationModelOptions
        > {
  FlutterGemmaProvider({String? huggingFaceToken})
    : super(
        apiKey: huggingFaceToken,
        apiKeyName: 'HUGGINGFACE_TOKEN',
        name: 'flutter_gemma',
        displayName: 'Flutter Gemma',
        defaultModelNames: {
          ModelKind.chat: _defaultChatModelName,
          ModelKind.embeddings: _defaultEmbeddingsModelName,
        },
        aliases: const ['gemma', 'fluttergemma'],
      );

  static final Logger _logger = Logger(
    'dartantic.chat.providers.flutter_gemma',
  );

  bool _initialized = false;
  String? _activeModelId;
  fg.ModelType? _modelType;

  @override
  Stream<ModelInfo> listModels() async* {
    final installedModels = await FlutterGemma.listInstalledModels();
    for (final modelId in installedModels) {
      final isInference =
          modelId.contains('gemma') ||
          modelId.contains('deepseek') ||
          modelId.contains('qwen') ||
          modelId.contains('llama') ||
          modelId.contains('phi');

      final kinds = <ModelKind>{};
      if (isInference) {
        kinds.add(ModelKind.chat);
      }
      if (modelId.contains('embedding')) {
        kinds.add(ModelKind.embeddings);
      }

      if (kinds.isEmpty) {
        kinds.add(ModelKind.other);
      }

      yield ModelInfo(
        name: modelId,
        providerName: name,
        kinds: kinds,
        displayName: modelId,
        description: 'Local inference model',
      );
    }
  }

  @override
  ChatModel<GemmaChatModelOptions> createChatModel({
    String? name,
    List<Tool<Object>>? tools,
    double? temperature,
    bool enableThinking = false,
    GemmaChatModelOptions? options,
  }) {
    final modelName = name ?? defaultModelNames[ModelKind.chat]!;

    _logger.info(
      'Creating Flutter Gemma model: $modelName with '
      '${tools?.length ?? 0} tools, '
      'temp: $temperature, '
      'thinking: $enableThinking',
    );

    return GemmaChatModel(
      name: modelName,
      tools: tools?.cast<Tool>(),
      temperature: temperature,
      enableThinking: enableThinking,
      defaultOptions: options ?? const GemmaChatModelOptions(),
      modelType: _modelType ?? fg.ModelType.gemmaIt,
    );
  }

  @override
  EmbeddingsModel<GemmaEmbeddingsModelOptions> createEmbeddingsModel({
    String? name,
    GemmaEmbeddingsModelOptions? options,
  }) {
    final modelName = name ?? defaultModelNames[ModelKind.embeddings]!;
    _logger.info('Creating Flutter Gemma embeddings model: $modelName');

    return GemmaEmbeddingsModel(
      name: modelName,
      defaultOptions: options ?? const GemmaEmbeddingsModelOptions(),
    );
  }

  @override
  MediaGenerationModel<MediaGenerationModelOptions> createMediaModel({
    String? name,
    List<Tool<Object>>? tools,
    MediaGenerationModelOptions? options,
  }) {
    throw UnimplementedError('Flutter Gemma does not support media generation');
  }

  Future<void> ensureInitialized() async {
    if (!_initialized) {
      await FlutterGemma.initialize(huggingFaceToken: apiKey);
      _initialized = true;
      _logger.info('FlutterGemma initialized');
    }
  }

  Future<void> installAndSetActiveModel({
    required fg.ModelType modelType,
    String? modelUrl,
    fg.ModelFileType fileType = fg.ModelFileType.task,
    void Function(int)? onProgress,
  }) async {
    await ensureInitialized();

    _modelType = modelType;

    if (modelUrl != null) {
      await FlutterGemma.installModel(
        modelType: modelType,
        fileType: fileType,
      ).fromNetwork(modelUrl).withProgress(onProgress ?? (_) {}).install();

      _activeModelId = modelUrl.split('/').last;
      _logger.info('Installed and set active model: $_activeModelId');
    }
  }

  void setActiveModel(String modelId) {
    _activeModelId = modelId;
    _logger.info('Set active model: $modelId');
  }

  String? get activeModelId => _activeModelId;
  fg.ModelType? get modelType => _modelType;
}
