import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/localization/strings.dart';
import '../../core/config/environment.dart';
import '../../core/theme/app_theme.dart';
import '../models/models.dart';
import 'status_badge.dart';

class IncidentCard extends StatelessWidget {
  const IncidentCard(this.incident, {super.key, this.onTap});
  final Incident incident;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap ?? () => context.push('/incident/${incident.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusBadge(incident.status),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        incident.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat.yMMMd(
                          Localizations.localeOf(context).languageCode,
                        ).format(incident.createdAt.toLocal()),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 76,
                    height: 76,
                    child: incident.media.isEmpty
                        ? const ColoredBox(
                            color: AppPalette.softGreen,
                            child: Icon(
                              Icons.location_city_outlined,
                              color: AppPalette.green,
                              size: 30,
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: Environment.mediaUrl(
                              incident.media.first['thumbnail_url'] as String,
                            ),
                            fit: BoxFit.cover,
                            placeholder: (_, _) =>
                                const ColoredBox(color: AppPalette.softGreen),
                            errorWidget: (_, _, _) => const ColoredBox(
                              color: AppPalette.softGreen,
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: AppPalette.muted,
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                _Metadata(
                  Icons.flag_outlined,
                  '${context.l.priority}: ${incident.priorityScore.toStringAsFixed(0)}',
                ),
                _Metadata(
                  Icons.people_outline,
                  '${context.l.confirmations}: ${incident.confirmationCount}',
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _Metadata extends StatelessWidget {
  const _Metadata(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: AppPalette.muted),
      const SizedBox(width: 6),
      Flexible(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
    ],
  );
}
