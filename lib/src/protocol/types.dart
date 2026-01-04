/// MCP Protocol types and data structures
library;

/// Base class for all MCP requests
class MCPRequest {
  final String jsonrpc;
  final String method;
  final Map<String, dynamic>? params;
  final Object? id;
  final Map<String, String>? headers;

  const MCPRequest({
    this.jsonrpc = '2.0',
    required this.method,
    this.params,
    this.id,
    this.headers,
  });

  factory MCPRequest.fromJson(Map<String, dynamic> json) => MCPRequest(
    jsonrpc: json['jsonrpc'] as String? ?? '2.0',
    method: json['method'] as String,
    params: json['params'] as Map<String, dynamic>?,
    id: json['id'],
    headers: json['headers'] != null
        ? Map<String, String>.from(json['headers'] as Map)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'jsonrpc': jsonrpc,
    'method': method,
    if (params != null) 'params': params,
    if (id != null) 'id': id,
    if (headers != null) 'headers': headers,
  };

  /// Creates a new MCPRequest with the given headers merged with existing ones
  MCPRequest withHeaders(Map<String, String> additionalHeaders) {
    if (additionalHeaders.isEmpty) return this;

    final mergedHeaders = <String, String>{};
    if (headers != null) {
      mergedHeaders.addAll(headers!);
    }
    mergedHeaders.addAll(additionalHeaders);

    return MCPRequest(
      jsonrpc: jsonrpc,
      method: method,
      params: params,
      id: id,
      headers: mergedHeaders,
    );
  }
}

/// Base class for all MCP responses
class MCPResponse {
  final String jsonrpc;
  final dynamic result;
  final MCPError? error;
  final dynamic id;

  const MCPResponse({this.jsonrpc = '2.0', this.result, this.error, this.id});

  factory MCPResponse.fromJson(Map<String, dynamic> json) => MCPResponse(
    jsonrpc: json['jsonrpc'] as String? ?? '2.0',
    result: json['result'],
    error: json['error'] != null
        ? MCPError.fromJson(json['error'] as Map<String, dynamic>)
        : null,
    id: json['id'],
  );

  Map<String, dynamic> toJson() => {
    'jsonrpc': jsonrpc,
    if (result != null) 'result': result,
    if (error != null) 'error': error!.toJson(),
    if (id != null) 'id': id,
  };
}

/// MCP Error structure
class MCPError {
  final int code;
  final String message;
  final dynamic data;

  const MCPError({required this.code, required this.message, this.data});

  factory MCPError.fromJson(Map<String, dynamic> json) => MCPError(
    code: json['code'] as int,
    message: json['message'] as String,
    data: json['data'],
  );

  Map<String, dynamic> toJson() => {
    'code': code,
    'message': message,
    if (data != null) 'data': data,
  };
}

/// Tool definition
class MCPToolDefinition {
  final String name;
  final String description;
  final Map<String, dynamic>? inputSchema;

  const MCPToolDefinition({
    required this.name,
    required this.description,
    this.inputSchema,
  });

  factory MCPToolDefinition.fromJson(Map<String, dynamic> json) =>
      MCPToolDefinition(
        name: json['name'] as String,
        description: json['description'] as String,
        inputSchema: json['inputSchema'] as Map<String, dynamic>?,
      );

  Map<String, dynamic> toJson() {
    // Always include inputSchema with proper JSON Schema format
    // Empty or null schemas become {"type": "object", "properties": {}}
    final schema = inputSchema;
    final normalizedSchema = (schema == null || schema.isEmpty)
        ? {'type': 'object', 'properties': <String, dynamic>{}}
        : schema;

    return {
      'name': name,
      'description': description,
      'inputSchema': normalizedSchema,
    };
  }
}

/// Resource definition
class MCPResourceDefinition {
  final String uri;
  final String name;
  final String description;
  final String? mimeType;

  const MCPResourceDefinition({
    required this.uri,
    required this.name,
    required this.description,
    this.mimeType,
  });

  factory MCPResourceDefinition.fromJson(Map<String, dynamic> json) =>
      MCPResourceDefinition(
        uri: json['uri'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        mimeType: json['mimeType'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'uri': uri,
    'name': name,
    'description': description,
    if (mimeType != null) 'mimeType': mimeType,
  };
}

/// Prompt definition
class MCPPromptDefinition {
  final String name;
  final String description;
  final List<MCPPromptArgument>? arguments;

  const MCPPromptDefinition({
    required this.name,
    required this.description,
    this.arguments,
  });

  factory MCPPromptDefinition.fromJson(Map<String, dynamic> json) =>
      MCPPromptDefinition(
        name: json['name'] as String,
        description: json['description'] as String,
        arguments: (json['arguments'] as List<dynamic>?)
            ?.map(
              (arg) => MCPPromptArgument.fromJson(arg as Map<String, dynamic>),
            )
            .toList(),
      );

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    if (arguments != null)
      'arguments': arguments!.map((arg) => arg.toJson()).toList(),
  };
}

/// Prompt argument definition
class MCPPromptArgument {
  final String name;
  final String description;
  final bool required;

  const MCPPromptArgument({
    required this.name,
    required this.description,
    this.required = false,
  });

  factory MCPPromptArgument.fromJson(Map<String, dynamic> json) =>
      MCPPromptArgument(
        name: json['name'] as String,
        description: json['description'] as String,
        required: json['required'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'required': required,
  };
}

/// Tool call context - provides access to parameters and metadata
class MCPToolContext {
  final Map<String, dynamic> _params;
  final String toolName;
  final dynamic requestId;
  final Map<String, String>? _headers;

  MCPToolContext(
    this._params,
    this.toolName,
    this.requestId, {
    Map<String, String>? headers,
  }) : _headers = headers;

  /// Get a parameter value with type checking
  T param<T>(String name, {T? defaultValue}) {
    final value = _params[name];
    if (value == null) {
      if (defaultValue != null) return defaultValue;
      throw ArgumentError('Required parameter "$name" is missing');
    }

    if (value is! T) {
      throw ArgumentError(
        'Parameter "$name" expected type $T but got ${value.runtimeType}',
      );
    }

    return value;
  }

  /// Get an optional parameter
  T? optionalParam<T>(String name) {
    final value = _params[name];
    return value is T ? value : null;
  }

  /// Get all parameters as a map
  Map<String, dynamic> get allParams => Map.unmodifiable(_params);

  /// Get request headers (if available)
  Map<String, String>? get headers =>
      _headers != null ? Map.unmodifiable(_headers) : null;

  /// Get a header value by name (case-insensitive)
  String? header(String name) {
    if (_headers == null) return null;

    // Case-insensitive lookup
    final lowerName = name.toLowerCase();
    final headerEntry = _headers.entries.firstWhere(
      (e) => e.key.toLowerCase() == lowerName,
      orElse: () => const MapEntry('', ''),
    );

    return headerEntry.key.isNotEmpty ? headerEntry.value : null;
  }
}

/// Resource content following MCP specification
class MCPResourceContent {
  final String uri;
  final String name;
  final String? title;
  final String? description;
  final String? mimeType;
  final String? text;
  final String? blob;
  final int? size;
  final MCPResourceAnnotations? annotations;

  const MCPResourceContent({
    required this.uri,
    required this.name,
    this.title,
    this.description,
    this.mimeType,
    this.text,
    this.blob,
    this.size,
    this.annotations,
  });

  factory MCPResourceContent.fromJson(Map<String, dynamic> json) =>
      MCPResourceContent(
        uri: json['uri'] as String,
        name: json['name'] as String,
        title: json['title'] as String?,
        description: json['description'] as String?,
        mimeType: json['mimeType'] as String?,
        text: json['text'] as String?,
        blob: json['blob'] as String?,
        size: json['size'] as int?,
        annotations: json['annotations'] != null
            ? MCPResourceAnnotations.fromJson(
                json['annotations'] as Map<String, dynamic>,
              )
            : null,
      );

  Map<String, dynamic> toJson() => {
    'uri': uri,
    'name': name,
    if (title != null) 'title': title,
    if (description != null) 'description': description,
    if (mimeType != null) 'mimeType': mimeType,
    if (text != null) 'text': text,
    if (blob != null) 'blob': blob,
    if (size != null) 'size': size,
    if (annotations != null) 'annotations': annotations!.toJson(),
  };
}

/// Resource metadata following MCP specification
/// These are called "annotations" in the spec but are actually metadata hints
class MCPResourceAnnotations {
  final List<String>? audience;
  final double? priority;
  final String? lastModified;

  const MCPResourceAnnotations({
    this.audience,
    this.priority,
    this.lastModified,
  });

  factory MCPResourceAnnotations.fromJson(Map<String, dynamic> json) =>
      MCPResourceAnnotations(
        audience: (json['audience'] as List<dynamic>?)?.cast<String>(),
        priority: (json['priority'] as num?)?.toDouble(),
        lastModified: json['lastModified'] as String?,
      );

  Map<String, dynamic> toJson() => {
    if (audience != null) 'audience': audience,
    if (priority != null) 'priority': priority,
    if (lastModified != null) 'lastModified': lastModified,
  };
}

/// Tool result
class MCPToolResult {
  final dynamic content;
  final bool isError;

  const MCPToolResult({required this.content, this.isError = false});

  factory MCPToolResult.fromJson(Map<String, dynamic> json) => MCPToolResult(
    content: json['content'],
    isError: json['isError'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {'content': content, 'isError': isError};
}

// =============================================================================
// MCP CONTENT TYPES - For returning rich content from tools
// =============================================================================

/// Base class for MCP content blocks returned by tools.
/// Tools can return a single MCPContent or List<MCPContent> to include
/// multiple content types (e.g., text + image) in their response.
abstract class MCPContent {
  const MCPContent();

  Map<String, dynamic> toJson();
}

/// Text content block for tool responses.
class TextContent extends MCPContent {
  final String text;

  const TextContent(this.text);

  @override
  Map<String, dynamic> toJson() => {
    'type': 'text',
    'text': text,
  };
}

/// Image content block for tool responses.
/// The AI can "see" images returned this way.
class ImageContent extends MCPContent {
  /// Base64-encoded image data
  final String data;

  /// MIME type of the image (default: image/png)
  final String mimeType;

  const ImageContent({
    required this.data,
    this.mimeType = 'image/png',
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': 'image',
    'data': data,
    'mimeType': mimeType,
  };
}

/// Embedded resource content block for tool responses.
class ResourceContent extends MCPContent {
  final MCPResourceContent resource;

  const ResourceContent(this.resource);

  @override
  Map<String, dynamic> toJson() => {
    'type': 'resource',
    'resource': resource.toJson(),
  };
}
