import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/project_model.dart';
import '../services/project_service.dart';

class ProjectManagerScreen extends StatefulWidget {
  const ProjectManagerScreen({Key? key}) : super(key: key);

  @override
  State<ProjectManagerScreen> createState() => _ProjectManagerScreenState();
}

class _ProjectManagerScreenState extends State<ProjectManagerScreen> {
  final ProjectService _projectService = ProjectService();
  List<SiteProject> _projects = [];
  String _activeProjectId = '';

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    await _projectService.initialize();
    final projects = await _projectService.getProjectsSortedByDate();
    if (mounted) {
      setState(() {
        _projects = projects;
        _activeProjectId = _projectService.activeProjectId;
      });
    }
  }

  Future<void> _createProject() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final clientController = TextEditingController();
    final locationController = TextEditingController();
    final colors = ['#2196F3', '#4CAF50', '#FF9800', '#E91E63', '#9C27B0', '#00BCD4', '#F44336'];
    String selectedColor = colors[Random().nextInt(colors.length)];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Project'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Project Name', hintText: 'e.g., Site A Survey'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: clientController,
                  decoration: const InputDecoration(labelText: 'Client Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Color: '),
                    ...colors.map((c) => GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = c),
                      child: Container(
                        margin: const EdgeInsets.only(left: 4),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(int.parse(c.replaceFirst('#', '0xFF'))),
                          border: selectedColor == c
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                        ),
                      ),
                    )),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                await _projectService.createProject(
                  name: nameController.text.trim(),
                  description: descController.text.trim(),
                  color: selectedColor,
                  clientName: clientController.text.trim().isNotEmpty ? clientController.text.trim() : null,
                  location: locationController.text.trim().isNotEmpty ? locationController.text.trim() : null,
                );
                final projects = await _projectService.getProjectsSortedByDate();
                if (mounted) {
                  setState(() => _projects = projects);
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editProject(SiteProject project) async {
    final nameController = TextEditingController(text: project.name);
    final descController = TextEditingController(text: project.description);
    final clientController = TextEditingController(text: project.clientName ?? '');
    final locationController = TextEditingController(text: project.location ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Project'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Project Name')),
              const SizedBox(height: 12),
              TextField(controller: descController, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 12),
              TextField(controller: clientController, decoration: const InputDecoration(labelText: 'Client Name')),
              const SizedBox(height: 12),
              TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await _projectService.updateProject(
                project.id,
                project.copyWith(
                  name: nameController.text.trim(),
                  description: descController.text.trim(),
                  clientName: clientController.text.trim().isNotEmpty ? clientController.text.trim() : null,
                  location: locationController.text.trim().isNotEmpty ? locationController.text.trim() : null,
                ),
              );
              final projects = await _projectService.getProjectsSortedByDate();
              if (mounted) {
                setState(() => _projects = projects);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _projects.length,
        itemBuilder: (context, index) {
          final project = _projects[index];
          final isActive = project.id == _activeProjectId;
          return Card(
            color: isActive ? Colors.grey[850] : Colors.grey[900],
            shape: RoundedRectangleBorder(
              side: isActive
                  ? BorderSide(color: Color(int.parse(project.color.replaceFirst('#', '0xFF'))), width: 2)
                  : BorderSide.none,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(int.parse(project.color.replaceFirst('#', '0xFF'))),
                child: Text(
                  project.name.isNotEmpty ? project.name[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                project.name,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (project.description.isNotEmpty)
                    Text(project.description, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  if (project.clientName != null)
                    Text('Client: ${project.clientName}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  Text(
                    DateFormat('MMM dd, yyyy').format(project.createdAt),
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isActive)
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      if (!isActive)
                        PopupMenuItem(
                          child: const Text('Set Active'),
                          onTap: () async {
                            await _projectService.setActiveProject(project.id);
                            if (mounted) setState(() => _activeProjectId = project.id);
                          },
                        ),
                      PopupMenuItem(
                        child: const Text('Edit'),
                        onTap: () => _editProject(project),
                      ),
                      if (project.id != 'default')
                        PopupMenuItem(
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          onTap: () async {
                            await _projectService.deleteProject(project.id);
                            final projects = await _projectService.getProjectsSortedByDate();
                            if (mounted) setState(() => _projects = projects);
                          },
                        ),
                    ],
                  ),
                ],
              ),
              onTap: () async {
                await _projectService.setActiveProject(project.id);
                if (mounted) setState(() => _activeProjectId = project.id);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createProject,
        child: const Icon(Icons.add),
      ),
    );
  }
}
