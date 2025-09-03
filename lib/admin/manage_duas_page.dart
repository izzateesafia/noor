import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme_constants.dart';
import '../models/dua.dart';
import '../cubit/dua_cubit.dart';
import '../cubit/dua_states.dart';
import '../repository/dua_repository.dart';
import 'dua_form_page.dart';

class ManageDuasPage extends StatelessWidget {
  const ManageDuasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DuaCubit(DuaRepository())..fetchDuas(),
      child: const _ManageDuasView(),
    );
  }
}

class _ManageDuasView extends StatelessWidget {
  const _ManageDuasView();

  Future<void> _addDua(BuildContext context) async {
    final newDua = await Navigator.of(context).push<Dua>(
      MaterialPageRoute(builder: (context) => const DuaFormPage()),
    );
    if (newDua != null) {
      context.read<DuaCubit>().addDua(newDua);
    }
  }

  Future<void> _editDua(BuildContext context, Dua dua) async {
    final editedDua = await Navigator.of(context).push<Dua>(
      MaterialPageRoute(builder: (context) => DuaFormPage(initialDua: dua)),
    );
    if (editedDua != null) {
      context.read<DuaCubit>().updateDua(editedDua);
    }
  }

  void _deleteDua(BuildContext context, Dua dua) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Dua'),
        content: const Text('Are you sure you want to delete this dua?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<DuaCubit>().deleteDua(dua.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Duas'),
        backgroundColor: AppColors.appBar,
        foregroundColor: AppColors.onAppBar,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Dua',
            onPressed: () => _addDua(context),
          ),
        ],
      ),
      body: BlocBuilder<DuaCubit, DuaState>(
        builder: (context, state) {
          if (state.status == DuaStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state.status == DuaStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(state.error ?? 'An error occurred'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<DuaCubit>().fetchDuas(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state.duas.isEmpty) {
            return Center(
              child: Text(
                'No duas found. Tap + to add.',
                style: TextStyle(color: AppColors.disabled, fontSize: 18),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            itemCount: state.duas.length,
            itemBuilder: (context, i) {
              final dua = state.duas[i];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : AppColors.lightCard,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (dua.image != null && dua.image!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            dua.image!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dua.title,
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.text,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              dua.content,
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.text,
                                fontSize: 14,
                              ),
                            ),
                            if (dua.link != null && dua.link!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                dua.link!,
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                            if (dua.notes != null && dua.notes!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Notes: ${dua.notes!}',
                                style: TextStyle(
                                  color: AppColors.disabled,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            tooltip: 'Edit',
                            onPressed: () => _editDua(context, dua),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete',
                            onPressed: () => _deleteDua(context, dua),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 