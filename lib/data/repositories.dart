import '../core/api_client.dart';
import 'models.dart';

class AuthRepository {
  AuthRepository(this._api);
  final ApiClient _api;

  Future<AuthSession> login({required String email, required String password}) async {
    final json = await _api.post('/auth/login', {'email': email, 'password': password});
    return _session(json);
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final json = await _api.post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
    return _session(json);
  }

  Future<User> me() async => User.fromJson((await _api.get('/auth/me'))['user'] as Map<String, dynamic>);

  Future<User> updateProfile({String? name, String? phone}) async {
    final json = await _api.patch('/auth/me', {'name': ?name, 'phone': ?phone});
    return User.fromJson(json['user'] as Map<String, dynamic>);
  }

  AuthSession _session(Map<String, dynamic> json) =>
      AuthSession(token: json['token'] as String, user: User.fromJson(json['user'] as Map<String, dynamic>));
}

class PackageQuery {
  const PackageQuery({this.search = '', this.region, this.category, this.sort = 'popular'});

  final String search;
  final String? region;
  final String? category;
  final String sort;

  PackageQuery copyWith({String? search, String? Function()? region, String? Function()? category, String? sort}) =>
      PackageQuery(
        search: search ?? this.search,
        region: region != null ? region() : this.region,
        category: category != null ? category() : this.category,
        sort: sort ?? this.sort,
      );

  bool get hasFilters => search.isNotEmpty || region != null || category != null;

  @override
  bool operator ==(Object other) =>
      other is PackageQuery &&
      other.search == search &&
      other.region == region &&
      other.category == category &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(search, region, category, sort);
}

class PackageRepository {
  PackageRepository(this._api);
  final ApiClient _api;

  Future<CatalogOptions> options() async => CatalogOptions.fromJson(await _api.get('/packages/options'));

  Future<List<TourPackage>> list([PackageQuery query = const PackageQuery()]) async {
    final json = await _api.get(
      '/packages',
      query: {'q': query.search, 'region': query.region, 'category': query.category, 'sort': query.sort},
    );
    return (json['data'] as List).map((e) => TourPackage.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PackageDetail> detail(String slug) async =>
      PackageDetail.fromJson((await _api.get('/packages/$slug'))['data'] as Map<String, dynamic>);

  Future<List<Review>> reviews(String slug) async {
    final json = await _api.get('/packages/$slug/reviews');
    return (json['data'] as List).map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
  }
}

class BookingRepository {
  BookingRepository(this._api);
  final ApiClient _api;

  Future<PriceBreakdown> quote(BookingRequest request) async =>
      PriceBreakdown.fromJson((await _api.post('/quotes', request.toJson()))['data'] as Map<String, dynamic>);

  Future<Booking> create(BookingRequest request, {required BookingContact contact, String? specialRequests}) async {
    final json = await _api.post('/bookings', {
      ...request.toJson(),
      'contact': contact.toJson(),
      if (specialRequests != null && specialRequests.isNotEmpty) 'specialRequests': specialRequests,
    });
    return Booking.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<List<Booking>> mine() async {
    final json = await _api.get('/bookings');
    return (json['data'] as List).map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Booking> byReference(String reference) async =>
      Booking.fromJson((await _api.get('/bookings/$reference'))['data'] as Map<String, dynamic>);

  Future<Booking> cancel(String reference) async =>
      Booking.fromJson((await _api.post('/bookings/$reference/cancel'))['data'] as Map<String, dynamic>);

  Future<Booking> review(String reference, {required int rating, String? comment}) async {
    final json = await _api.post('/bookings/$reference/review', {
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
    return Booking.fromJson(json['data'] as Map<String, dynamic>);
  }
}
