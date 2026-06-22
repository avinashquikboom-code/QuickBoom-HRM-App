enum AnnouncementCategory { general, holiday, policy, event }

class AnnouncementModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String postedBy;
  final AnnouncementCategory category;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.postedBy,
    required this.category,
  });

  String get categoryLabel {
    switch (category) {
      case AnnouncementCategory.general:
        return 'General';
      case AnnouncementCategory.holiday:
        return 'Holiday';
      case AnnouncementCategory.policy:
        return 'Policy';
      case AnnouncementCategory.event:
        return 'Event';
    }
  }
}
