import 'package:flutter/material.dart';

/// Page de présentation des propositions d'icônes pour chaque menu
/// de l'application Grand Public.
/// A utiliser uniquement pour capture d'écran / choix d'équipe.
class IconSceneScreen extends StatelessWidget {
  const IconSceneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Propositions d\'icônes — Grand Public'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _IconSection(
            title: 'Média',
            subtitle: 'Témoignages, événements, direct, Premium',
            color: Color(0xFFE53935),
            icons: [
              _IconOption(Icons.videocam_outlined, 'video'),
              _IconOption(Icons.play_circle_outline, 'play_circle'),
              _IconOption(Icons.movie_outlined, 'film'),
              _IconOption(Icons.theaters_outlined, 'clapperboard'),
              _IconOption(Icons.live_tv_outlined, 'tv'),
              _IconOption(Icons.cell_tower_outlined, 'radio_tower'),
              _IconOption(Icons.fiber_manual_record, 'live_dot'),
              _IconOption(Icons.smart_display_outlined, 'monitor_play'),
              _IconOption(Icons.cast_outlined, 'airplay'),
              _IconOption(Icons.auto_awesome_outlined, 'sparkles'),
              _IconOption(Icons.workspace_premium_outlined, 'crown'),
              _IconOption(Icons.lock_outline, 'lock'),
              _IconOption(Icons.lock_open_outlined, 'unlock'),
              _IconOption(Icons.camera_alt_outlined, 'camera'),
              _IconOption(Icons.mic_none_outlined, 'mic'),
              _IconOption(Icons.calendar_today_outlined, 'calendar'),
              _IconOption(Icons.grid_view_outlined, 'grid'),
            ],
          ),
          SizedBox(height: 28),
          _IconSection(
            title: 'Social — Chat',
            subtitle: 'Canaux, discussions privées',
            color: Color(0xFF1E88E5),
            icons: [
              _IconOption(Icons.chat_bubble_outline, 'message_circle'),
              _IconOption(Icons.sms_outlined, 'message_square'),
              _IconOption(Icons.forum_outlined, 'messages_square'),
              _IconOption(Icons.group_outlined, 'users'),
              _IconOption(Icons.tag, 'hash'),
              _IconOption(Icons.send_outlined, 'send'),
              _IconOption(Icons.mic_none_outlined, 'mic'),
              _IconOption(Icons.alternate_email, 'at_sign'),
              _IconOption(Icons.public_outlined, 'globe'),
              _IconOption(Icons.lock_outline, 'lock'),
            ],
          ),
          SizedBox(height: 28),
          _IconSection(
            title: 'Social — Dating',
            subtitle: 'Rencontres, affinités',
            color: Color(0xFFD81B60),
            icons: [
              _IconOption(Icons.favorite_border, 'heart'),
              _IconOption(Icons.volunteer_activism_outlined, 'heart_handshake'),
              _IconOption(Icons.local_fire_department_outlined, 'flame'),
              _IconOption(Icons.groups_2_outlined, 'users_round'),
              _IconOption(Icons.auto_awesome_outlined, 'sparkle'),
              _IconOption(Icons.star_border, 'star'),
              _IconOption(Icons.person_add_alt_outlined, 'user_plus'),
              _IconOption(Icons.shuffle_outlined, 'shuffle'),
              _IconOption(Icons.location_on_outlined, 'map_pin'),
              _IconOption(Icons.sentiment_satisfied_alt_outlined, 'smile'),
            ],
          ),
          SizedBox(height: 28),
          _IconSection(
            title: 'Social — Bizz',
            subtitle: 'Annonces, marché local',
            color: Color(0xFF43A047),
            icons: [
              _IconOption(Icons.shopping_bag_outlined, 'shopping_bag'),
              _IconOption(Icons.storefront_outlined, 'store'),
              _IconOption(Icons.sell_outlined, 'tag'),
              _IconOption(Icons.inventory_2_outlined, 'package'),
              _IconOption(Icons.payments_outlined, 'hand_coins'),
              _IconOption(Icons.location_on_outlined, 'map_pin'),
              _IconOption(Icons.playlist_add_outlined, 'list_plus'),
              _IconOption(Icons.verified_outlined, 'badge_check'),
              _IconOption(Icons.account_balance_wallet_outlined, 'wallet'),
              _IconOption(Icons.search_outlined, 'search'),
            ],
          ),
          SizedBox(height: 28),
          _IconSection(
            title: 'Club',
            subtitle: 'Promotions et avantages partenaires',
            color: Color(0xFFFB8C00),
            icons: [
              _IconOption(Icons.confirmation_number_outlined, 'ticket'),
              _IconOption(Icons.card_giftcard_outlined, 'gift'),
              _IconOption(Icons.percent_outlined, 'percent'),
              _IconOption(Icons.local_offer_outlined, 'badge_percent'),
              _IconOption(Icons.star_border, 'star'),
              _IconOption(Icons.handshake_outlined, 'handshake'),
              _IconOption(Icons.workspace_premium_outlined, 'crown'),
              _IconOption(Icons.emoji_events_outlined, 'award'),
              _IconOption(Icons.shopping_bag_outlined, 'shopping_bag'),
              _IconOption(Icons.bolt_outlined, 'zap'),
            ],
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _IconOption {
  final IconData icon;
  final String label;
  const _IconOption(this.icon, this.label);
}

class _IconSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final List<_IconOption> icons;

  const _IconSection({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icons,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: icons.map((opt) => _IconTile(opt: opt, color: color)).toList(),
          ),
        ],
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final _IconOption opt;
  final Color color;

  const _IconTile({required this.opt, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(opt.icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            opt.label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Colors.black87),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
