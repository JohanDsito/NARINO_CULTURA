import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/account_security_repository.dart';

export 'change_email_provider.dart';

export 'active_sessions_provider.dart';

export 'delete_account_provider.dart';

final accountSecurityRepositoryProvider =
    Provider<AccountSecurityRepository>((ref) => AccountSecurityRepository());
