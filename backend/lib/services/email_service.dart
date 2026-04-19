import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../config/config.dart';

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  final Config _config = Config();

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

  Future<bool> sendInvitationEmail({
    required String toEmail,
    required String orgName,
    required String invitationCode,
  }) async {
    if (!isConfigured) {
      print('⚠️  SMTP nicht konfiguriert – Einladungs-E-Mail nicht gesendet');
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
      ..from = Address(_config.smtpFrom ?? _config.smtpUser!, 'MyPet')
      ..recipients.add(Address(toEmail))
      ..subject = '🐾 Einladung zu $orgName'
      ..html = '''
<!DOCTYPE html>
<html>
<body style="font-family:sans-serif;max-width:600px;margin:0 auto;padding:20px;">
  <h2 style="color:#4CAF50;">🐾 MyPet Einladung</h2>
  <p>Du wurdest eingeladen, der Organisation <strong>${_htmlEscape(orgName)}</strong> beizutreten.</p>
  <p>Dein Einladungscode: <strong style="font-size:18px;letter-spacing:2px;">${_htmlEscape(invitationCode)}</strong></p>
  <p>Melde dich in der MyPet-App an und gib diesen Code ein, um der Organisation beizutreten.</p>
  <p style="color:#888;font-size:12px;">Diese Einladung ist 7 Tage gültig.</p>
</body>
</html>
'''
      ..text =
          'Einladung zu $orgName\n\nDein Code: $invitationCode\n\nMelde dich in MyPet an und gib diesen Code ein.';

    try {
      await send(envelope, smtpServer);
      return true;
    } catch (e) {
      print('❌ Einladungs-E-Mail-Fehler: $e');
      return false;
    }
  }

  String _htmlEscape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}
