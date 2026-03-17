import 'package:shared_preferences/shared_preferences.dart';

class TaskPersistenceService {
  static const String _keyTasks = 'active_tasks';
  late final SharedPreferences _prefs;

  static final TaskPersistenceService _instance = TaskPersistenceService._internal();
  factory TaskPersistenceService() => _instance;
  TaskPersistenceService._internal();

  /// Initialize with SharedPreferences (call this in Bootstrap)
  void init(SharedPreferences prefs) {
    _prefs = prefs;
  }

  /// Registers a task that has started processing.
  Future<void> registerRunningTask(String taskId, String description) async {
    final tasks = _prefs.getStringList(_keyTasks) ?? [];
    if (!tasks.contains(taskId)) {
      tasks.add(taskId);
      await _prefs.setStringList(_keyTasks, tasks);
      await _prefs.setString('task_desc_$taskId', description);
    }
  }

  /// Clears a task that has safely completed.
  Future<void> completeTask(String taskId) async {
    final tasks = _prefs.getStringList(_keyTasks) ?? [];
    if (tasks.contains(taskId)) {
      tasks.remove(taskId);
      await _prefs.setStringList(_keyTasks, tasks);
      await _prefs.remove('task_desc_$taskId');
    }
  }

  /// Returns a list of tasks that were running during previous session.
  List<String> getInterruptedTasks() {
    return _prefs.getStringList(_keyTasks) ?? [];
  }

  /// Gets the description of an interrupted task.
  String? getTaskDescription(String taskId) {
    return _prefs.getString('task_desc_$taskId');
  }

  /// Clears all interrupted tasks (e.g. after notifying the user).
  Future<void> clearAllInterruptedTasks() async {
    final tasks = _prefs.getStringList(_keyTasks) ?? [];
    for (final taskId in tasks) {
      await _prefs.remove('task_desc_$taskId');
    }
    await _prefs.remove(_keyTasks);
  }
}
