import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'models/dua.dart';
import 'theme_constants.dart';
import 'package:intl/intl.dart';
import 'cubit/dua_cubit.dart';
import 'cubit/dua_states.dart';
import 'repository/dua_repository.dart';
import 'pages/dua_post_page.dart';

class DuasPage extends StatelessWidget {
  const DuasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DuaCubit(DuaRepository())..fetchDuas(),
      child: BlocBuilder<DuaCubit, DuaState>(
        builder: (context, state) {
          if (state.status == DuaStatus.loading) {
            return const Scaffold(
              appBar: _DuasAppBar(),
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (state.status == DuaStatus.error) {
            return const Scaffold(
              appBar: _DuasAppBar(),
              body: Center(child: Text('Gagal memuatkan doa.')),
            );
          } else if (state.duas.isEmpty) {
            return const Scaffold(
              appBar: _DuasAppBar(),
              body: Center(child: Text('Tiada doa tersedia.')),
            );
          }
          final duas = List<Dua>.from(state.duas.where((d) => !d.isHidden))
            ..sort((a, b) => (b.uploaded ?? DateTime(0)).compareTo(a.uploaded ?? DateTime(0)));
          return Scaffold(
            appBar: const _DuasAppBar(),
            body: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              itemCount: duas.length,
              itemBuilder: (context, i) {
                final dua = duas[i];
                return InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DuaPostPage(dua: dua),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Theme.of(context).cardColor,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (dua.image != null && dua.image!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: dua.image!.startsWith('http://') || dua.image!.startsWith('https://')
                                  ? Image.network(
                                      dua.image!,
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          height: 120,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                      loadingProgress.expectedTotalBytes!
                                                  : null,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          height: 120,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.image,
                                            color: Theme.of(context).colorScheme.primary,
                                            size: 40,
                                          ),
                                        );
                                      },
                                    )
                                  : dua.image!.startsWith('assets/')
                                      ? Image.asset(
                                          dua.image!,
                                          height: 120,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              height: 120,
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                Icons.image,
                                                color: Theme.of(context).colorScheme.primary,
                                                size: 40,
                                              ),
                                            );
                                          },
                                        )
                                      : Image.file(
                                          File(dua.image!),
                                          height: 120,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              height: 120,
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                Icons.image,
                                                color: Theme.of(context).colorScheme.primary,
                                                size: 40,
                                              ),
                                            );
                                          },
                                        ),
                            ),
                          ),
                        Text(
                          dua.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 15),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dua.content,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 13),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 16, color: AppColors.disabled),
                            const SizedBox(width: 6),
                            Text(
                              dua.uploaded != null
                                  ? DateFormat('EEE, d MMM yyyy • h:mm a').format(dua.uploaded!)
                                  : '-',
                              style: TextStyle(
                                color: AppColors.disabled,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _DuasAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _DuasAppBar();
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Doa'),
      backgroundColor: AppColors.appBar,
      foregroundColor: AppColors.onAppBar,
    );
  }
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

