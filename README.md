# Expense Tracker App

A Flutter web application for tracking daily expenses with real-time currency conversion.

## Features

- Add and manage expenses
- Real-time currency conversion (USD to INR)
- Period-wise expense tracking (Week, Month, Year)
- Download expense reports in CSV format
- Beautiful charts and visualizations
- Responsive design for mobile and desktop

## Deployment Instructions

### Deploy to Vercel

1. Create a Vercel account at https://vercel.com
2. Install Vercel CLI:
   ```bash
   npm install -g vercel
   ```
3. Build the web app:
   ```bash
   flutter build web
   ```
4. Deploy to Vercel:
   ```bash
   vercel
   ```

### Deploy to GitHub Pages

1. Create a GitHub repository
2. Push your code to the repository
3. Enable GitHub Pages in repository settings
4. Set the build directory to `build/web`

## Local Development

1. Install Flutter
2. Clone the repository
3. Run the app:
   ```bash
   flutter run -d chrome
   ```

## Technologies Used

- Flutter
- Dart
- Google Fonts
- fl_chart for visualizations
- CSV for report generation
- Real-time currency conversion API
