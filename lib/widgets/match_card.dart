import 'package:flutter/material.dart';
import 'package:skip_the_chase/models/match.dart';
import 'package:timeago/timeago.dart' as timeago;

class MatchCard extends StatelessWidget {
  final Match match;
  final VoidCallback onTap;

  const MatchCard({
    super.key,
    required this.match,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lastMessage = match.lastMessage;
    
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: match.matchedUser.avatarUrl != null
            ? NetworkImage(match.matchedUser.avatarUrl!)
            : null,
        child: match.matchedUser.avatarUrl == null
            ? Text(match.matchedUser.name[0])
            : null,
      ),
      title: Text(
        match.matchedUser.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: lastMessage != null
          ? Text(
              lastMessage.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : Text(
              'Matched ${timeago.format(match.createdAt)}',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
      trailing: lastMessage != null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeago.format(lastMessage.createdAt, locale: 'en_short'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                if (!lastMessage.isRead)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            )
          : null,
      onTap: onTap,
    );
  }
}