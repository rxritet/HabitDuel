import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/duel_provider.dart';

class CreateDuelScreen extends ConsumerStatefulWidget {
  const CreateDuelScreen({super.key});

  @override
  ConsumerState<CreateDuelScreen> createState() => _CreateDuelScreenState();
}

class _CreateDuelScreenState extends ConsumerState<CreateDuelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _habitCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _opponentCtrl = TextEditingController();
  int _durationDays = 21;

  static const _durations = [7, 14, 21, 30];

  @override
  void dispose() {
    _habitCtrl.dispose();
    _descCtrl.dispose();
    _opponentCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(createDuelProvider.notifier).create(
          habitName: _habitCtrl.text.trim(),
          description:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          durationDays: _durationDays,
          opponentUsername: _opponentCtrl.text.trim().isEmpty
              ? null
              : _opponentCtrl.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CreateDuelState>(createDuelProvider, (prev, next) {
      if (next is CreateDuelSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Duel created!')),
        );
        ref.read(createDuelProvider.notifier).reset();
        ref.read(duelsListProvider.notifier).load();
        Navigator.pop(context);
      } else if (next is CreateDuelError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message)),
        );
      }
    });

    final state = ref.watch(createDuelProvider);
    final isLoading = state is CreateDuelLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Duel')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _habitCtrl,
                decoration: const InputDecoration(
                  labelText: 'Habit name *',
                  hintText: 'e.g. Morning meditation',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _opponentCtrl,
                decoration: const InputDecoration(
                  labelText: 'Opponent username (optional)',
                  hintText: 'Leave empty for open challenge',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),
              Text(
                'Duration',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: _durations
                    .map((d) => ButtonSegment(
                          value: d,
                          label: Text('$d days'),
                        ))
                    .toList(),
                selected: {_durationDays},
                onSelectionChanged: (v) =>
                    setState(() => _durationDays = v.first),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Duel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
