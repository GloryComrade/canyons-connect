/// Canonical route paths. Use these instead of string literals.
class Routes {
  const Routes._();

  static const signIn = '/sign-in';
  static const home = '/home';
  static const schedule = '/schedule';
  static const grades = '/grades';
  static const inbox = '/inbox';
  static const clubs = '/clubs';
  static const utahView = '/utah-view';
  static const photoDrop = '/photo-drop';
  static const profile = '/profile';

  // Pushed (above the shell)
  static const connections = '/connections';
  static const search = '/search';

  static const photoEventPattern = '/photo-event/:id';
  static String photoEvent(String id) => '/photo-event/$id';
}
