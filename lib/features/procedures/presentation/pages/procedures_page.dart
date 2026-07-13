import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_content_container.dart';
import '../../../../design_system/widgets/atlas_empty_state.dart';
import '../../../../design_system/widgets/atlas_page_header.dart';
import '../../../home/presentation/widgets/home_section_header.dart';
import '../../data/procedure_repository.dart';
import '../../domain/models/procedure_models.dart';
import '../pages/procedure_detail_page.dart';
import '../widgets/procedure_category_filter.dart';
import '../widgets/procedure_guide_card.dart';

/// Répond à : « Comment accomplir cette démarche administrative ? »
class ProceduresPage extends StatefulWidget {
  const ProceduresPage({super.key});

  @override
  State<ProceduresPage> createState() => _ProceduresPageState();
}

class _ProceduresPageState extends State<ProceduresPage> {
  final ProcedureRepository _repository = const ProcedureRepository();
  final TextEditingController _searchController = TextEditingController();

  ProcedureCategory? _selectedCategory;
  List<ProcedureGuide> _guides = const [];

  @override
  void initState() {
    super.initState();
    _guides = _repository.getAll();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      _guides = _repository.search(
        ProcedureSearchQuery(
          text: _searchController.text,
          category: _selectedCategory,
        ),
      );
    });
  }

  void _onCategorySelected(ProcedureCategory? category) {
    setState(() => _selectedCategory = category);
    _applyFilters();
  }

  void _openGuide(ProcedureGuide guide) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProcedureDetailPage(guide: guide),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AtlasContentContainer(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AtlasSpacing.section),
                  const AtlasPageHeader(
                    title: 'Démarches',
                    subtitle: 'Guides pas à pas pour vos démarches au Maroc.',
                  ),
                  const SizedBox(height: AtlasSpacing.xl),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Rechercher une démarche…',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.lg),
                  ProcedureCategoryFilter(
                    selectedCategory: _selectedCategory,
                    onCategorySelected: _onCategorySelected,
                  ),
                  const SizedBox(height: AtlasSpacing.xl),
                  const HomeSectionHeader(title: 'Guides disponibles'),
                  const SizedBox(height: AtlasSpacing.lg),
                ],
              ),
            ),
            if (_guides.isEmpty)
              const SliverToBoxAdapter(
                child: AtlasEmptyState(
                  message: 'Aucune démarche ne correspond à votre recherche.',
                ),
              )
            else
              SliverList.separated(
                itemCount: _guides.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AtlasSpacing.lg),
                itemBuilder: (context, index) {
                  final guide = _guides[index];
                  return ProcedureGuideCard(
                    guide: guide,
                    onTap: () => _openGuide(guide),
                  );
                },
              ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AtlasSpacing.sectionLarge),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ouvre un guide depuis n'importe quel écran de l'application.
void openProcedureGuide(BuildContext context, ProcedureGuide guide) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ProcedureDetailPage(guide: guide),
    ),
  );
}

/// Ouvre un guide par identifiant ; ne fait rien si introuvable.
void openProcedureGuideById(
  BuildContext context,
  ProcedureRepository repository,
  String procedureId,
) {
  final guide = repository.findById(procedureId);
  if (guide == null) return;
  openProcedureGuide(context, guide);
}
