import 'package:flutter/material.dart';

import '../../domain/favorite_entity_type.dart';
import '../../domain/favorites_repository.dart';
import '../favorites_scope.dart';

/// Bouton cœur pour ajouter ou retirer un favori depuis une barre d'app.
class FavoriteToggleButton extends StatefulWidget {
  const FavoriteToggleButton({
    super.key,
    required this.entityType,
    required this.entitySlug,
  });

  final FavoriteEntityType entityType;
  final String entitySlug;

  @override
  State<FavoriteToggleButton> createState() => _FavoriteToggleButtonState();
}

class _FavoriteToggleButtonState extends State<FavoriteToggleButton> {
  FavoritesRepository? _repository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = FavoritesScope.of(context);
    if (!identical(repository, _repository)) {
      _repository?.removeListener(_onFavoritesChanged);
      _repository = repository;
      _repository!.addListener(_onFavoritesChanged);
    }
  }

  @override
  void dispose() {
    _repository?.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) setState(() {});
  }

  bool get _isFavorite {
    return _repository!.isFavorite(
      entityType: widget.entityType,
      entitySlug: widget.entitySlug,
    );
  }

  Future<void> _toggleFavorite() async {
    await _repository!.toggleFavorite(
      entityType: widget.entityType,
      entitySlug: widget.entitySlug,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFavorite = _isFavorite;

    return IconButton(
      onPressed: _toggleFavorite,
      tooltip: isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite ? theme.colorScheme.primary : null,
      ),
    );
  }
}
