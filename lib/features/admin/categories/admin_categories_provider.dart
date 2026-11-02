import 'package:flutter_lms/features/admin/core/admin_paged_provider.dart';
import 'package:flutter_lms/features/admin/models/admin_models.dart';
import 'package:flutter_lms/features/admin/categories/admin_categories_service.dart';

class AdminCategoriesProvider extends AdminPagedProvider<AdminCategory> {
  AdminCategoriesProvider(this.service)
    : super(
        (page, filters) =>
            service.list(page: page, search: filters['search'] ?? ''),
      );

  final AdminCategoriesService service;
  AdminCategory? selectedCategory;

  Future<void> search(String value) => applyFilters({'search': value});

  Future<void> createCategory(String name, String description) async {
    final created = await runAction(
      () => service.create({'name': name, 'description': description}),
    );
    selectedCategory = created;
    await applyFilters(Map<String, String>.of(filters));
  }

  Future<void> updateCategory(
    AdminCategory original, {
    required String name,
    required String description,
  }) async {
    final body = <String, dynamic>{};
    if (name != original.name) body['name'] = name;
    if (description != original.description) {
      body['description'] = description;
    }
    if (body.isEmpty) return;
    final updated = await runAction(() => service.update(original.id, body));
    selectedCategory = updated;
    replaceItem((category) => category.id == original.id, updated);
  }

  Future<void> setCategoryActive(AdminCategory category, bool isActive) async {
    final updated = await runAction(
      () => service.setActive(category.id, isActive),
    );
    selectedCategory = updated;
    replaceItem((item) => item.id == category.id, updated);
  }

  void selectCategory(AdminCategory? value) {
    selectedCategory = value;
    notifySafely();
  }

  @override
  void reset() {
    selectedCategory = null;
    super.reset();
  }
}
