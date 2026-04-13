import 'package:dartantic_interface/dartantic_interface.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

class GemmaEmbeddingsModelOptions extends EmbeddingsModelOptions {
  const GemmaEmbeddingsModelOptions({
    this.dimensions,
    this.batchSize,
    this.preferredBackend,
  });

  final int? dimensions;
  final int? batchSize;
  final PreferredBackend? preferredBackend;
}
