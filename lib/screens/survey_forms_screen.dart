import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SurveyFormsScreen extends StatefulWidget {
  const SurveyFormsScreen({super.key});

  @override
  State<SurveyFormsScreen> createState() => _SurveyFormsScreenState();
}

class _SurveyFormsScreenState extends State<SurveyFormsScreen> {
  final List<SurveyForm> _forms = [];
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _loadForms();
  }

  Future<void> _loadForms() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/survey_forms.json');
      if (await file.exists()) {
        final data = jsonDecode(await file.readAsString()) as List;
        setState(() {
          _forms.clear();
          for (var form in data) {
            _forms.add(SurveyForm.fromJson(form as Map<String, dynamic>));
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading forms: $e');
    }
  }

  Future<void> _saveForms() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/survey_forms.json');
    await file.writeAsString(jsonEncode(_forms.map((f) => f.toJson()).toList()));
  }

  void _createNewForm() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        return AlertDialog(
          title: const Text('Create New Form'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Form Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final form = SurveyForm(
                    id: _uuid.v4(),
                    name: nameController.text,
                    fields: [],
                    createdAt: DateTime.now(),
                  );
                  setState(() => _forms.add(form));
                  _saveForms();
                  Navigator.pop(context);
                  _openFormEditor(form);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _openFormEditor(SurveyForm form) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FormEditorSheet(
        form: form,
        onSave: (updatedForm) {
          setState(() {
            final index = _forms.indexWhere((f) => f.id == updatedForm.id);
            if (index != -1) _forms[index] = updatedForm;
          });
          _saveForms();
        },
      ),
    );
  }

  void _fillForm(SurveyForm form) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FormFillSheet(
        form: form,
        onSubmit: (responses) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Form submitted!')),
          );
        },
      ),
    );
  }

  void _deleteForm(String id) {
    setState(() => _forms.removeWhere((f) => f.id == id));
    _saveForms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Survey Forms'),
        backgroundColor: const Color(0xFF1a1a2e),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewForm,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
          ),
        ),
        child: _forms.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.description_outlined, size: 64, color: Colors.white38),
                    const SizedBox(height: 16),
                    const Text('No survey forms yet', style: TextStyle(color: Colors.white54, fontSize: 16)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _createNewForm,
                      icon: const Icon(Icons.add),
                      label: const Text('Create Form'),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _forms.length,
                itemBuilder: (context, index) {
                  final form = _forms[index];
                  return Card(
                    color: Colors.white.withOpacity(0.1),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.description, color: Colors.cyanAccent),
                      title: Text(form.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${form.fields.length} fields',
                        style: const TextStyle(color: Colors.white54),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white54),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'fill', child: Text('Fill Form')),
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                        onSelected: (value) {
                          if (value == 'fill') _fillForm(form);
                          else if (value == 'edit') _openFormEditor(form);
                          else if (value == 'delete') _deleteForm(form.id);
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class SurveyForm {
  final String id;
  final String name;
  final List<FormField> fields;
  final DateTime createdAt;

  SurveyForm({required this.id, required this.name, required this.fields, required this.createdAt});

  factory SurveyForm.fromJson(Map<String, dynamic> json) {
    return SurveyForm(
      id: json['id'] as String,
      name: json['name'] as String,
      fields: (json['fields'] as List).map((f) => FormField.fromJson(f as Map<String, dynamic>)).toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'fields': fields.map((f) => f.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };
}

class FormField {
  final String id;
  final String label;
  final FieldType type;
  final bool required;

  FormField({required this.id, required this.label, required this.type, this.required = false});

  factory FormField.fromJson(Map<String, dynamic> json) {
    return FormField(
      id: json['id'] as String,
      label: json['label'] as String,
      type: FieldType.values.firstWhere((e) => e.name == json['type']),
      required: json['required'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'type': type.name,
    'required': required,
  };
}

enum FieldType { text, number, date, dropdown, checkbox, textarea }

class _FormEditorSheet extends StatefulWidget {
  final SurveyForm form;
  final Function(SurveyForm) onSave;

  const _FormEditorSheet({required this.form, required this.onSave});

  @override
  State<_FormEditorSheet> createState() => _FormEditorSheetState();
}

class _FormEditorSheetState extends State<_FormEditorSheet> {
  late List<FormField> _fields;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _fields = List.from(widget.form.fields);
  }

  void _addField(FieldType type) {
    setState(() {
      _fields.add(FormField(id: _uuid.v4(), label: 'New Field', type: type));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1a1a2e),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Edit Form', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              _buildTypeChip('Text', FieldType.text),
              _buildTypeChip('Number', FieldType.number),
              _buildTypeChip('Date', FieldType.date),
              _buildTypeChip('Dropdown', FieldType.dropdown),
              _buildTypeChip('Checkbox', FieldType.checkbox),
              _buildTypeChip('Text Area', FieldType.textarea),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _fields.length,
              itemBuilder: (context, index) {
                final field = _fields[index];
                return ListTile(
                  leading: Icon(_getIconForType(field.type), color: Colors.cyanAccent),
                  title: Text(field.label, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(field.type.name, style: const TextStyle(color: Colors.white54)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => _fields.removeAt(index)),
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onSave(SurveyForm(
                id: widget.form.id,
                name: widget.form.name,
                fields: _fields,
                createdAt: widget.form.createdAt,
              ));
              Navigator.pop(context);
            },
            child: const Text('Save Form'),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, FieldType type) {
    return ActionChip(
      label: Text(label),
      onPressed: () => _addField(type),
    );
  }

  IconData _getIconForType(FieldType type) {
    switch (type) {
      case FieldType.text: return Icons.text_fields;
      case FieldType.number: return Icons.numbers;
      case FieldType.date: return Icons.calendar_today;
      case FieldType.dropdown: return Icons.arrow_drop_down_circle;
      case FieldType.checkbox: return Icons.check_box;
      case FieldType.textarea: return Icons.notes;
    }
  }
}

class _FormFillSheet extends StatefulWidget {
  final SurveyForm form;
  final Function(Map<String, dynamic>) onSubmit;

  const _FormFillSheet({required this.form, required this.onSubmit});

  @override
  State<_FormFillSheet> createState() => _FormFillSheetState();
}

class _FormFillSheetState extends State<_FormFillSheet> {
  final Map<String, dynamic> _responses = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1a1a2e),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.form.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: widget.form.fields.map((field) => _buildFieldInput(field)).toList(),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onSubmit(_responses);
              Navigator.pop(context);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldInput(FormField field) {
    switch (field.type) {
      case FieldType.text:
        return Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            decoration: InputDecoration(labelText: field.label, labelStyle: const TextStyle(color: Colors.white70)),
            style: const TextStyle(color: Colors.white),
            onChanged: (v) => _responses[field.id] = v,
          ),
        );
      case FieldType.number:
        return Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            decoration: InputDecoration(labelText: field.label, labelStyle: const TextStyle(color: Colors.white70)),
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            onChanged: (v) => _responses[field.id] = v,
          ),
        );
      case FieldType.date:
        return ListTile(
          title: Text(field.label, style: const TextStyle(color: Colors.white)),
          trailing: const Icon(Icons.calendar_today, color: Colors.white54),
          onTap: () async {
            final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
            if (date != null) _responses[field.id] = date.toString().substring(0, 10);
          },
        );
      case FieldType.dropdown:
        return ListTile(
          title: Text(field.label, style: const TextStyle(color: Colors.white)),
          trailing: const Icon(Icons.arrow_drop_down, color: Colors.white54),
          onTap: () {},
        );
      case FieldType.checkbox:
        return CheckboxListTile(
          title: Text(field.label, style: const TextStyle(color: Colors.white)),
          value: _responses[field.id] as bool? ?? false,
          onChanged: (v) => setState(() => _responses[field.id] = v),
        );
      case FieldType.textarea:
        return Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            decoration: InputDecoration(labelText: field.label, labelStyle: const TextStyle(color: Colors.white70)),
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            onChanged: (v) => _responses[field.id] = v,
          ),
        );
    }
  }
}