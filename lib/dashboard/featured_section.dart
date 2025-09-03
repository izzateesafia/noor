import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme_constants.dart';
import '../cubit/class_cubit.dart';
import '../cubit/class_states.dart';
import '../models/class_model.dart';
import '../models/user_model.dart';
import '../class_payment_page.dart';
import '../models/dua.dart';
import '../models/hadith.dart';

class FeaturedSection extends StatelessWidget {
  final UserModel user;
  final List<Dua>? duas;
  final List<Hadith>? hadiths;
  
  const FeaturedSection({
    super.key, 
    required this.user, 
    this.duas, 
    this.hadiths,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocBuilder<ClassCubit, ClassState>(
          builder: (context, state) {
            Widget classSection;
            if (state.status == ClassStatus.loading) {
              classSection = const Center(child: CircularProgressIndicator());
            } else if (state.status == ClassStatus.error) {
              classSection = Center(child: Text('Failed to load classes', style: TextStyle(color: Theme.of(context).colorScheme.error)));
            } else if (state.status == ClassStatus.loaded && state.classes.isNotEmpty) {
              classSection = SizedBox(
                height: 190,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 0, right: 0),
                  children: state.classes.take(5).map((c) => _buildFeaturedClassCard(context, c, user)).toList(),
                ),
              );
            } else {
              classSection = Center(child: Text('No classes available', style: Theme.of(context).textTheme.bodyMedium));
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context, 'Featured Classes', Icons.school, '/classes'),
                const SizedBox(height: 12),
                classSection,
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        // Featured Duas Section
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, 'Featured Duas', Icons.favorite, '/duas'),
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                Widget duaSection;
                if (duas == null) {
                  duaSection = const Center(child: CircularProgressIndicator());
                } else if (duas!.isEmpty) {
                  duaSection = Center(child: Text('No duas available', style: Theme.of(context).textTheme.bodyMedium));
                } else {
                  duaSection = SizedBox(
                    height: 160,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 0, right: 0),
                      children: duas!.take(5).map((d) => _buildFeaturedDuaCard(context, d)).toList(),
                    ),
                  );
                }
                return duaSection;
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Featured Hadiths Section
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, 'Featured Hadiths', Icons.book, '/hadiths'),
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                Widget hadithSection;
                if (hadiths == null) {
                  hadithSection = const Center(child: CircularProgressIndicator());
                } else if (hadiths!.isEmpty) {
                  hadithSection = Center(child: Text('No hadiths available', style: Theme.of(context).textTheme.bodyMedium));
                } else {
                  hadithSection = SizedBox(
                    height: 160,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 0, right: 0),
                      children: hadiths!.take(5).map((h) => _buildFeaturedHadithCard(
                        context, 
                        h.title, 
                        h.content, 
                        h.narrator!,
                        h.image ?? 'assets/images/hadith_default.png'
                      )).toList(),
                    ),
                  );
                }
                return hadithSection;
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, String route) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextButton(
              onPressed: () => Navigator.of(context).pushNamed(route),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'View All',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedClassCard(BuildContext context, ClassModel classModel, UserModel user) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ClassPaymentPage(user: user, classModel: classModel),
          ),
        );
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 16),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: Theme.of(context).cardColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section with gradient overlay
              Container(
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      Theme.of(context).colorScheme.primary.withOpacity(0.6),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    if (classModel.image != null && classModel.image!.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        child: Image.asset(
                          classModel.image!,
                          width: double.infinity,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: double.infinity,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                              child: Icon(
                                Icons.school,
                                color: Theme.of(context).colorScheme.onPrimary,
                                size: 40,
                              ),
                            );
                          },
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.schedule,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content section
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classModel.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person, size: 12,        color: Theme.of(context).colorScheme.primary,),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            classModel.instructor,
                            style: Theme.of(context).textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 12, color: Theme.of(context).disabledColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            classModel.time,
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedDuaCard(BuildContext context, Dua dua) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dua.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (dua.image != null && dua.image!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    dua.image!,
                    height: 60,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              if (dua.image != null && dua.image!.isNotEmpty) const SizedBox(height: 8),
              Text(
                dua.content,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.3, fontStyle: FontStyle.italic),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
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
      ),
    );
  }

  Widget _buildFeaturedHadithCard(BuildContext context, String title, String content, String source, String? image) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Theme.of(context).cardColor,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with decorative elements
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Content with elegant styling
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.format_quote,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              content,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.3, fontStyle: FontStyle.italic),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Source with book icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.book,
                        size: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        source,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 