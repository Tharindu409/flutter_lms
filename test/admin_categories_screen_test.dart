import 'package:flutter/material.dart';
import 'package:flutter_lms/features/admin/categories/admin_categories_provider.dart';
import 'package:flutter_lms/features/admin/categories/admin_categories_service.dart';
import 'package:flutter_lms/features/admin/core/admin_paged_data.dart';
import 'package:flutter_lms/features/admin/models/admin_models.dart';
import 'package:flutter_lms/features/admin/screens/admin_categories_screen.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/services/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('admin can create a category without inherited-scope errors', (
    tester,
  ) async {
    final service = _CategoriesService();
    final provider = AdminCategoriesProvider(service);
    addTearDown(provider.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<AdminCategoriesProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(body: AdminCategoriesScreen(onOpenMore: _noop)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Create category'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byType(TextFormField).at(0), 'Mobile');
    await tester.enterText(find.byType(TextFormField).at(1), 'Mobile apps');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Create category'), findsNothing);
    expect(find.text('Mobile'), findsOneWidget);
    expect(service.createdBody, {
      'name': 'Mobile',
      'description': 'Mobile apps',
    });
  });
}

void _noop() {}

class _CategoriesService extends AdminCategoriesService {
  _CategoriesService() : super(ApiClient(TokenStorage.memory()));

  Map<String, dynamic>? createdBody;
  var listCalls = 0;

  @override
  Future<AdminCategory> create(Map<String, dynamic> body) async {
    createdBody = Map.of(body);
    return const AdminCategory(
      id: 'category-id',
      name: 'Mobile',
      description: 'Mobile apps',
      slug: 'mobile',
      isActive: true,
    );
  }

  @override
  Future<AdminPagedData<AdminCategory>> list({
    int page = 1,
    int limit = 20,
    String search = '',
  }) async {
    listCalls++;
    return AdminPagedData(
      items: createdBody == null
          ? const []
          : const [
              AdminCategory(
                id: 'category-id',
                name: 'Mobile',
                description: 'Mobile apps',
                slug: 'mobile',
                isActive: true,
              ),
            ],
      page: 1,
      limit: 20,
      total: createdBody == null ? 0 : 1,
      totalPages: 1,
    );
  }
}
