import '../errors/app_exception.dart';
import 'gemini_error_mapper.dart' as gemini_errors;

/// User-facing message for AI / Gemini failures.
String userFacingAiError(Object error) {
  if (error is AiServiceException) {
    return error.message;
  }

  return gemini_errors.mapGeminiError(error).message;
}

bool isMissingGeminiKeyError(Object error) {
  if (error is AiServiceException && error.code == 'missing_api_key') {
    return true;
  }
  final text = error.toString().toLowerCase();
  return text.contains('api key not set') || text.contains('missing_api_key');
}

bool isQuotaExceededError(Object error) => gemini_errors.isQuotaExceededError(error);
