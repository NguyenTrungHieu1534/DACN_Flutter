# Wave Music – Login UI (Flutter)

Ocean-inspired sign-in screen using your palette and a live health check against your backend.

Backend health endpoint used: `https://backend-dacn-9l4w.onrender.com/health` ([link](https://backend-dacn-9l4w.onrender.com/health)).

## Run

1. Install Flutter (3.22+), set up an emulator or device.
2. From the project root, run:

```bash
flutter pub get
flutter run
```

## Customize

- Colors live in `lib/theme/app_theme.dart` (`AppColors`).
- Health check logic in `lib/services/api_service.dart` (`ApiService.checkHealth`).
- UI lives in `lib/screens/login_screen.dart`.

## Notes

- This project uses `http` for the health check and `google_fonts` for typography.




