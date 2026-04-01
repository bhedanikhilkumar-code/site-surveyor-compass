import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/project_model.dart';

class ProjectService {
  static const String projectBoxName = 'projects';
  late Box<SiteProject> _projectBox;
  String _activeProjectId = 'default';

  String get activeProjectId => _activeProjectId;

  bool get isInitialized => Hive.isBoxOpen(projectBoxName);

  Future<void> initialize() async {
    if (!isInitialized) {
      _projectBox = await Hive.openBox<SiteProject>(projectBoxName);
    } else {
      _projectBox = Hive.box<SiteProject>(projectBoxName);
    }

    if (_projectBox.isEmpty) {
      await createProject(
        name: 'Default Project',
        description: 'Default site survey project',
        color: '#2196F3',
      );
    }

    final defaultProject = _projectBox.values.firstWhere(
      (p) => p.id == 'default',
      orElse: () => _projectBox.values.first,
    );
    _activeProjectId = defaultProject.id;
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
    if (id == 'default') return;
    await _projectBox.delete(id);
    if (_activeProjectId == id) {
      _activeProjectId = _projectBox.isNotEmpty ? _projectBox.values.first.id : 'default';
    }
  }

  Future<int> getProjectCount() async {
    return _projectBox.length;
  }

  Future<void> close() async {
    await _projectBox.close();
  }
}
