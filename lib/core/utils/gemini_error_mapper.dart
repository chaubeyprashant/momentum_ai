import '../errors/app_exception.dart';

/// Maps raw Gemini / SDK errors to [AiServiceException] with stable codes.
AiServiceException mapGeminiError(Object error) {
  final text = error.toString();
  final lower = text.toLowerCase();

  if (lower.contains('api key not set') || lower.contains('missing_api_key')) {
    return const AiServiceException(
      'AI service is temporarily unavailable. Please try again later.',
      code: 'missing_api_key',
    );
  }

  if (_isQuotaError(lower)) {
    final retrySeconds = _parseRetrySeconds(text);
    final waitHint = retrySeconds != null
        ? ' Wait about ${retrySeconds}s and try again.'
        : ' Wait a few minutes and try again.';
    return AiServiceException(
      'AI is busy right now.$waitHint',
      code: 'quota_exceeded',
    );
  }

  if (lower.contains('invalid api key') ||
      lower.contains('api key not valid') ||
      lower.contains('api_key_invalid')) {
    return const AiServiceException(
      'AI service is temporarily unavailable. Please try again later.',
      code: 'invalid_api_key',
    );
  }

  if (lower.contains('model') &&
      (lower.contains('not found') ||
          lower.contains('not supported') ||
          lower.contains('no longer available'))) {
    return const AiServiceException(
      'AI service is temporarily unavailable. Please try again later.',
      code: 'model_not_found',
    );
  }

  return AiServiceException('AI request failed. Please try again later.');
}

bool isQuotaExceededError(Object error) {
  if (error is AiServiceException && error.code == 'quota_exceeded') {
    return true;
  }
  return _isQuotaError(error.toString().toLowerCase());
}

bool _isQuotaError(String lower) {
  return lower.contains('quota') ||
      lower.contains('rate limit') ||
      lower.contains('resource_exhausted') ||
      lower.contains('too many requests');
}

int? _parseRetrySeconds(String text) {
  final match = RegExp(r'retry in ([\d.]+)s', caseSensitive: false).firstMatch(text);
  if (match == null) return null;
  return double.tryParse(match.group(1) ?? '')?.ceil();
}
