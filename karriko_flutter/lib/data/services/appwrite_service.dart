import 'package:appwrite/appwrite.dart';
import '../../core/constants/appwrite_constants.dart';

class AppwriteService {
  static late final Client _client;
  static late final Account _account;
  static bool _initialized = false;

  static Client get client => _client;
  static Account get account => _account;

  static Future<void> initialize() async {
    if (_initialized) return;
    _client = Client()
        .setEndpoint(AppwriteConstants.endpoint)
        .setProject(AppwriteConstants.projectId)
        .setSelfSigned(status: false);
    _account = Account(_client);
    _initialized = true;
  }
}
