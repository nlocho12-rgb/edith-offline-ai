import 'package:flutter/services.dart';

/// Talks to the native llama.cpp engine via MethodChannel.
class LlamaService {
  static const MethodChannel _channel = MethodChannel('com.nlocho.edith/native');

  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<bool> initEngine() async {
    try {
      final ok = await _channel.invokeMethod<bool>('initEngine');
      _initialized = ok ?? false;
      return _initialized;
    } on PlatformException catch (e) {
      throw Exception('Failed to initialize engine: ${e.message}');
    }
  }

  Future<String> infer(String prompt) async {
    if (!_initialized) {
      throw StateError('Engine not initialized. Call initEngine() first.');
    }
    try {
      final response = await _channel.invokeMethod<String>('inferLLM', {
        'prompt': prompt,
      });
      return response ?? '';
    } on PlatformException catch (e) {
      throw Exception('Inference failed: ${e.message}');
    }
  }
}
