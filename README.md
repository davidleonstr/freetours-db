# Free Tours Booking — Database Schema

PostgreSQL schema for a **free walking-tours booking system**. No pricing or payment processing — registration and booking are instant (no email-confirmation flow).

- **Engine:** PostgreSQL 18.4
- **Primary keys:** UUID (`gen_random_uuid()`, via the `pgcrypto` extension)

## Loading the schema

```bash
psql -d your_db -f schema.sql
```

`schema.sql` is an entry point that pulls in the enum type, trigger function, tables, triggers, and indexes via `\i` includes, in dependency order. To wipe a database first, run `clear.sql`.

## Entity overview

| Table | Purpose |
|---|---|
| `tours` | The tour catalog. Free (no price fields). Has a required meeting point stored as a label plus lat/lng coordinates (and an optional OSM node/way/relation id) for the map shown in booking emails. |
| `images` | Reusable image records (URL, alt text, display position). |
| `gallery` | Join table linking a `tour` to multiple `images` (beyond its single cover image), with a `position` for ordering. |
| `tour_schedules` | The departure **times** a tour can run at (e.g. `05:30`). |
| `tour_dates` | The calendar **dates** a tour is actually open for. Can be soft-closed via `is_active` instead of deleted. |
| `customers` | Registered users. Created instantly — no verification/confirmation flag. |
| `bookings` | A reservation: one customer, one tour, pinned to a specific `tour_date` + `tour_schedule`, with a party breakdown (adults, children, babies, pets) and a status. |
| `reviews` | One review per customer per tour (1–5 stars, optional text). |

## Key relationships

- A `tour` has many `tour_schedules` (times) and many `tour_dates` (dates) — both independent, and a `booking` picks one of each rather than accepting free-form date/time values.
- A `booking` therefore always references a `tour_date` and a `tour_schedule` that both belong to the same `tour` (enforced at the application level, not by a DB constraint).
- A `tour` has one cover `image` (`tours.image`) and many gallery `images` via `gallery`.
- A `customer` can leave at most one `review` per `tour` (`UNIQUE (customer_id, tour_id)`).

## Booking party composition

Each `booking` tracks:
- `quantity` — number of adults (must be > 0)
- `number_of_children` — counted against tour capacity
- `number_of_babies` — not counted against capacity
- `number_of_pets` — not counted against capacity

## Booking status

`booking_status` enum: `pending` → `confirmed` → `completed`, or `cancelled`.

## Auditing

`tours`, `customers`, and `bookings` all have `created_at`/`updated_at`, with triggers (`updated_at()` function) that automatically refresh `updated_at` on every row update.

## Indexes

- `idx_bookings_customer`, `idx_bookings_tour`, `idx_bookings_tour_schedule` — booking lookups by customer/tour/schedule.
- `idx_bookings_tour_date_schedule` — partial index on `(tour_id, tour_date_id, tour_schedule_id)` for non-cancelled bookings, e.g. to check remaining capacity for a given departure.
- `idx_tour_schedules_tour_id_time` — schedules per tour.
- `idx_gallery_tour` — gallery images per tour.
- `idx_reviews_tour_id` — reviews per tour.

## File layout

```
schema.sql              -- entry point, includes everything below in order
clear.sql                -- drops and recreates the public schema
types/
  booking_status.sql
functions/
  updated_at.sql
tables/
  images.sql
  tours.sql
  tour_schedules.sql
  tour_dates.sql
  gallery.sql
  customers.sql
  bookings.sql
  reviews.sql
triggers/
  trg_tours_updated_at.sql
  trg_customers_updated_at.sql
  trg_bookings_updated_at.sql
indexes/
  idx_gallery_tour.sql
  idx_bookings_customer.sql
  idx_bookings_tour.sql
  idx_bookings_tour_schedule.sql
  idx_tour_schedules_tour_id_time.sql
  idx_reviews_tour_id.sql
  idx_bookings_tour_date_schedule.sql
```

## Example usage

Register a customer:

```sql
INSERT INTO customers (full_name, email, phone)
VALUES ('Jane Doe', 'jane@example.com', '+503 7000 0000')
RETURNING id;
```

Open a calendar date and a departure time for a tour:

```sql
INSERT INTO tour_dates (tour_id, date)
VALUES ('<tour_id>', '2026-09-01')
RETURNING id;

INSERT INTO tour_schedules (time, tour_id)
VALUES ('05:30', '<tour_id>')
RETURNING id;
```

Book the tour:

```sql
INSERT INTO bookings (
  customer_id, tour_id, tour_date_id, tour_schedule_id,
  quantity, number_of_children, number_of_babies, number_of_pets
)
VALUES ('<customer_id>', '<tour_id>', '<tour_date_id>', '<tour_schedule_id>', 2, 1, 0, 0)
RETURNING id;
```

Fetch a customer's booking history:

```sql
SELECT b.id, t.name AS tour_name, t.meeting_point, td.date AS tour_date,
       ts.time AS departure_time, b.quantity, b.number_of_children,
       b.number_of_babies, b.number_of_pets, b.status AS booking_status
FROM bookings b
JOIN tours t ON t.id = b.tour_id
JOIN tour_dates td ON td.id = b.tour_date_id
JOIN tour_schedules ts ON ts.id = b.tour_schedule_id
WHERE b.customer_id = '<customer_id>'
ORDER BY b.created_at DESC;
```

Fetch a tour with its gallery:

```sql
SELECT t.*,
       json_agg(DISTINCT jsonb_build_object('id', i.id, 'url', i.url, 'alt', i.alt, 'position', g.position))
         FILTER (WHERE i.id IS NOT NULL) AS gallery
FROM tours t
LEFT JOIN gallery g ON g.tour_id = t.id
LEFT JOIN images i ON i.id = g.image_id
WHERE t.id = '<tour_id>'
GROUP BY t.id;
```