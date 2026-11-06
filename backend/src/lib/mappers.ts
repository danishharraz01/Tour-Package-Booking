/** Converts raw SQLite rows into the camelCase JSON shapes the API returns. */

type Row = Record<string, unknown>;

export function toUser(row: Row) {
  return {
    id: row.id as number,
    name: row.name as string,
    email: row.email as string,
    phone: (row.phone as string | null) ?? null,
    role: row.role as 'customer' | 'admin',
    createdAt: row.created_at as string,
  };
}

export function toPackageSummary(row: Row) {
  return {
    id: row.id as number,
    slug: row.slug as string,
    title: row.title as string,
    location: row.location as string,
    country: row.country as string,
    region: row.region as string,
    category: row.category as string,
    summary: row.summary as string,
    image: row.image as string,
    durationDays: row.duration_days as number,
    pricePerPaxCents: row.price_per_pax_cents as number,
    maxGroupSize: row.max_group_size as number,
    isFeatured: row.is_featured === 1,
    rating: row.rating == null ? null : Math.round((row.rating as number) * 10) / 10,
    reviewCount: (row.review_count as number) ?? 0,
  };
}

export function toPackageDetail(row: Row) {
  return {
    ...toPackageSummary(row),
    description: row.description as string,
    highlights: JSON.parse(row.highlights as string) as string[],
    inclusions: JSON.parse(row.inclusions as string) as string[],
    itinerary: (JSON.parse(row.itinerary as string) as { title: string; description: string }[]).map(
      (day, i) => ({ day: i + 1, ...day }),
    ),
  };
}

export function toBooking(row: Row) {
  return {
    id: row.id as number,
    reference: row.reference as string,
    status: row.status as 'confirmed' | 'completed' | 'cancelled',
    tourDate: row.tour_date as string,
    travellers: row.travellers as number,
    tourType: row.tour_type as string,
    insurance: row.insurance === 1,
    contact: {
      name: row.contact_name as string,
      email: row.contact_email as string,
      phone: row.contact_phone as string,
    },
    specialRequests: (row.special_requests as string | null) ?? null,
    price: {
      currency: 'MYR' as const,
      unitPriceCents: row.unit_price_cents as number,
      travellers: row.travellers as number,
      baseCents: row.base_cents as number,
      tourTypeCents: row.tour_type_cents as number,
      insuranceCents: row.insurance_cents as number,
      discountCents: row.discount_cents as number,
      totalCents: row.total_cents as number,
      promoCode: (row.promo_code as string | null) ?? null,
    },
    package: {
      slug: row.package_slug as string,
      title: row.package_title as string,
      location: row.package_location as string,
      image: row.package_image as string,
      durationDays: row.package_duration_days as number,
    },
    hasReview: Boolean(row.review_id),
    createdAt: row.created_at as string,
    cancelledAt: (row.cancelled_at as string | null) ?? null,
  };
}

export function toReview(row: Row) {
  return {
    id: row.id as number,
    rating: row.rating as number,
    comment: (row.comment as string | null) ?? null,
    author: row.author_name as string,
    createdAt: row.created_at as string,
  };
}
