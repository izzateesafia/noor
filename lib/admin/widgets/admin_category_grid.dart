import 'package:flutter/material.dart';

class AdminCategory {
  final String title;
  final List<AdminCategoryItem> items;
  final Color color;

  AdminCategory({
    required this.title,
    required this.items,
    required this.color,
  });
}

class AdminCategoryItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int? badgeCount;
  final Color? color;

  AdminCategoryItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeCount,
    this.color,
  });
}

class AdminCategoryGrid extends StatelessWidget {
  final List<AdminCategory> categories;

  const AdminCategoryGrid({
    super.key,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categories.map((category) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: category.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      category.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: category.items.length,
                    itemBuilder: (context, index) {
                      return _CategoryItemCard(
                        item: category.items[index],
                        categoryColor: category.color,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _CategoryItemCard extends StatelessWidget {
  final AdminCategoryItem item;
  final Color categoryColor;

  const _CategoryItemCard({
    required this.item,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor = item.color ?? categoryColor;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: itemColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: itemColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item.icon,
                      color: itemColor,
                      size: 28,
                    ),
                  ),
                  if (item.badgeCount != null && item.badgeCount! > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: itemColor,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          item.badgeCount! > 99 ? '99+' : item.badgeCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

