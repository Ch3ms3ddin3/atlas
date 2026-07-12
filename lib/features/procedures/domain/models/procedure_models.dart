import 'package:flutter/material.dart';

/// Catégories de démarches administratives au Maroc.
enum ProcedureCategory {
  identite,
  sejour,
  vehicule,
  transport,
}

/// Guide pas à pas d'une démarche administrative.
class ProcedureGuide {
  const ProcedureGuide({
    required this.id,
    required this.title,
    required this.summary,
    required this.category,
    required this.categoryLabel,
    required this.estimatedDuration,
    required this.documents,
    required this.steps,
    required this.icon,
    this.officialUrl,
  });

  final String id;
  final String title;
  final String summary;
  final ProcedureCategory category;
  final String categoryLabel;
  final String estimatedDuration;
  final List<String> documents;
  final List<String> steps;
  final IconData icon;
  final String? officialUrl;
}

/// Filtre de recherche pour la liste des démarches.
class ProcedureSearchQuery {
  const ProcedureSearchQuery({
    this.text = '',
    this.category,
  });

  final String text;
  final ProcedureCategory? category;
}
