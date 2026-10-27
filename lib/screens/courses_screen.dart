import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lms/providers/course_catalog_provider.dart';
import 'package:flutter_lms/utils/app_routes.dart';
import 'package:flutter_lms/widgets/course_card.dart';
import 'package:flutter_lms/widgets/state_views.dart';
import 'package:provider/provider.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  static const _anyLanguage = '__ANY_LANGUAGE__';
  static const _levels = {
    'BEGINNER': 'Beginner',
    'INTERMEDIATE': 'Intermediate',
    'ADVANCED': 'Advanced',
    'ALL_LEVELS': 'All levels',
  };

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.text = context.read<CourseCatalogProvider>().search;
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CourseCatalogProvider>().init();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      context.read<CourseCatalogProvider>().loadMore();
    }
  }

  void _onSearchChanged(String value) {
    setState(() {}); // shows or hides the clear button
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) context.read<CourseCatalogProvider>().setSearch(value);
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {});
    context.read<CourseCatalogProvider>().setSearch('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse courses'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Filter by level',
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => context
                .read<CourseCatalogProvider>()
                .selectLevel(value == 'ANY' ? null : value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'ANY', child: Text('Any level')),
              for (final entry in _levels.entries)
                PopupMenuItem(value: entry.key, child: Text(entry.value)),
            ],
          ),
        ],
      ),
      body: Consumer<CourseCatalogProvider>(
        builder: (context, catalog, _) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search courses',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _clearSearch,
                        ),
                ),
              ),
            ),
            if (catalog.categoriesError != null)
              MaterialBanner(
                content: Text(
                  'Course categories could not be loaded. You can still browse courses.',
                ),
                leading: const Icon(Icons.info_outline),
                actions: [
                  TextButton(
                    onPressed: catalog.isLoadingCategories
                        ? null
                        : catalog.retryCategories,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            if (catalog.isLoadingCategories &&
                catalog.categories.isEmpty &&
                catalog.categoriesError == null)
              const LinearProgressIndicator(),
            _filterRow(catalog),
            Expanded(child: _content(catalog)),
          ],
        ),
      ),
    );
  }

  Widget _filterRow(CourseCatalogProvider catalog) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          if (catalog.categoriesLoaded && catalog.categories.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: Text('No active categories'),
            ),
          if (catalog.selectedLevel != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InputChip(
                label: Text(
                  _levels[catalog.selectedLevel] ?? catalog.selectedLevel!,
                ),
                onDeleted: () => catalog.selectLevel(null),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('All'),
              selected: catalog.selectedCategoryId == null,
              onSelected: (_) => catalog.selectCategory(null),
            ),
          ),
          for (final category in catalog.categories)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(category.name),
                selected: catalog.selectedCategoryId == category.id,
                onSelected: (_) => catalog.selectCategory(category.id),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: SizedBox(
              width: 170,
              child: DropdownButtonFormField<String>(
                initialValue: catalog.selectedLanguage ?? _anyLanguage,
                decoration: const InputDecoration(
                  labelText: 'Language',
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: _anyLanguage,
                    child: Text('Any language'),
                  ),
                  for (final language in catalog.availableLanguages)
                    DropdownMenuItem(value: language, child: Text(language)),
                ],
                onChanged: (value) => catalog.selectLanguage(
                  value == _anyLanguage ? null : value,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(CourseCatalogProvider catalog) {
    if (catalog.isLoading && catalog.courses.isEmpty) {
      return const LoadingView(message: 'Loading courses...');
    }

    if (catalog.errorMessage != null && catalog.courses.isEmpty) {
      return ErrorView(
        message: catalog.errorMessage!,
        onRetry: catalog.refresh,
      );
    }

    if (catalog.courses.isEmpty) {
      final filtered =
          catalog.search.isNotEmpty ||
          catalog.selectedCategoryId != null ||
          catalog.selectedLevel != null ||
          catalog.selectedLanguage != null;
      return EmptyView(
        icon: Icons.search_off,
        title: filtered ? 'No courses match your filters' : 'No courses yet',
        message: filtered
            ? 'Try a different search or clear the filters.'
            : 'Check back later for new courses.',
      );
    }

    return RefreshIndicator(
      onRefresh: catalog.refresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: catalog.courses.length + 1,
        itemBuilder: (context, index) {
          if (index == catalog.courses.length) return _listFooter(catalog);

          final course = catalog.courses[index];
          return CourseCard(
            course: course,
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.courseDetail,
              arguments: course.id,
            ),
          );
        },
      ),
    );
  }

  Widget _listFooter(CourseCatalogProvider catalog) {
    if (catalog.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (catalog.loadMoreError != null) {
      return Center(
        child: TextButton.icon(
          onPressed: catalog.loadMore,
          icon: const Icon(Icons.refresh),
          label: Text('${catalog.loadMoreError} Tap to retry'),
        ),
      );
    }

    return const SizedBox(height: 8);
  }
}
