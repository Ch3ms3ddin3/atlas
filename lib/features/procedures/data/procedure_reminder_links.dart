/// Associe les rappels administratifs de l'accueil aux guides démarches.
abstract final class ProcedureReminderLinks {
  static const _links = {
    'admin-cin': 'cin-renewal',
  };

  static String? procedureIdForReminder(String reminderId) {
    return _links[reminderId];
  }
}
