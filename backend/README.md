# THESIS Backend

This folder contains the Laravel API for the thesis project. Deploy this folder as the backend app root. The Flutter mobile app lives in the sibling `mobile/` folder and should be deployed separately.

## Local Development

1. Install PHP dependencies with `composer install`.
2. Copy `.env.example` to `.env` and set your local database values.
3. Run `php artisan key:generate` if the app key is empty.
4. Run `php artisan migrate`.
5. Start the server with `php artisan serve --host=0.0.0.0 --port=8000`.

## Laravel Cloud Deployment

Use `.env.production.example` as the baseline for production settings.

Important values to set in Laravel Cloud:

- `APP_ENV=production`
- `APP_DEBUG=false`
- `APP_URL=https://your-cloud-domain`
- `DB_CONNECTION=mysql` and the cloud database credentials
- `SESSION_DRIVER=database`
- `CACHE_STORE=database`
- `QUEUE_CONNECTION=database`
- `FILESYSTEM_DISK=public` unless you move uploads to object storage

Deploy only the `backend/` application code. Do not include the Flutter app as part of the Laravel Cloud app root.

After deployment, run the migrations in the cloud environment and verify:

- `GET /api/health`
- `POST /api/login`
- `POST /api/register`
- file upload routes that use the public disk

If media needs to persist across redeploys, use durable storage such as object storage instead of relying on ephemeral local files.

## Testing Local vs Online

- Android emulator local API base URL: `http://10.0.2.2:8000/api`
- Physical phone on the same Wi-Fi network: `http://<your-PC-LAN-IP>:8000/api`
- Deployed production API base URL: `https://your-cloud-domain/api`

The Flutter app already supports switching API URLs through `mobile/lib/services/api_service.dart`. Keep local testing pointed at LAN or emulator endpoints and production builds pointed at the deployed URL.
