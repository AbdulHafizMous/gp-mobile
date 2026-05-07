
// ── Interest model ────────────────────────────────────────────────────────────
class ProfileInterest {
  final int id;
  final String name;
  bool isSelected;
  ProfileInterest({
    required this.id,
    required this.name,
    this.isSelected = false,
  });
}
