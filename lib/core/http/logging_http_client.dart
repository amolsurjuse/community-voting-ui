import 'package:http/http.dart' as http;

/// An [http.BaseClient] decorator that logs every request and response.
///
/// All `http.Client` methods (`get`, `post`, `put`, etc.) funnel through
/// [send], so overriding it in a single place captures everything.
class LoggingHttpClient extends http.BaseClient {
  LoggingHttpClient([http.Client? inner]) : _inner = inner ?? http.Client();

  final http.Client _inner;

  static const _maxBodyLength = 2048;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    _logRequest(request);

    final stopwatch = Stopwatch()..start();
    final response = await _inner.send(request);
    stopwatch.stop();

    // Read the body so we can log it and still return a usable response.
    final bytes = await response.stream.toBytes();
    _logResponse(request, response, bytes, stopwatch.elapsedMilliseconds);

    return http.StreamedResponse(
      http.ByteStream.fromBytes(bytes),
      response.statusCode,
      contentLength: response.contentLength,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  void _logRequest(http.BaseRequest request) {
    final buffer = StringBuffer()
      ..writeln('--> ${request.method} ${request.url}');

    request.headers.forEach((key, value) {
      buffer.writeln('    $key: $value');
    });

    if (request is http.Request && request.body.isNotEmpty) {
      buffer.writeln('    Body: ${_truncate(request.body)}');
    }

    // ignore: avoid_print
    print(buffer.toString());
  }

  void _logResponse(
    http.BaseRequest request,
    http.StreamedResponse response,
    List<int> bytes,
    int elapsedMs,
  ) {
    final body = String.fromCharCodes(bytes);
    final buffer = StringBuffer()
      ..writeln(
        '<-- ${response.statusCode} ${request.method} ${request.url} (${elapsedMs}ms)',
      );

    response.headers.forEach((key, value) {
      buffer.writeln('    $key: $value');
    });

    if (body.isNotEmpty) {
      buffer.writeln('    Body: ${_truncate(body)}');
    }

    // ignore: avoid_print
    print(buffer.toString());
  }

  String _truncate(String value) {
    if (value.length <= _maxBodyLength) return value;
    return '${value.substring(0, _maxBodyLength)}… (truncated)';
  }
}
