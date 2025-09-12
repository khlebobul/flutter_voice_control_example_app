import 'package:flutter/foundation.dart';

/// Service for processing voice commands
class VoiceCommandService {
  static VoiceCommandService? _instance;
  static VoiceCommandService get instance {
    _instance ??= VoiceCommandService._();
    return _instance!;
  }

  VoiceCommandService._();

  final Map<String, VoidCallback> _commands = {};
  final List<String> _commandHistory = [];
  final Map<String, DateTime> _lastExecutionTimes = {};
  final Duration _debounceDelay = const Duration(seconds: 3);
  String _lastProcessedText = '';
  final Set<String> _processedTexts = {};

  /// Registers a voice command with its corresponding action
  void registerCommand(String command, VoidCallback action) {
    _commands[command.toLowerCase()] = action;
    // debugPrint('Зарегистрирована голосовая команда: "$command"');
  }

  /// Unregisters a voice command
  void unregisterCommand(String command) {
    _commands.remove(command.toLowerCase());
    debugPrint('Voice command removed: "$command"');
  }

  /// Clears all registered commands
  void clearCommands() {
    _commands.clear();
    debugPrint('All voice commands cleared');
  }

  /// Processes recognized text and looks for commands
  void processRecognizedText(String text) {
    if (text.isEmpty) return;

    final normalizedText = text.toLowerCase().trim();
    final latestLine = normalizedText.split('\n').first.trim();

    if (_lastProcessedText == latestLine) {
      return;
    }

    final textHash = latestLine.hashCode.toString();
    if (_processedTexts.contains(textHash)) {
      debugPrint('Text was already processed: "$latestLine"');
      return;
    }

    debugPrint('Processing recognized text: "$latestLine"');
    _lastProcessedText = latestLine;
    _processedTexts.add(textHash);

    if (_processedTexts.length > 20) {
      final oldestHashes = _processedTexts.take(_processedTexts.length - 20);
      _processedTexts.removeAll(oldestHashes);
    }

    _commandHistory.add(latestLine);
    if (_commandHistory.length > 50) {
      _commandHistory.removeAt(0);
    }

    // Look for commands in the text
    for (final commandEntry in _commands.entries) {
      final command = commandEntry.key;
      final action = commandEntry.value;

      if (_containsCommand(latestLine, command)) {
        debugPrint('Found command "$command" in text "$latestLine"');

        // Check debounce
        final now = DateTime.now();
        final lastExecution = _lastExecutionTimes[command];

        if (lastExecution != null &&
            now.difference(lastExecution) < _debounceDelay) {
          debugPrint(
            'Command "$command" blocked by debounce (${_debounceDelay.inSeconds}s)',
          );
          continue;
        }

        try {
          action();
          _lastExecutionTimes[command] = now;
          debugPrint('Command "$command" executed successfully');
        } catch (e) {
          debugPrint('Error executing command "$command": $e');
        }
        break; // Execute only the first found command
      }
    }
  }

  /// Checks if the text contains the command
  bool _containsCommand(String text, String command) {
    // Remove potential numbering like "0:", "1:", etc. at the start of each line
    final cleanText = text
        .split('\n')
        .map((line) => line.replaceFirst(RegExp(r'^\d+:\s*'), '').trim())
        .join('\n')
        .trim();

    // Exact match
    if (cleanText == command) return true;

    // Contains the command as a separate word
    final words = cleanText.split(RegExp(r'\s+'));
    if (words.contains(command)) return true;

    // Contains the command at the end of the sentence
    if (cleanText.endsWith(command)) return true;

    // Contains the command at the beginning of the sentence
    if (cleanText.startsWith(command)) return true;

    // Check the original text without cleaning for compatibility
    if (text.contains(command)) return true;

    return false;
  }

  /// Returns the list of registered commands
  List<String> get registeredCommands => _commands.keys.toList();

  /// Returns the command history
  List<String> get commandHistory => List.unmodifiable(_commandHistory);

  /// Clears the command history
  void clearHistory() {
    _commandHistory.clear();
    debugPrint('Voice command history cleared');
  }

  /// Resets text processing state
  void resetProcessingState() {
    _lastProcessedText = '';
    _lastExecutionTimes.clear();
    _processedTexts.clear();
    debugPrint('Command processing state reset');
  }
}
