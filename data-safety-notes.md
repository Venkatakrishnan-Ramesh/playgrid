# Data Safety Notes

## Collected data

- Name
- Email address
- Department
- Sports preferences
- Booking history
- Game participation
- Notifications

## Data handling

- Used for app functionality only
- Stored in Supabase when connected
- Mock data is used locally when Supabase is not configured

## Sharing

- No advertising SDKs are included in this MVP
- No analytics SDKs are included in this MVP

## Security notes

- Replace placeholder FCM credentials before production
- Use Supabase RLS to enforce row-level access
- Keep the service role key out of the client app
