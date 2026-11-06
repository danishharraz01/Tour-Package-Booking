import bcrypt from 'bcryptjs';
import type { DatabaseSync } from 'node:sqlite';

interface SeedPackage {
  slug: string;
  title: string;
  location: string;
  country: string;
  region: string;
  category: string;
  summary: string;
  description: string;
  image: string;
  priceRm: number;
  maxGroupSize: number;
  featured: boolean;
  highlights: string[];
  inclusions: string[];
  itinerary: { title: string; description: string }[];
}

const STANDARD_INCLUSIONS = [
  'Hotel accommodation (twin sharing)',
  'Daily breakfast',
  'Airport transfers',
  'Licensed local guide',
];

export const SEED_PACKAGES: SeedPackage[] = [
  {
    slug: 'langkawi-island-escape',
    title: 'Langkawi Island Escape',
    location: 'Langkawi, Kedah',
    country: 'Malaysia',
    region: 'Malaysia',
    category: 'Beach',
    summary: 'Duty-free shopping, cable cars and island hopping on the jewel of Kedah.',
    description:
      'A relaxed four-day getaway across the Langkawi archipelago. Ride the SkyCab to Mount Mat Cincang, ' +
      'kayak through the Kilim Geoforest mangroves and finish with a sunset dinner on Pantai Cenang.',
    image: 'kedah.jpg',
    priceRm: 150,
    maxGroupSize: 15,
    featured: true,
    highlights: ['SkyCab & Sky Bridge', 'Kilim Geoforest Park', 'Island hopping', 'Pantai Cenang sunset'],
    inclusions: STANDARD_INCLUSIONS,
    itinerary: [
      { title: 'Arrival & Kuah Town', description: 'Check in, explore Eagle Square and the duty-free shops of Kuah.' },
      { title: 'SkyCab & Oriental Village', description: 'Cable car to the Sky Bridge, followed by Telaga Tujuh waterfalls.' },
      { title: 'Island hopping', description: 'Pregnant Maiden Lake, eagle feeding and swimming at Beras Basah.' },
      { title: 'Mangrove cruise & departure', description: 'Morning Kilim mangrove tour before your transfer to the airport.' },
    ],
  },
  {
    slug: 'penang-heritage-trail',
    title: 'Penang Heritage & Food Trail',
    location: 'George Town, Penang',
    country: 'Malaysia',
    region: 'Malaysia',
    category: 'Culture',
    summary: 'UNESCO streets, street art and the best hawker food in Malaysia.',
    description:
      'Seven days in the Pearl of the Orient. Walk the UNESCO-listed heritage core of George Town, ' +
      'take the funicular up Penang Hill and eat your way through legendary hawker centres.',
    image: 'penang.jpg',
    priceRm: 300,
    maxGroupSize: 12,
    featured: false,
    highlights: ['George Town street art', 'Penang Hill funicular', 'Kek Lok Si Temple', 'Hawker food tour'],
    inclusions: [...STANDARD_INCLUSIONS, 'Guided hawker food tasting'],
    itinerary: [
      { title: 'Arrival in George Town', description: 'Evening trishaw ride along Armenian Street and the clan jetties.' },
      { title: 'Heritage walk', description: 'Cheong Fatt Tze Mansion, Khoo Kongsi and the famous street murals.' },
      { title: 'Penang Hill', description: 'Funicular to the summit, The Habitat canopy walk and Kek Lok Si Temple.' },
      { title: 'Balik Pulau', description: 'Durian and nutmeg farms in the rural west of the island.' },
      { title: 'Chowrasta Market', description: 'Morning market visit and a hands-on Nyonya cooking class.' },
      { title: 'Batu Ferringhi', description: 'Beach day with an optional night market visit.' },
      { title: 'Departure', description: 'Last breakfast of nasi kandar before your transfer.' },
    ],
  },
  {
    slug: 'sabah-borneo-adventure',
    title: 'Sabah Borneo Adventure',
    location: 'Kota Kinabalu, Sabah',
    country: 'Malaysia',
    region: 'Malaysia',
    category: 'Nature',
    summary: 'Islands, rainforest and Mount Kinabalu views in the Land Below the Wind.',
    description:
      'Explore the wild side of Borneo: snorkel the Tunku Abdul Rahman Marine Park, walk the ' +
      'canopy at Kinabalu Park and feast on fresh seafood by the waterfront.',
    image: 'sabah.jpg',
    priceRm: 400,
    maxGroupSize: 12,
    featured: true,
    highlights: ['Tunku Abdul Rahman Marine Park', 'Kinabalu Park', 'Kundasang highlands', 'Seafood night market'],
    inclusions: [...STANDARD_INCLUSIONS, 'Marine park fees'],
    itinerary: [
      { title: 'Arrival in Kota Kinabalu', description: 'Sunset at Tanjung Aru beach and the waterfront night market.' },
      { title: 'City & heritage', description: 'Sabah Museum, the floating mosque and Signal Hill Observatory.' },
      { title: 'Marine park', description: 'Snorkelling and lunch on Manukan and Sapi islands.' },
      { title: 'Kinabalu Park', description: 'Botanical garden walk and the Poring canopy walkway.' },
      { title: 'Kundasang', description: 'Desa Dairy Farm with views of Mount Kinabalu.' },
      { title: 'Seafood feast', description: 'Free morning, then a fresh seafood dinner by the sea.' },
      { title: 'Departure', description: 'Souvenir shopping at the Filipino market before your flight.' },
    ],
  },
  {
    slug: 'hokkaido-discovery',
    title: 'Hokkaido Discovery',
    location: 'Hokkaido',
    country: 'Japan',
    region: 'East Asia',
    category: 'Nature',
    summary: 'Hot springs, lakes and harbour towns across Japan’s northern island.',
    description:
      'A seven-day loop of Hokkaido from Chitose. Soak in the onsen of Noboribetsu, watch the night view ' +
      'from Mount Hakodate and stroll the canals of Otaru before ending in Sapporo.',
    image: 'japan.jpg',
    priceRm: 1670,
    maxGroupSize: 20,
    featured: true,
    highlights: ['Noboribetsu Hell Valley', 'Mount Hakodate night view', 'Lake Toya', 'Otaru canal'],
    inclusions: [...STANDARD_INCLUSIONS, 'Return flights from Kuala Lumpur', 'Onsen ryokan night'],
    itinerary: [
      { title: 'Kuala Lumpur – Chitose', description: 'Overnight flight to New Chitose Airport.' },
      { title: 'Chitose – Noboribetsu', description: 'Jigokudani Hell Valley and an evening at a traditional onsen.' },
      { title: 'Noboribetsu – Hakodate', description: 'Morning market, red-brick warehouses and the Mount Hakodate ropeway.' },
      { title: 'Hakodate – Lake Toya', description: 'Onuma Quasi-National Park and lakeside fireworks (seasonal).' },
      { title: 'Lake Toya – Otaru – Sapporo', description: 'Otaru canal, music box museum and glass workshops.' },
      { title: 'Sapporo', description: 'Odori Park, Shiroi Koibito Park and a Sapporo ramen dinner.' },
      { title: 'Chitose – Kuala Lumpur', description: 'Last-minute shopping at the airport before your flight home.' },
    ],
  },
  {
    slug: 'korea-grand-tour',
    title: 'Korea Grand Tour',
    location: 'Seoul & beyond',
    country: 'South Korea',
    region: 'East Asia',
    category: 'Culture',
    summary: 'Palaces, hanok villages and coastal cities from Seoul to Gyeongju.',
    description:
      'Travel the length of the peninsula: the hanok village of Jeonju, the harbour of Mokpo and the ' +
      'thousand-year-old capital of Gyeongju, finishing among the palaces and markets of Seoul.',
    image: 'korea.jpg',
    priceRm: 1500,
    maxGroupSize: 20,
    featured: false,
    highlights: ['Jeonju Hanok Village', 'Bulguksa Temple', 'Gyeongbokgung Palace', 'Myeongdong street food'],
    inclusions: [...STANDARD_INCLUSIONS, 'Return flights from Kuala Lumpur', 'Hanbok rental'],
    itinerary: [
      { title: 'Kuala Lumpur – Incheon', description: 'Overnight flight to Seoul Incheon.' },
      { title: 'Incheon – Gunsan', description: 'Arrive and explore the time-capsule streets of Gunsan.' },
      { title: 'Gunsan – Jeonju', description: 'Hanok village walk and the original bibimbap.' },
      { title: 'Jeonju – Mokpo', description: 'Mokpo Marine Cable Car and the coastal promenade.' },
      { title: 'Mokpo – Gyeongju', description: 'Bulguksa Temple, Seokguram Grotto and royal tombs.' },
      { title: 'Gyeongju – Seoul', description: 'KTX to Seoul, Gyeongbokgung Palace in hanbok and Myeongdong.' },
      { title: 'Seoul – Kuala Lumpur', description: 'Free morning before your transfer to Incheon.' },
    ],
  },
  {
    slug: 'maldives-island-retreat',
    title: 'Maldives Island Retreat',
    location: 'North Malé Atoll',
    country: 'Maldives',
    region: 'South Asia',
    category: 'Beach',
    summary: 'Overwater villas, bioluminescent beaches and a scenic seaplane flight.',
    description:
      'Seven days of turquoise lagoons. Snorkel house reefs, take a helicopter ride over the atolls and ' +
      'walk the glowing shores of Vaadhoo at night.',
    image: 'maldives.jpg',
    priceRm: 1800,
    maxGroupSize: 10,
    featured: true,
    highlights: ['Overwater villa', 'Helicopter scenic flight', 'Vaadhoo glowing beach', 'Reef snorkelling'],
    inclusions: ['Resort accommodation', 'All meals', 'Speedboat transfers', 'Snorkelling equipment'],
    itinerary: [
      { title: 'Arrival in Malé', description: 'Speedboat transfer to your island resort.' },
      { title: 'Malé city tour', description: 'Old Friday Mosque, the fish market and Sultan Park.' },
      { title: 'Local island', description: 'Lunch with a Maldivian family on a local island.' },
      { title: 'Island hopping', description: 'Sandbank picnic and dolphin watching cruise.' },
      { title: 'Helicopter ride', description: 'A 30-minute scenic flight over the atolls.' },
      { title: 'Glowing beach', description: 'Evening trip to see the bioluminescent plankton.' },
      { title: 'Departure', description: 'A final walk on the beach before your flight.' },
    ],
  },
  {
    slug: 'swiss-alps-explorer',
    title: 'Swiss Alps Explorer',
    location: 'Lucerne & Interlaken',
    country: 'Switzerland',
    region: 'Europe',
    category: 'Nature',
    summary: 'Lakes, glaciers and mountain railways in the heart of Europe.',
    description:
      'From the medieval old town of Lucerne to the slopes of the Jungfrau region — ride cogwheel trains, ' +
      'cruise alpine lakes and try your hand at skiing.',
    image: 'switzerland.jpg',
    priceRm: 2300,
    maxGroupSize: 16,
    featured: false,
    highlights: ['Chapel Bridge, Lucerne', 'Mount Titlis', 'Jungfraujoch', 'Lake Brienz cruise'],
    inclusions: [...STANDARD_INCLUSIONS, 'Swiss Travel Pass (6 days)'],
    itinerary: [
      { title: 'Arrival in Zurich', description: 'Transfer to Lucerne and an evening walk along the Reuss.' },
      { title: 'Lucerne old town', description: 'Chapel Bridge, Lion Monument and a lake cruise.' },
      { title: 'Swiss cuisine', description: 'Cheese fondue and chocolate workshop.' },
      { title: 'Leisure day', description: 'Free day — optional Mount Pilatus excursion.' },
      { title: 'Interlaken', description: 'Scenic train to Interlaken and a Lake Brienz cruise.' },
      { title: 'Skiing on the Jungfrau', description: 'Ski lesson or snow play at the Top of Europe.' },
      { title: 'Departure', description: 'Shopping in Zurich before your flight home.' },
    ],
  },
  {
    slug: 'da-nang-ba-na-hills',
    title: 'Da Nang & Ba Na Hills',
    location: 'Da Nang',
    country: 'Vietnam',
    region: 'Southeast Asia',
    category: 'City',
    summary: 'The Golden Bridge, Hoi An lanterns and the beaches of central Vietnam.',
    description:
      'Seven days in central Vietnam: walk the Golden Bridge above the clouds at Ba Na Hills, explore the ' +
      'lantern-lit old town of Hoi An and relax on My Khe beach.',
    image: 'vietname.jpg',
    priceRm: 870,
    maxGroupSize: 18,
    featured: false,
    highlights: ['Golden Bridge', 'Hoi An Ancient Town', 'Marble Mountains', 'My Khe beach'],
    inclusions: [...STANDARD_INCLUSIONS, 'Ba Na Hills cable car ticket'],
    itinerary: [
      { title: 'Arrival in Da Nang', description: 'See the Dragon Bridge breathe fire (weekends).' },
      { title: 'Marble Mountains', description: 'Caves, pagodas and stone-carving villages.' },
      { title: 'Vietnamese cuisine', description: 'Street food tour: mi quang, banh xeo and more.' },
      { title: 'Ba Na Hills', description: 'Cable car to the French Village and the Golden Bridge.' },
      { title: 'Hoi An', description: 'Lantern-making class and a boat ride on the Thu Bon river.' },
      { title: 'Han Market', description: 'Morning shopping and a beach afternoon at My Khe.' },
      { title: 'Departure', description: 'Transfer to Da Nang International Airport.' },
    ],
  },
  {
    slug: 'merbabu-x-jogja',
    title: 'Merbabu x Jogja Hiking Trip',
    location: 'Mount Merbabu & Yogyakarta',
    country: 'Indonesia',
    region: 'Southeast Asia',
    category: 'Adventure',
    summary: 'Summit Mount Merbabu via Suwanting, then explore the beaches, caves and streets of Yogyakarta.',
    description:
      'A private 5-day, 4-night hiking trip in Central Java. Climb Mount Merbabu via the Suwanting trail ' +
      'with licensed local guides and porters, camp at Pos 3, catch the summit sunrise over the savanna, ' +
      'then unwind in Yogyakarta: the Pantai Timang cliffs, river tubing at Goa Pindul and a night on ' +
      'Malioboro street. Your group is never merged with other travellers. ' +
      'Not included: flights, personal porter, snacks and the Pantai Timang gondola ticket. ' +
      'The itinerary may change with weather and trail conditions.',
    image: 'merbabu.jpg',
    priceRm: 800,
    maxGroupSize: 12,
    featured: true,
    highlights: [
      'Summit sunrise on Mount Merbabu',
      'Suwanting savanna',
      'Pantai Timang, Gunung Kidul',
      'Goa Pindul river tubing',
      'Malioboro street',
    ],
    inclusions: [
      'Return transport from meeting point to basecamp',
      'Mount Merbabu online hiking permit',
      'Licensed mountain guide & porters',
      'All meals before, during and after the hike',
      'Camping gear: tent, sleeping bag, toilet tent, portable table & chairs',
      'Return ojek rides',
      '2 nights hotel near Merbabu + 1 night hotel at Malioboro',
      'Basecamp homestay',
      'Goa Pindul entrance ticket',
      'Travel insurance',
    ],
    itinerary: [
      {
        title: 'Arrival in Yogyakarta',
        description: 'Meet at Yogyakarta International Airport and transfer to your hotel in Suwanting.',
      },
      {
        title: 'Hike to Pos 3 camp',
        description:
          'Breakfast at basecamp, gear check and start the climb at 10:00. Lunch at Pos 2, trek on to the ' +
          'Pos 3 campsite, then coffee, fried bananas and dinner under the stars.',
      },
      {
        title: 'Summit Merbabu',
        description:
          'Wake at 03:00 for the summit push and sunrise at the peak, explore the Suwanting savanna, then ' +
          'descend to camp, pack up and hike down to basecamp for a hot meal.',
      },
      {
        title: 'Pantai Timang, Goa Pindul & Malioboro',
        description:
          'Visit Curug Kedung Kayang, coffee with a view at Pantai Timang, river tubing through Goa Pindul and ' +
          'Goa Tanding, then shop for bakpia and souvenirs on Malioboro. Overnight at a Malioboro hotel.',
      },
      {
        title: 'Departure',
        description: 'Early transfer to Yogyakarta International Airport for your flight home.',
      },
    ],
  },
];

export const SEED_PROMO_CODES = [
  { code: 'WELCOME5', description: '5% off your first adventure', percentOff: 5, minTravellers: 1, minDaysAhead: 0 },
  { code: 'GROUP10', description: '10% off for groups of 4 or more', percentOff: 10, minTravellers: 4, minDaysAhead: 0 },
  { code: 'EARLYBIRD20', description: '20% off when you book 60+ days ahead', percentOff: 20, minTravellers: 1, minDaysAhead: 60 },
];

export const DEMO_USERS = [
  { name: 'Demo Traveller', email: 'demo@ssbtour.com', password: 'Password123!', role: 'customer' },
  { name: 'SSB Admin', email: 'admin@ssbtour.com', password: 'Admin123!', role: 'admin' },
] as const;

const SEED_REVIEWS: [slug: string, author: string, rating: number, comment: string][] = [
  ['langkawi-island-escape', 'Aina R.', 5, 'Island hopping was the highlight — our guide was fantastic with the kids.'],
  ['langkawi-island-escape', 'Hafiz M.', 4, 'Great value for money. The SkyCab queue was long but worth it.'],
  ['penang-heritage-trail', 'Mei Ling T.', 5, 'The hawker food tour alone is worth the trip. So well organised!'],
  ['sabah-borneo-adventure', 'Daniel K.', 5, 'Snorkelling at Sapi island was unreal. Would book again.'],
  ['sabah-borneo-adventure', 'Siti N.', 4, 'Kundasang was cold but beautiful. Hotels were comfortable.'],
  ['hokkaido-discovery', 'Arif Z.', 5, 'The onsen night in Noboribetsu was magical. Perfectly paced itinerary.'],
  ['hokkaido-discovery', 'Rachel L.', 5, 'Otaru canal at dusk — unforgettable. Thank you SSB Tour!'],
  ['korea-grand-tour', 'Farah A.', 4, 'Loved Jeonju and Gyeongju. Wish we had one more day in Seoul.'],
  ['maldives-island-retreat', 'Kevin O.', 5, 'The glowing beach is real and the helicopter ride was incredible.'],
  ['swiss-alps-explorer', 'Nurul H.', 5, 'Jungfraujoch took our breath away. Smooth train connections.'],
  ['da-nang-ba-na-hills', 'Jason W.', 4, 'Golden Bridge was crowded but Hoi An at night made up for it.'],
  ['merbabu-x-jogja', 'Izzat F.', 5, 'Summit sunrise above the clouds was worth every step. Guides and porters were top notch.'],
];

function seedReviews(db: DatabaseSync) {
  const pkgId = db.prepare('SELECT id, price_per_pax_cents FROM packages WHERE slug = ?');
  const insertUser = db.prepare(`INSERT INTO users (name, email, password_hash) VALUES (?, ?, '!seed-account')`);
  const insertBooking = db.prepare(`
    INSERT INTO bookings (reference, user_id, package_id, tour_date, travellers, tour_type, contact_name,
      contact_email, contact_phone, unit_price_cents, base_cents, tour_type_cents, insurance_cents,
      discount_cents, total_cents, status)
    VALUES (?, ?, ?, ?, 2, 'independent', ?, ?, '+60123456789', ?, ?, 0, 0, 0, ?, 'completed')`);
  const insertReview = db.prepare(
    'INSERT INTO reviews (package_id, user_id, booking_id, rating, comment) VALUES (?, ?, ?, ?, ?)',
  );

  SEED_REVIEWS.forEach(([slug, author, rating, comment], i) => {
    const pkg = pkgId.get(slug) as { id: number; price_per_pax_cents: number };
    const email = `reviewer${i + 1}@example.com`;
    const userId = Number(insertUser.run(author, email).lastInsertRowid);
    const base = pkg.price_per_pax_cents * 2;
    const bookingId = Number(
      insertBooking.run(`SSB-SEED${String(i + 1).padStart(2, '0')}`, userId, pkg.id, '2025-06-01', author, email,
        pkg.price_per_pax_cents, base, base).lastInsertRowid,
    );
    insertReview.run(pkg.id, userId, bookingId, rating, comment);
  });
}

/**
 * Seeds an empty database with the catalogue, promo codes, demo accounts and
 * reviews. On an existing database it only adds catalogue packages that are
 * missing (matched by slug), so new trips appear without wiping user data.
 */
export function seed(db: DatabaseSync) {
  const { count } = db.prepare('SELECT COUNT(*) AS count FROM packages').get() as { count: number };

  const insertPackage = db.prepare(`
    INSERT INTO packages (slug, title, location, country, region, category, summary, description, image,
      duration_days, price_per_pax_cents, max_group_size, highlights, inclusions, itinerary, is_featured)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT (slug) DO NOTHING`);
  const addPackages = () => {
    for (const p of SEED_PACKAGES) {
      insertPackage.run(
        p.slug, p.title, p.location, p.country, p.region, p.category, p.summary, p.description, p.image,
        p.itinerary.length, p.priceRm * 100, p.maxGroupSize,
        JSON.stringify(p.highlights), JSON.stringify(p.inclusions), JSON.stringify(p.itinerary),
        p.featured ? 1 : 0,
      );
    }
  };

  if (count > 0) {
    addPackages();
    return;
  }
  const insertPromo = db.prepare(`
    INSERT INTO promo_codes (code, description, percent_off, min_travellers, min_days_ahead)
    VALUES (?, ?, ?, ?, ?)`);
  const insertUser = db.prepare(
    'INSERT INTO users (name, email, password_hash, role) VALUES (?, ?, ?, ?)',
  );

  db.exec('BEGIN');
  try {
    addPackages();
    for (const c of SEED_PROMO_CODES) {
      insertPromo.run(c.code, c.description, c.percentOff, c.minTravellers, c.minDaysAhead);
    }
    for (const u of DEMO_USERS) {
      insertUser.run(u.name, u.email, bcrypt.hashSync(u.password, 10), u.role);
    }
    seedReviews(db);
    db.exec('COMMIT');
  } catch (err) {
    db.exec('ROLLBACK');
    throw err;
  }
}
