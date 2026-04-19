import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import '../config/config.dart';

/// Service für symmetrische Verschlüsselung sensibler Felder (AES-256-CBC).
///
/// Verwendung:
///   final enc = EncryptionService();
///   final cipher = enc.encrypt('geheime Notiz');
///   final plain = enc.decrypt(cipher);
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  late final Encrypter _encrypter;
  bool _initialized = false;

  void init() {
    if (_initialized) return;
    final rawKey = Config().encryptionKey;
    // Derive 32-byte AES key from raw key string via SHA-256
    final keyBytes = sha256.convert(utf8.encode(rawKey)).bytes;
    final key = Key(Uint8List.fromList(keyBytes));
    _encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    _initialized = true;
  }

  /// Verschlüsselt einen String. Gibt "<iv_base64>:<cipher_base64>" zurück.
  String encrypt(String plaintext) {
    if (!_initialized) init();
    final iv = IV.fromSecureRandom(16);
    final encrypted = _encrypter.encrypt(plaintext, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Entschlüsselt einen "<iv_base64>:<cipher_base64>" String.
  /// Gibt null zurück wenn das Format ungültig ist.
  String? decrypt(String ciphertext) {
    if (!_initialized) init();
    try {
      final parts = ciphertext.split(':');
      if (parts.length != 2) return null;
      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);
      return _encrypter.decrypt(encrypted, iv: iv);
    } catch (_) {
      return null;
    }
  }

  /// Gibt true zurück wenn der Wert verschlüsselt aussieht (iv:cipher Format).
  bool isEncrypted(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return false;
    try {
      IV.fromBase64(parts[0]);
      Encrypted.fromBase64(parts[1]);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Verschlüsselt einen Wert, falls er noch nicht verschlüsselt ist.
  String encryptIfNeeded(String plaintext) {
    return isEncrypted(plaintext) ? plaintext : encrypt(plaintext);
  }
}
