import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lms/features/admin/categories/admin_categories_provider.dart';
import 'package:flutter_lms/features/admin/models/admin_models.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:flutter_lms/widgets/confirm_dialog.dart';
import 'package:provider/provider.dart';

import 'admin_screen_components.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key, required this.onOpenMore});

  final VoidCallback onOpenMore;

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminCategoriesProvider>().load();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _edit([AdminCategory? category]) async {
    final provider = context.read<AdminCategoriesProvider>();
    await showDialog<void>(
      context: context,
      builder: (_) => ChangeNotifierProvider<AdminCategoriesProvider>.value(
        value: provider,
        child: _AdminCategoryDialog(category: category, onError: _message),
      ),
    );
  }

  Future<void> _toggle(AdminCategory category) async {
    final active = !category.isActive;
    final accepted = await showConfirmDialog(
      context,
      title: active ? 'Activate category?' : 'Deactivate category?',
      message: active
          ? 'This category will become available for course creation.'
          : 'Courses currently using it may prevent deactivation.',
      confirmLabel: active ? 'Activate' : 'Deactivate',
    );
    if (!mounted || !accepted) return;
    try {
      await context.read<AdminCategoriesProvider>().setCategoryActive(
        category,
        active,
      );
    } on ApiException catch (error) {
      _message(error.message);
    }
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminCategoriesProvider>(
      builder: (context, provider, _) => Column(
        children: [
          AdminHeader(
            title: 'Categories',
            subtitle: 'Organize courses into topics',
            action: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                adminMoreButton(widget.onOpenMore),
                IconButton(
                  onPressed: provider.isSubmitting ? null : () => _edit(),
                  icon: const Icon(Icons.add),
                  tooltip: 'Create category',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              onChanged: (_) {
                _debounce?.cancel();
                _debounce = Timer(
                  const Duration(milliseconds: 400),
                  () => provider.search(_search.text.trim()),
                );
              },
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search categories',
              ),
            ),
          ),
          Expanded(
            child: adminPagedBody<AdminCategory>(
              provider: provider,
              title: 'No categories found',
              onRefresh: () => provider.load(refresh: true),
              itemBuilder: (category) => Card(
                child: ListTile(
                  title: Text(category.name),
                  subtitle: Text(category.description),
                  leading: AdminStatusBadge(
                    value: category.isActive ? 'ACTIVE' : 'INACTIVE',
                  ),
                  trailing: PopupMenuButton<String>(
                    enabled: !provider.isSubmitting,
                    onSelected: (action) {
                      if (action == 'edit') _edit(category);
                      if (action == 'toggle') _toggle(category);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(
                          category.isActive ? 'Deactivate' : 'Activate',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminCategoryDialog extends StatefulWidget {
  const _AdminCategoryDialog({required this.category, required this.onError});

  final AdminCategory? category;
  final ValueChanged<String> onError;

  @override
  State<_AdminCategoryDialog> createState() => _AdminCategoryDialogState();
}

class _AdminCategoryDialogState extends State<_AdminCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.category?.name ?? '');
    _description = TextEditingController(
      text: widget.category?.description ?? '',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final provider = context.read<AdminCategoriesProvider>();
    try {
      final category = widget.category;
      if (category == null) {
        await provider.createCategory(
          _name.text.trim(),
          _description.text.trim(),
        );
      } else {
        await provider.updateCategory(
          category,
          name: _name.text.trim(),
          description: _description.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context);
    } on ApiException catch (error) {
      widget.onError(error.message);
    }
  }

  @override
  Widget build(BuildContext context) => Consumer<AdminCategoriesProvider>(
    builder: (context, provider, _) => AlertDialog(
      title: Text(
        widget.category == null ? 'Create category' : 'Edit category',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Name is required'
                    : null,
              ),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Description is required'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: provider.isSubmitting ? null : _save,
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
