# Daily Quran

A Flutter application for daily Quran reading and Islamic content.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Environment Setup

This project uses environment variables for sensitive configuration like API keys.

### Setting up .env file

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Edit the `.env` file and add your actual API keys:
   ```env
   STRIPE_PUBLISHABLE_KEY=your_publishable_key_here
   STRIPE_SECRET_KEY=your_secret_key_here
   STRIPE_MERCHANT_IDENTIFIER=merchant.com.hexahelix.dq
   ```

3. Get your Stripe keys from: https://dashboard.stripe.com/apikeys

**Important:** The `.env` file is gitignored and will not be committed to version control. Never commit your actual API keys to the repository.

### Running the app

After setting up the `.env` file, run:
```bash
flutter pub get
flutter run
```
