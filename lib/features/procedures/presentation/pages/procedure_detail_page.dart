import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_content_container.dart';
import '../../domain/models/procedure_models.dart';

/// Détail d'une démarche — étapes, documents et lien officiel.
class ProcedureDetailPage extends StatelessWidget {
  const ProcedureDetailPage({
    super.key,
    required this.guide,
  });

  final ProcedureGuide guide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(guide.title),
      ),
      body: SafeArea(
        child: AtlasContentContainer(
          child: ListView(
            padding: const EdgeInsets.only(
              top: AtlasSpacing.section,
              bottom: AtlasSpacing.sectionLarge,
            ),
            children: [
            Row(
              children: [
                Icon(
                  guide.icon,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: AtlasSpacing.md),
                Expanded(
                  child: Text(
                    guide.categoryLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AtlasSpacing.lg),
            Text(
              guide.summary,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AtlasSpacing.xl),
            _InfoRow(
              icon: Icons.schedule_outlined,
              label: 'Délai estimé',
              value: guide.estimatedDuration,
            ),
            const SizedBox(height: AtlasSpacing.sectionLarge),
            Text(
              'Documents requis',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AtlasSpacing.md),
            for (final document in guide.documents) ...[
              _BulletItem(text: document),
              const SizedBox(height: AtlasSpacing.sm),
            ],
            const SizedBox(height: AtlasSpacing.section),
            Text(
              'Étapes',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AtlasSpacing.md),
            for (var i = 0; i < guide.steps.length; i++) ...[
              _StepItem(
                index: i + 1,
                text: guide.steps[i],
              ),
              const SizedBox(height: AtlasSpacing.md),
            ],
            if (guide.officialUrl != null) ...[
              const SizedBox(height: AtlasSpacing.section),
              Text(
                'Lien officiel',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AtlasSpacing.sm),
              SelectableText(
                guide.officialUrl!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AtlasSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AtlasSpacing.xs),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BulletItem extends StatelessWidget {
  const _BulletItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '•',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: AtlasSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.index,
    required this.text,
  });

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$index',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: AtlasSpacing.md),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: AtlasSpacing.xs),
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.45,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
