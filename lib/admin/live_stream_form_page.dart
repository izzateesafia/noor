import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/live_stream_cubit.dart';
import '../cubit/live_stream_states.dart';
import '../models/live_stream.dart';

class LiveStreamFormPage extends StatefulWidget {
  final LiveStream? liveStream;

  const LiveStreamFormPage({super.key, this.liveStream});

  @override
  State<LiveStreamFormPage> createState() => _LiveStreamFormPageState();
}

class _LiveStreamFormPageState extends State<LiveStreamFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tiktokLinkController = TextEditingController();
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.liveStream != null) {
      _titleController.text = widget.liveStream!.title;
      _descriptionController.text = widget.liveStream!.description;
      _tiktokLinkController.text = widget.liveStream!.tiktokLiveLink;
      _isActive = widget.liveStream!.isActive;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tiktokLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.liveStream == null ? 'Add Live Stream' : 'Edit Live Stream'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        actions: [
          if (widget.liveStream != null)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveLiveStream,
            ),
        ],
      ),
      body: BlocConsumer<LiveStreamCubit, LiveStreamState>(
        listener: (context, state) {
          if (state is LiveStreamSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          } else if (state is LiveStreamError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Title Field
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Live Stream Title *',
                    hintText: 'Enter the title of your live stream',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description Field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    hintText: 'Enter a description for your live stream',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // TikTok Live Link Field
                TextFormField(
                  controller: _tiktokLinkController,
                  decoration: const InputDecoration(
                    labelText: 'Live Stream Link *',
                    hintText: 'Enter the live stream URL',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the live stream link';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Active Status Toggle
                Card(
                  child: SwitchListTile(
                    title: const Text('Active Live Stream'),
                    subtitle: const Text('Make this the current active live stream'),
                    value: _isActive,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value;
                      });
                    },
                    secondary: Icon(
                      _isActive ? Icons.live_tv : Icons.tv_off,
                      color: _isActive ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Save Button
                if (widget.liveStream == null)
                  ElevatedButton.icon(
                    onPressed: state is LiveStreamLoading ? null : _saveLiveStream,
                    icon: state is LiveStreamLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      state is LiveStreamLoading ? 'Saving...' : 'Save Live Stream',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),

                const SizedBox(height: 16),

                // Help Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'How to get Live Stream Link:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '1. Go to your live stream platform\n'
                          '2. Find the share or copy link option\n'
                          '3. Copy the live stream URL\n'
                          '4. Paste the link here',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _saveLiveStream() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.liveStream == null) {
      // Add new live stream
      context.read<LiveStreamCubit>().addLiveStream(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        tiktokLiveLink: _tiktokLinkController.text.trim(),
      );
    } else {
      // Update existing live stream
      final updatedLiveStream = widget.liveStream!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        tiktokLiveLink: _tiktokLinkController.text.trim(),
        isActive: _isActive,
      );
      context.read<LiveStreamCubit>().updateLiveStream(updatedLiveStream);
    }
  }
} 