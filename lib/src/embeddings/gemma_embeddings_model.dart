import 'package:dartantic_interface/dartantic_interface.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:logging/logging.dart';

import 'gemma_embeddings_model_options.dart';

class GemmaEmbeddingsModel
    extends EmbeddingsModel<GemmaEmbeddingsModelOptions> {
  GemmaEmbeddingsModel({
    required String name,
    GemmaEmbeddingsModelOptions? defaultOptions,
    this.dimensions,
    this.batchSize,
  }) : _defaultOptions = defaultOptions ?? const GemmaEmbeddingsModelOptions(),
       super(
         name: name,
         defaultOptions: defaultOptions ?? const GemmaEmbeddingsModelOptions(),
       );

  static final Logger _logger = Logger('dartantic.embeddings.gemma');

  final GemmaEmbeddingsModelOptions _defaultOptions;
  @override
  final int? dimensions;
  @override
  final int? batchSize;
  dynamic _embeddingModel;

  @override
  Future<EmbeddingsResult> embedQuery(
    String query, {
    GemmaEmbeddingsModelOptions? options,
  }) async {
    _logger.info('Embedding query of length ${query.length}');

    try {
      if (_embeddingModel == null) {
        _embeddingModel = await FlutterGemma.getActiveEmbedder(
          preferredBackend: _defaultOptions.preferredBackend,
        );
      }

      final embedding = await _embeddingModel.generateEmbedding(
        query,
        taskType: TaskType.retrievalQuery,
      );

      return EmbeddingsResult(
        output: embedding,
        finishReason: FinishReason.stop,
        metadata: const {},
        usage: null,
      );
    } catch (e, stackTrace) {
      _logger.warning('Embedding query error: $e', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<BatchEmbeddingsResult> embedDocuments(
    List<String> texts, {
    GemmaEmbeddingsModelOptions? options,
  }) async {
    _logger.info('Embedding ${texts.length} documents');

    try {
      if (_embeddingModel == null) {
        _embeddingModel = await FlutterGemma.getActiveEmbedder(
          preferredBackend: _defaultOptions.preferredBackend,
        );
      }

      final embeddings = await _embeddingModel.generateEmbeddings(
        texts,
        taskType: TaskType.retrievalDocument,
      );

      return BatchEmbeddingsResult(
        output: embeddings,
        finishReason: FinishReason.stop,
        metadata: const {},
        usage: null,
      );
    } catch (e, stackTrace) {
      _logger.warning('Embedding documents error: $e', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    if (_embeddingModel != null) {
      await _embeddingModel.close();
      _embeddingModel = null;
    }
    _logger.info('GemmaEmbeddingsModel disposed');
  }
}
