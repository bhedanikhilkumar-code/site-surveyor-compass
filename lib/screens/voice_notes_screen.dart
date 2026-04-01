import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../services/gps_service.dart';

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
    final path = '${dir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';

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
    if (path == null || !mounted) return;

    final gps = context.read<GpsService>();
    final note = VoiceNote(
      filePath: path,
      latitude: gps.latitude,
      longitude: gps.longitude,
      altitude: gps.altitude,
      timestamp: DateTime.now(),
      duration: _recordingDuration,
    );

    setState(() {
      _isRecording = false;
      _notes.insert(0, note);
    });
  }

  Future<void> _playNote(VoiceNote note) async {
    await _player.play(DeviceFileSource(note.filePath));
  }

  Future<void> _stopPlayback() async {
    await _player.stop();
  }

  Future<void> _deleteNote(VoiceNote note) async {
    try {
      await File(note.filePath).delete();
    } catch (_) {}
    setState(() => _notes.remove(note));
  }

  @override
  void dispose() {
    _isRecording = false;
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Notes'),
        elevation: 0,
      ),
      body: _notes.isEmpty && !_isRecording
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic, size: 80, color: Colors.grey[700]),
                  const SizedBox(height: 16),
                  Text('Hold mic button to record',
                      style: TextStyle(color: Colors.grey[500], fontSize: 16)),
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
          '${_recordingDuration.inMinutes.toString().padLeft(2, '0')}:${(_recordingDuration.inSeconds % 60).toString().padLeft(2, '0')}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildNoteTile(VoiceNote note) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.cyan.withOpacity(0.2),
          child: IconButton(
            icon: const Icon(Icons.play_arrow, color: Colors.cyan, size: 20),
            onPressed: () => _playNote(note),
          ),
        ),
        title: Text(
          'Note ${note.timestamp.day}/${note.timestamp.month} ${note.timestamp.hour.toString().padLeft(2, '0')}:${note.timestamp.minute.toString().padLeft(2, '0')}',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        subtitle: Text(
          '${note.duration.inSeconds}s'
          '${note.latitude != null ? ' | ${note.latitude!.toStringAsFixed(4)}, ${note.longitude!.toStringAsFixed(4)}' : ''}',
          style: const TextStyle(color: Colors.grey, fontSize: 11),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
          onPressed: () => _deleteNote(note),
        ),
      ),
    );
  }
}

class VoiceNote {
  final String filePath;
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final DateTime timestamp;
  final Duration duration;

  VoiceNote({
    required this.filePath,
    this.latitude,
    this.longitude,
    this.altitude,
    required this.timestamp,
    required this.duration,
  });
}
