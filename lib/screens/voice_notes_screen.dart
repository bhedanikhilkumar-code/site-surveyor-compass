import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../services/gps_service.dart';
import '../models/voice_note_model.dart';

class VoiceNotesScreen extends StatefulWidget {
  const VoiceNotesScreen({Key? key}) : super(key: key);

  @override
  State<VoiceNotesScreen> createState() => _VoiceNotesScreenState();
}

class _VoiceNotesScreenState extends State<VoiceNotesScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final List<VoiceNote> _notes = [];
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Box<VoiceNote>? _voiceBox;
  bool _isLoading = true;
  String? _playingNoteId;

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    try {
      _voiceBox = await Hive.openBox<VoiceNote>('voice_notes');
      _loadNotes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize voice notes: $e')),
        );
      }
    }
  }

  void _loadNotes() {
    if (_voiceBox == null) return;
    final notes = _voiceBox!.values.toList();
    notes.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    setState(() {
      _notes.clear();
      _notes.addAll(notes);
      _isLoading = false;
    });
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required')),
        );
      }
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final id = const Uuid().v4();
    final path = '${dir.path}/voice_note_$id.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );

    setState(() {
      _isRecording = true;
      _recordingDuration = Duration.zero;
    });

    _countDuration();
  }

  void _countDuration() async {
    while (_isRecording) {
      await Future.delayed(const Duration(seconds: 1));
      if (_isRecording && mounted) {
        setState(() => _recordingDuration += const Duration(seconds: 1));
      }
    }
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    if (path == null || mounted == false) return;

    final gps = context.read<GpsService>();
    final id = const Uuid().v4();
    final now = DateTime.now();

    final note = VoiceNote(
      id: id,
      filePath: path,
      timestamp: now,
      latitude: gps.latitude,
      longitude: gps.longitude,
      durationMs: _recordingDuration.inMilliseconds,
      name: 'Voice Note ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
    );

    try {
      await _voiceBox?.put(id, note);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save voice note: $e')),
        );
      }
    }

    setState(() {
      _isRecording = false;
      _notes.insert(0, note);
    });
  }

  Future<void> _playNote(VoiceNote note) async {
    try {
      if (_playingNoteId == note.id) {
        await _player.stop();
        setState(() => _playingNoteId = null);
        return;
      }

      await _player.stop();
      await _player.play(DeviceFileSource(note.filePath));
      setState(() => _playingNoteId = note.id);

      _player.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() => _playingNoteId = null);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to play note: $e')),
        );
      }
    }
  }

  Future<void> _stopPlayback() async {
    await _player.stop();
    if (mounted) {
      setState(() => _playingNoteId = null);
    }
  }

  Future<void> _deleteNote(VoiceNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Voice Note', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this voice note?', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.cyan)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await File(note.filePath).delete();
    } catch (_) {}

    try {
      await _voiceBox?.delete(note.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete from storage: $e')),
        );
      }
    }

    setState(() => _notes.remove(note));
  }

  Future<void> _renameNote(VoiceNote note) async {
    final controller = TextEditingController(text: note.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Rename Voice Note', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Name',
            labelStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.cyan),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel', style: TextStyle(color: Colors.cyan)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save', style: TextStyle(color: Colors.cyan)),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty) return;

    note.name = newName;
    try {
      await note.save();
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to rename note: $e')),
        );
      }
    }
  }

  Future<void> _shareNote(VoiceNote note) async {
    try {
      final file = File(note.filePath);
      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Audio file not found')),
          );
        }
        return;
      }

      await Share.shareXFiles(
        [XFile(note.filePath)],
        subject: note.name,
        text: 'Voice Note - ${note.timestamp.toString()}\n'
            '${note.latitude != null ? 'Location: ${note.latitude!.toStringAsFixed(4)}, ${note.longitude!.toStringAsFixed(4)}' : 'No GPS data'}\n'
            'Duration: ${note.duration.inMinutes.toString().padLeft(2, '0')}:${(note.duration.inSeconds % 60).toString().padLeft(2, '0')}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share note: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _isRecording = false;
    _recorder.dispose();
    _player.dispose();
    _voiceBox?.close();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    return '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Notes'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.stop, color: Colors.red),
            onPressed: _isRecording ? _stopRecording : null,
            tooltip: 'Stop Recording',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
          : _notes.isEmpty && !_isRecording
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mic, size: 80, color: Colors.grey[700]),
                      const SizedBox(height: 16),
                      Text(
                        'Hold mic button to record',
                        style: TextStyle(color: Colors.grey[500], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _notes.length + (_isRecording ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isRecording && index == 0) {
                      return _buildRecordingIndicator();
                    }
                    final note = _notes[_isRecording ? index - 1 : index];
                    return _buildNoteTile(note);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isRecording ? _stopRecording : _startRecording,
        backgroundColor: _isRecording ? Colors.red : Colors.cyan,
        child: Icon(_isRecording ? Icons.stop : Icons.mic),
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    return Card(
      color: Colors.red.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2),
        ),
        title: const Text('Recording...', style: TextStyle(color: Colors.red)),
        subtitle: Text(
          _formatDuration(_recordingDuration),
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildNoteTile(VoiceNote note) {
    final isPlaying = _playingNoteId == note.id;

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPlaying
              ? Colors.cyan.withOpacity(0.5)
              : Colors.cyan.withOpacity(0.2),
          child: IconButton(
            icon: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.cyan,
              size: 20,
            ),
            onPressed: () => _playNote(note),
          ),
        ),
        title: Text(
          note.name,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Duration: ${_formatDuration(note.duration)}',
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
            if (note.latitude != null && note.longitude != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'GPS: ${note.latitude!.toStringAsFixed(4)}, ${note.longitude!.toStringAsFixed(4)}',
                  style: TextStyle(color: Colors.cyan.withOpacity(0.7), fontSize: 11),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.cyan, size: 20),
              onPressed: () => _renameNote(note),
              tooltip: 'Rename',
            ),
            IconButton(
              icon: const Icon(Icons.share, color: Colors.cyan, size: 20),
              onPressed: () => _shareNote(note),
              tooltip: 'Share',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () => _deleteNote(note),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}
