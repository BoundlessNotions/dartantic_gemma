import 'package:dartantic_interface/dartantic_interface.dart';
import 'package:flutter_gemma/core/model.dart' as fg;
import 'package:flutter_gemma/core/message.dart' as fg;
import 'package:flutter_gemma/core/model_response.dart' as fg;
import 'package:flutter_gemma/flutter_gemma.dart' hide Tool;
import 'package:flutter_gemma/core/tool.dart' as fg;
import 'package:logging/logging.dart';

import 'gemma_chat_model_options.dart';

class GemmaChatModel extends ChatModel<GemmaChatModelOptions> {
  GemmaChatModel({
    required super.name,
    List<Tool>? tools,
    super.temperature,
    bool enableThinking = false,
    required GemmaChatModelOptions defaultOptions,
    fg.ModelType modelType = fg.ModelType.gemmaIt,
    PreferredBackend? preferredBackend,
  }) : _enableThinking = enableThinking,
       _modelType = modelType,
       _preferredBackend = preferredBackend,
       super(defaultOptions: defaultOptions, tools: tools);

  static final Logger _logger = Logger('dartantic.chat.models.gemma');

  final bool _enableThinking;
  final fg.ModelType _modelType;
  final PreferredBackend? _preferredBackend;
  InferenceModel? _model;

  @override
  Stream<ChatResult<ChatMessage>> sendStream(
    List<ChatMessage> messages, {
    GemmaChatModelOptions? options,
    Schema? outputSchema,
  }) async* {
    _logger.info(
      'Starting Flutter Gemma chat stream with ${messages.length} messages',
    );

    try {
      if (_model == null) {
        _model = await FlutterGemma.getActiveModel(
          maxTokens: options?.maxTokens ?? defaultOptions.maxTokens ?? 16384,
          preferredBackend: options?.preferredBackend ?? _preferredBackend,
        );
      }

      final dartanticTools = tools;
      List<fg.Tool>? gemmaTools;

      if (dartanticTools != null && dartanticTools.isNotEmpty) {
        gemmaTools = dartanticTools
            .map(
              (t) => fg.Tool(
                name: t.name,
                description: t.description,
                parameters: _convertSchema(t.inputSchema),
              ),
            )
            .toList();
      }

      final chat = await _model!.createChat(
        tools: gemmaTools ?? [],
        supportsFunctionCalls: gemmaTools != null && gemmaTools.isNotEmpty,
        isThinking: _enableThinking,
        modelType: _modelType,
        temperature: temperature ?? 0.8,
        topK: options?.topK ?? 40,
        topP: options?.topP,
        systemInstruction: options?.systemInstruction,
      );

      try {
        // Send history + last message as query to the model.
        // FlutterGemma manages state internally if the model supports it,
        // but for ReACT loops we ensure the session is fresh and we send
        // the context via messages.
        for (final message in messages) {
          final gemmaMessage = _convertToGemmaMessage(message);
          await chat.addQuery(gemmaMessage);
        }

        String accumulatedThinking = '';

        int toolCallIdCounter = 0;

        await for (final response in chat.generateChatResponseAsync()) {
          FinishReason finishReason = FinishReason.unspecified;

          if (response is fg.ThinkingResponse) {
            accumulatedThinking += response.content;
            yield ChatResult<ChatMessage>(
              output: ChatMessage(
                role: ChatMessageRole.model,
                parts: [ThinkingPart(accumulatedThinking)],
              ),
              thinking: accumulatedThinking,
              finishReason: finishReason,
            );
          } else if (response is fg.TextResponse) {
            yield ChatResult<ChatMessage>(
              output: ChatMessage(
                role: ChatMessageRole.model,
                parts: [TextPart(response.token)],
              ),
              thinking: accumulatedThinking.isNotEmpty
                  ? accumulatedThinking
                  : null,
              finishReason: finishReason,
            );
          } else if (response is fg.FunctionCallResponse) {
            finishReason = FinishReason.toolCalls;
            yield ChatResult<ChatMessage>(
              output: ChatMessage(
                role: ChatMessageRole.model,
                parts: [
                  ToolPart.call(
                    callId: 'call_${toolCallIdCounter++}',
                    toolName: response.name,
                    arguments: response.args,
                  ),
                ],
              ),
              thinking: accumulatedThinking.isNotEmpty
                  ? accumulatedThinking
                  : null,
              finishReason: finishReason,
            );
          } else if (response is fg.ParallelFunctionCallResponse) {
            finishReason = FinishReason.toolCalls;
            final toolCallParts = response.calls
                .map(
                  (call) => ToolPart.call(
                    callId: 'call_${toolCallIdCounter++}',
                    toolName: call.name,
                    arguments: call.args,
                  ),
                )
                .toList();
            yield ChatResult<ChatMessage>(
              output: ChatMessage(
                role: ChatMessageRole.model,
                parts: toolCallParts,
              ),
              thinking: accumulatedThinking.isNotEmpty
                  ? accumulatedThinking
                  : null,
              finishReason: finishReason,
            );
          }
        }
      } finally {
        await chat.close();
      }

      _logger.info('Flutter Gemma chat stream completed');
    } catch (e, stackTrace) {
      _logger.warning('Flutter Gemma chat stream error: $e', e, stackTrace);
      rethrow;
    }
  }

  Map<String, dynamic> _convertSchema(Schema? schema) {
    if (schema == null) return {};
    return Map<String, dynamic>.from(schema.value);
  }
fg.Message _convertToGemmaMessage(ChatMessage message) {
  final buffer = StringBuffer();
  for (final part in message.parts) {
    if (part is TextPart) {
      buffer.write(part.text);
    } else if (part is ToolPart) {
      if (part.kind == ToolPartKind.result) {
        buffer.write(part.result.toString());
      }
    } else if (part is ThinkingPart) {
      buffer.write(part.text);
    }
  }

  return fg.Message(
    text: buffer.toString(),
    isUser: message.role == ChatMessageRole.user,
  );
}


  @override
  void dispose() {
    _model = null;
    _logger.info('GemmaChatModel disposed');
  }
}
