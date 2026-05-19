begin;

insert into public.sports (name, slug, description, icon_name, is_active)
values
  ('Badminton', 'badminton', 'Fast indoor rally sport.', 'sports_tennis', true),
  ('Cricket', 'cricket', 'Organized nets, box cricket, and tournament play.', 'sports_cricket', true),
  ('Football', 'football', '5-a-side and full pitch bookings.', 'sports_soccer', true),
  ('Basketball', 'basketball', 'Half-court and full-court sessions.', 'sports_basketball', true),
  ('Table Tennis', 'table-tennis', 'Quick doubles and ladder matches.', 'table_tennis', true),
  ('Volleyball', 'volleyball', 'Casual and competitive indoor play.', 'sports_volleyball', true)
on conflict (slug) do update
set name = excluded.name,
    description = excluded.description,
    icon_name = excluded.icon_name,
    is_active = excluded.is_active;

insert into public.venues (name, slug, description, address, city, latitude, longitude, opening_hours, amenities, supported_sports, contact_phone, is_active)
values
  (
    'PlayGrid Arena',
    'playgrid-arena',
    'Premium indoor courts with evening lighting and locker rooms.',
    '12 Tech Park Road',
    'Bengaluru',
    12.9716000,
    77.5946000,
    '{"mon-fri":{"open":"06:00","close":"22:30"},"sat-sun":{"open":"07:00","close":"22:00"}}',
    '["parking","washrooms","changing_room","water_station"]',
    '["badminton","table-tennis","basketball"]',
    '+91-90000-11111',
    true
  ),
  (
    'North Campus Sports Hub',
    'north-campus-sports-hub',
    'Organized turf and court bookings for teams and employee clubs.',
    '88 Enterprise Avenue',
    'Bengaluru',
    12.9352000,
    77.6245000,
    '{"mon-fri":{"open":"05:30","close":"21:30"},"sat-sun":{"open":"06:00","close":"21:30"}}',
    '["parking","cafe","showers","spectator_seating"]',
    '["football","cricket","volleyball"]',
    '+91-90000-22222',
    true
  ),
  (
    'Skyline Court Club',
    'skyline-court-club',
    'Compact venue for after-work games and structured leagues.',
    '41 Startup Street',
    'Bengaluru',
    12.9098000,
    77.6387000,
    '{"mon-fri":{"open":"07:00","close":"23:00"},"sat-sun":{"open":"08:00","close":"23:00"}}',
    '["parking","lights","changing_room"]',
    '["badminton","football","basketball"]',
    '+91-90000-33333',
    true
  )
on conflict (slug) do update
set name = excluded.name,
    description = excluded.description,
    address = excluded.address,
    city = excluded.city,
    latitude = excluded.latitude,
    longitude = excluded.longitude,
    opening_hours = excluded.opening_hours,
    amenities = excluded.amenities,
    supported_sports = excluded.supported_sports,
    contact_phone = excluded.contact_phone,
    is_active = excluded.is_active;

commit;
