/// Immutable data models mirroring the API's JSON responses.
library;

class User {
  const User({required this.id, required this.name, required this.email, this.phone, required this.role});

  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;

  bool get isAdmin => role == 'admin';
  String get firstName => name.split(' ').first;
  String get initials =>
      name.trim().split(RegExp(r'\s+')).take(2).map((w) => w.isEmpty ? '' : w[0].toUpperCase()).join();

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as int,
    name: json['name'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String?,
    role: json['role'] as String,
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email, 'phone': phone, 'role': role};
}

class AuthSession {
  const AuthSession({required this.token, required this.user});
  final String token;
  final User user;
}

class TourPackage {
  const TourPackage({
    required this.id,
    required this.slug,
    required this.title,
    required this.location,
    required this.country,
    required this.region,
    required this.category,
    required this.summary,
    required this.image,
    required this.durationDays,
    required this.pricePerPaxCents,
    required this.maxGroupSize,
    required this.isFeatured,
    required this.rating,
    required this.reviewCount,
  });

  final int id;
  final String slug;
  final String title;
  final String location;
  final String country;
  final String region;
  final String category;
  final String summary;
  final String image;
  final int durationDays;
  final int pricePerPaxCents;
  final int maxGroupSize;
  final bool isFeatured;
  final double? rating;
  final int reviewCount;

  String get imageAsset => 'assets/$image';
  String get durationLabel => '$durationDays days · ${durationDays - 1} nights';

  factory TourPackage.fromJson(Map<String, dynamic> json) => TourPackage(
    id: json['id'] as int,
    slug: json['slug'] as String,
    title: json['title'] as String,
    location: json['location'] as String,
    country: json['country'] as String,
    region: json['region'] as String,
    category: json['category'] as String,
    summary: json['summary'] as String,
    image: json['image'] as String,
    durationDays: json['durationDays'] as int,
    pricePerPaxCents: json['pricePerPaxCents'] as int,
    maxGroupSize: json['maxGroupSize'] as int,
    isFeatured: json['isFeatured'] as bool,
    rating: (json['rating'] as num?)?.toDouble(),
    reviewCount: json['reviewCount'] as int,
  );
}

class ItineraryDay {
  const ItineraryDay({required this.day, required this.title, required this.description});
  final int day;
  final String title;
  final String description;

  factory ItineraryDay.fromJson(Map<String, dynamic> json) =>
      ItineraryDay(day: json['day'] as int, title: json['title'] as String, description: json['description'] as String);
}

class PackageDetail {
  const PackageDetail({
    required this.summary,
    required this.description,
    required this.highlights,
    required this.inclusions,
    required this.itinerary,
  });

  final TourPackage summary;
  final String description;
  final List<String> highlights;
  final List<String> inclusions;
  final List<ItineraryDay> itinerary;

  factory PackageDetail.fromJson(Map<String, dynamic> json) => PackageDetail(
    summary: TourPackage.fromJson(json),
    description: json['description'] as String,
    highlights: List<String>.from(json['highlights'] as List),
    inclusions: List<String>.from(json['inclusions'] as List),
    itinerary: (json['itinerary'] as List).map((e) => ItineraryDay.fromJson(e as Map<String, dynamic>)).toList(),
  );
}

class Review {
  const Review({required this.id, required this.rating, this.comment, required this.author, required this.createdAt});
  final int id;
  final int rating;
  final String? comment;
  final String author;
  final DateTime createdAt;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    id: json['id'] as int,
    rating: json['rating'] as int,
    comment: json['comment'] as String?,
    author: json['author'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class TourTypeOption {
  const TourTypeOption({required this.key, required this.label, required this.description, required this.multiplier});
  final String key;
  final String label;
  final String description;
  final double multiplier;

  /// e.g. "+20%", "−10%" or "Included".
  String get adjustmentLabel {
    final pct = ((multiplier - 1) * 100).round();
    if (pct == 0) return 'Base price';
    return pct > 0 ? '+$pct%' : '−${pct.abs()}%';
  }

  factory TourTypeOption.fromJson(Map<String, dynamic> json) => TourTypeOption(
    key: json['key'] as String,
    label: json['label'] as String,
    description: json['description'] as String,
    multiplier: (json['multiplier'] as num).toDouble(),
  );
}

class CatalogOptions {
  const CatalogOptions({
    required this.regions,
    required this.categories,
    required this.tourTypes,
    required this.insurancePerPaxCents,
  });

  final List<String> regions;
  final List<String> categories;
  final List<TourTypeOption> tourTypes;
  final int insurancePerPaxCents;

  String tourTypeLabel(String key) => tourTypes.where((t) => t.key == key).map((t) => t.label).firstOrNull ?? key;

  factory CatalogOptions.fromJson(Map<String, dynamic> json) => CatalogOptions(
    regions: List<String>.from(json['regions'] as List),
    categories: List<String>.from(json['categories'] as List),
    tourTypes: (json['tourTypes'] as List).map((e) => TourTypeOption.fromJson(e as Map<String, dynamic>)).toList(),
    insurancePerPaxCents: json['insurancePerPaxCents'] as int,
  );
}

class PriceBreakdown {
  const PriceBreakdown({
    required this.unitPriceCents,
    required this.travellers,
    required this.baseCents,
    required this.tourTypeCents,
    required this.insuranceCents,
    required this.discountCents,
    required this.totalCents,
    this.promoCode,
  });

  final int unitPriceCents;
  final int travellers;
  final int baseCents;
  final int tourTypeCents;
  final int insuranceCents;
  final int discountCents;
  final int totalCents;
  final String? promoCode;

  factory PriceBreakdown.fromJson(Map<String, dynamic> json) => PriceBreakdown(
    unitPriceCents: json['unitPriceCents'] as int,
    travellers: json['travellers'] as int,
    baseCents: json['baseCents'] as int,
    tourTypeCents: json['tourTypeCents'] as int,
    insuranceCents: json['insuranceCents'] as int,
    discountCents: json['discountCents'] as int,
    totalCents: json['totalCents'] as int,
    promoCode: json['promoCode'] as String?,
  );
}

/// The traveller's selections, sent to `/quotes` and `/bookings`.
class BookingRequest {
  const BookingRequest({
    required this.packageSlug,
    required this.tourDate,
    required this.travellers,
    required this.tourType,
    required this.insurance,
    this.promoCode,
  });

  final String packageSlug;
  final String tourDate;
  final int travellers;
  final String tourType;
  final bool insurance;
  final String? promoCode;

  Map<String, dynamic> toJson() => {
    'packageSlug': packageSlug,
    'tourDate': tourDate,
    'travellers': travellers,
    'tourType': tourType,
    'insurance': insurance,
    if (promoCode != null && promoCode!.isNotEmpty) 'promoCode': promoCode,
  };
}

enum BookingStatus {
  confirmed('Confirmed'),
  completed('Completed'),
  cancelled('Cancelled');

  const BookingStatus(this.label);
  final String label;

  static BookingStatus parse(String value) =>
      BookingStatus.values.firstWhere((s) => s.name == value, orElse: () => BookingStatus.confirmed);
}

class BookingContact {
  const BookingContact({required this.name, required this.email, required this.phone});
  final String name;
  final String email;
  final String phone;

  Map<String, dynamic> toJson() => {'name': name, 'email': email, 'phone': phone};
}

class Booking {
  const Booking({
    required this.reference,
    required this.status,
    required this.tourDate,
    required this.travellers,
    required this.tourType,
    required this.insurance,
    required this.contact,
    this.specialRequests,
    required this.price,
    required this.packageSlug,
    required this.packageTitle,
    required this.packageLocation,
    required this.packageImage,
    required this.packageDurationDays,
    required this.hasReview,
    required this.createdAt,
  });

  final String reference;
  final BookingStatus status;
  final DateTime tourDate;
  final int travellers;
  final String tourType;
  final bool insurance;
  final BookingContact contact;
  final String? specialRequests;
  final PriceBreakdown price;
  final String packageSlug;
  final String packageTitle;
  final String packageLocation;
  final String packageImage;
  final int packageDurationDays;
  final bool hasReview;
  final DateTime createdAt;

  String get imageAsset => 'assets/$packageImage';
  DateTime get returnDate => tourDate.add(Duration(days: packageDurationDays - 1));
  bool get isUpcoming => status == BookingStatus.confirmed && !tourDate.isBefore(todayDate());

  /// Reviews open once the trip has started (departure day or later).
  bool get canReview => status != BookingStatus.cancelled && !hasReview && !tourDate.isAfter(todayDate());

  /// Last day the booking can be cancelled.
  DateTime get freeCancellationUntil => cancellationDeadline(tourDate);

  /// Mirrors the server's 3-month cancellation rule for UI hints; the server
  /// remains the source of truth.
  bool get canCancel =>
      status == BookingStatus.confirmed && tourDate.difference(todayDate()).inDays >= kCancellationCutoffDays;

  factory Booking.fromJson(Map<String, dynamic> json) {
    final pkg = json['package'] as Map<String, dynamic>;
    final contact = json['contact'] as Map<String, dynamic>;
    return Booking(
      reference: json['reference'] as String,
      status: BookingStatus.parse(json['status'] as String),
      tourDate: DateTime.parse(json['tourDate'] as String),
      travellers: json['travellers'] as int,
      tourType: json['tourType'] as String,
      insurance: json['insurance'] as bool,
      contact: BookingContact(
        name: contact['name'] as String,
        email: contact['email'] as String,
        phone: contact['phone'] as String,
      ),
      specialRequests: json['specialRequests'] as String?,
      price: PriceBreakdown.fromJson(json['price'] as Map<String, dynamic>),
      packageSlug: pkg['slug'] as String,
      packageTitle: pkg['title'] as String,
      packageLocation: pkg['location'] as String,
      packageImage: pkg['image'] as String,
      packageDurationDays: pkg['durationDays'] as int,
      hasReview: json['hasReview'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Today at local midnight.
DateTime todayDate() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// Bookings can be cancelled until 3 months (90 days) before departure.
/// Must match `CANCELLATION_CUTOFF_DAYS` on the server.
const kCancellationCutoffDays = 90;

/// Last day a trip departing on [tourDate] can still be cancelled.
DateTime cancellationDeadline(DateTime tourDate) =>
    DateTime(tourDate.year, tourDate.month, tourDate.day - kCancellationCutoffDays);
