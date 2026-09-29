import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/localization/strings.dart';
import '../../core/config/environment.dart';
import '../models/models.dart';

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
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 82,
                height: 90,
                child: incident.media.isEmpty
                    ? const ColoredBox(
                        color: Color(0xFFE4EFE8),
                        child: Icon(Icons.location_city_rounded),
                      )
                    : CachedNetworkImage(
                        imageUrl: Environment.mediaUrl(
                          incident.media.first['thumbnail_url'] as String,
                        ),
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) =>
                            const Icon(Icons.image_not_supported_outlined),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.statusLabel(incident.status),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    incident.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${context.l.priority}: ${incident.priorityScore.toStringAsFixed(0)} · ${incident.confirmationCount} ${context.l.confirmations.toLowerCase()}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    DateFormat.yMMMd(
                      Localizations.localeOf(context).languageCode,
                    ).format(incident.createdAt.toLocal()),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
