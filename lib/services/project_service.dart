import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/project_model.dart';

class ProjectService {
  static const String projectBoxName = 'projects';
  static const String _metaBoxName = 'project_meta';
  static const String _activeProjectKey = 'active_project_id';
  late Box<SiteProject> _projectBox;
  late Box _metaBox;
  String _activeProjectId = 'default';

  String get activeProjectId => _activeProjectId;

  bool get isInitialized => Hive.isBoxOpen(projectBoxName);

  Future<void> initialize() async {
    if (!isInitialized) {
      _projectBox = await Hive.openBox<SiteProject>(projectBoxName);
    } else {
      _projectBox = Hive.box<SiteProject>(projectBoxName);
    }

    if (!Hive.isBoxOpen(_metaBoxName)) {
      _metaBox = await Hive.openBox(_metaBoxName);
    } else {
      _metaBox = Hive.box(_metaBoxName);
    }

    if (_projectBox.isEmpty) {
      await createProject(
        name: 'Default Project',
        description: 'Default site survey project',
        color: '#2196F3',
      );
    }

    // Restore persisted active project ID
    final persistedId = _metaBox.get(_activeProjectKey) as String?;
    if (persistedId != null && _projectBox.containsKey(persistedId)) {
      _activeProjectId = persistedId;
    } else {
      _activeProjectId = _projectBox.values.first.id;
    }
  }

  Future<SiteProject> createProject({
    required String name,
    String description = '',
    String color = '#2196F3',
    String? clientName,
    String? location,
  }) async {
    final project = SiteProject(
      id: const Uuid().v4(),
      name: name,
      description: description,
      createdAt: DateTime.now(),
      color: color,
      clientName: clientName,
      location: location,
    );
    await _projectBox.put(project.id, project);
    return project;
  }

  Future<void> setActiveProject(String projectId) async {
    _activeProjectId = projectId;
    await _metaBox.put(_activeProjectKey, projectId);
  }

  Future<SiteProject?> getActiveProject() async {
    return _projectBox.get(_activeProjectId);
  }

  Future<List<SiteProject>> getAllProjects() async {
    return _projectBox.values.toList();
  }

  Future<List<SiteProject>> getProjectsSortedByDate({bool descending = true}) async {
    final projects = _projectBox.values.toList();
    projects.sort((a, b) {
      if (descending) return b.createdAt.compareTo(a.createdAt);
      return a.createdAt.compareTo(b.createdAt);
    });
    return projects;
  }

  Future<SiteProject?> getProject(String id) async {
    return _projectBox.get(id);
  }

  Future<void> updateProject(String id, SiteProject project) async {
    await _projectBox.put(id, project.copyWith(updatedAt: DateTime.now()));
  }

  Future<void> deleteProject(String id) async {
    if (_projectBox.length <= 1) return; // Prevent deleting the last project
    await _projectBox.delete(id);
    if (_activeProjectId == id) {
      _activeProjectId = _projectBox.values.first.id;
      await _metaBox.put(_activeProjectKey, _activeProjectId);
    }
  }

  Future<int> getProjectCount() async {
    return _projectBox.length;
  }

  Future<void> close() async {
    await _projectBox.close();
    await _metaBox.close();
  }
}
