import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../config/config.dart';

class EmailService {
  final Config _config;

  EmailService({required Config config}) : _config = config;

  bool get isConfigured =>
      (_config.smtpHost?.isNotEmpty ?? false) &&
      (_config.smtpUser?.isNotEmpty ?? false);

  Future<bool> sendReminderEmail({
    required String toEmail,
    required String toName,
    required String title,
    required String message,
    required DateTime remindAt,
  }) async {
    if (!isConfigured) {
      print('⚠️  SMTP nicht konfiguriert – E-Mail nicht gesendet: $title');
      return false;
    }

    final smtpServer = SmtpServer(
      _config.smtpHost!,
      port: _config.smtpPort ?? 587,
      ssl: false,
      username: _config.smtpUser,
      password: _config.smtpPassword,
    );

    final envelope = Message()
      ..from = Address(_config.smtpFrom ?? _config.smtpUser!, 'MyPet Reminder')
      ..recipients.add(Address(toEmail, toName))
      ..subject = '🐾 Erinnerung: $title'
      ..html = _buildHtml(toName, title, message, remindAt)
      ..text = _buildText(toName, title, message, remindAt);

    try {
      await send(envelope, smtpServer);
      return true;
    } catch (e) {
      print('❌ E-Mail-Fehler: $e');
      return false;
    }
  }

  String _buildHtml(
      String name, String title, String message, DateTime remindAt) {
    final dateStr =
        '${remindAt.day.toString().padLeft(2, '0')}.${remindAt.month.toString().padLeft(2, '0')}.${remindAt.year}';
    return '''
<!DOCTYPE html>
<html>
<body style="font-family:sans-serif;max-width:600px;margin:0 auto;padding:20px;">
  <h2 style="color:#4CAF50;">🐾 MyPet Erinnerung</h2>
  <p>Hallo $name,</p>
  <p>Du hast eine Erinnerung für <strong>$dateStr</strong>:</p>
  <div style="background:#f5f5f5;padding:16px;border-radius:8px;margin:16px 0;">
    <h3 style="margin:0 0 8px;">${_htmlEscape(title)}</h3>
    ${message.isNotEmpty ? '<p style="margin:0;">${_htmlEscape(message)}</p>' : ''}
  </div>
  <p style="color:#888;font-size:12px;">Diese E-Mail wurde automatisch von MyPet gesendet.</p>
</body>
</html>
''';
  }

  String _buildText(
      String name, String title, String message, DateTime remindAt) {
    final dateStr =
        '${remindAt.day.toString().padLeft(2, '0')}.${remindAt.month.toString().padLeft(2, '0')}.${remindAt.year}';
    return 'Hallo $name,\n\nErinnerung für $dateStr:\n$title\n${message.isNotEmpty ? message : ''}\n\n-- MyPet';
  }

  String _htmlEscape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}
