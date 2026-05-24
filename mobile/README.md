# THESIS Mobile

This folder contains the Flutter app. Use `API_BASE_URL` to point the app at the correct backend.

## Local Testing

Android emulator:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

Physical phone on the same Wi-Fi network:

```bash
flutter run --dart-define=API_BASE_URL=http://<your-pc-lan-ip>:8000/api
```

If you want to build an APK for testing:

```bash
flutter build apk --dart-define=API_BASE_URL=http://<your-pc-lan-ip>:8000/api
```

## Production Build

Use the deployed Laravel Cloud URL:

```bash
flutter build apk --dart-define=API_BASE_URL=https://your-cloud-domain/api
```

For iOS, use the same pattern with the production API URL:

```bash
flutter build ios --dart-define=API_BASE_URL=https://your-cloud-domain/api
```

## Notes

- `API_BASE_URL` overrides the stored/discovered local URL.
- Keep the backend health endpoint available at `/api/health`.
- For phone testing, `localhost` will not work because the device cannot reach your PC through that name.
