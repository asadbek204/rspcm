# Mobile Context (Short)

## Role In System
`rspcm-mobile` is the Flutter client for the RSPCM education platform.
It consumes backend APIs and provides student-facing workflows.

## Main Areas
- Auth: login/register/OTP verification.
- Dashboard + notifications.
- Subjects and calendar.
- Exams and practice flows.
- Chat (groups, list, messages).
- Profile.

## Structure
- `lib/main.dart`: app entry.
- `lib/screens/`: UI screens.
- `lib/services/` + `lib/core/api/`: API calls and endpoints.
- `lib/models/`: request/response models.
- `lib/providers/`: state (auth/theme and related app state).

## Integration Notes
- Keep models aligned with backend DTOs.
- API endpoint changes in backend must be reflected in:
  1. `core/api/api_endpoints.dart`
  2. service calls
  3. related screen/provider logic.
