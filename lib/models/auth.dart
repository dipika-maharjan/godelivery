class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAt,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      accessTokenExpiresAt: json['accessTokenExpiresAt'] as String,
    );
  }

  final String accessToken;
  final String refreshToken;
  final String accessTokenExpiresAt;
}

enum VerifyOtpStatus { login, signupRequired }

class VerifyOtpResult {
  const VerifyOtpResult({required this.status, this.tokens, this.signupToken});

  factory VerifyOtpResult.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResult(
      status: json['status'] == 'LOGIN'
          ? VerifyOtpStatus.login
          : VerifyOtpStatus.signupRequired,
      tokens: json['tokens'] == null
          ? null
          : AuthTokens.fromJson(json['tokens'] as Map<String, dynamic>),
      signupToken: json['signupToken'] as String?,
    );
  }

  final VerifyOtpStatus status;
  final AuthTokens? tokens;
  final String? signupToken;
}
