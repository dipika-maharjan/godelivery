/// One of the signed-in account's API keys — secrets are never shown again
/// after creation. Matches `ApiKeyListItemResponseDto`.
class ApiKeyListItem {
  const ApiKeyListItem({
    required this.id,
    required this.name,
    required this.keyPrefix,
    required this.scopes,
    this.lastUsedAt,
    this.revokedAt,
    this.expiresAt,
    required this.createdAt,
  });

  factory ApiKeyListItem.fromJson(Map<String, dynamic> json) {
    return ApiKeyListItem(
      id: json['id'] as String,
      name: json['name'] as String,
      keyPrefix: json['keyPrefix'] as String,
      scopes: (json['scopes'] as List).cast<String>(),
      lastUsedAt: json['lastUsedAt'] == null
          ? null
          : DateTime.parse(json['lastUsedAt'] as String),
      revokedAt: json['revokedAt'] == null
          ? null
          : DateTime.parse(json['revokedAt'] as String),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final String name;
  final String keyPrefix;
  final List<String> scopes;
  final DateTime? lastUsedAt;
  final DateTime? revokedAt;
  final DateTime? expiresAt;
  final DateTime createdAt;
}

/// The one-time response to creating a key — [secret] is never shown again.
/// Matches `CreateApiKeyResponseDto`.
class CreatedApiKey {
  const CreatedApiKey({
    required this.id,
    required this.name,
    required this.keyPrefix,
    required this.secret,
    required this.scopes,
  });

  factory CreatedApiKey.fromJson(Map<String, dynamic> json) {
    return CreatedApiKey(
      id: json['id'] as String,
      name: json['name'] as String,
      keyPrefix: json['keyPrefix'] as String,
      secret: json['secret'] as String,
      scopes: (json['scopes'] as List).cast<String>(),
    );
  }

  final String id;
  final String name;
  final String keyPrefix;
  final String secret;
  final List<String> scopes;
}
