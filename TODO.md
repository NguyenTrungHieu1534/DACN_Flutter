# Dark Mode Implementation Plan

## Information Gathered
- The app uses a `ThemeProvider` to toggle between light and dark themes in `main.dart`.
- `AppTheme.dart` defines a complete `darkTheme` with appropriate dark colors (e.g., scaffoldBackgroundColor: Color(0xFF0A1929), cardColor: Color(0xFF1A2332)).
- `LibraryScreen`, `SearchScreen`, and `AlbumDetailScreen` have hardcoded `backgroundColor: AppColors.mist` (light color), overriding the theme.
- Cards in these screens use `color: Colors.white`, which doesn't adapt to dark mode.
- Text colors use `AppColors.oceanDeep` (dark blue), which may not be suitable for dark backgrounds.
- The theme is properly set up, but screens are not respecting it due to hardcoded values.

## Plan
- Remove hardcoded `backgroundColor: AppColors.mist` from `LibraryScreen`, `SearchScreen`, and `AlbumDetailScreen` to let the theme handle background colors.
- Replace `color: Colors.white` in cards with `color: Theme.of(context).cardColor` for theme-aware card backgrounds.
- Update text colors to use theme-aware colors:
  - Body text: `color: Theme.of(context).textTheme.bodyMedium!.color`
  - Titles: `color: Theme.of(context).textTheme.titleMedium!.color`
  - Subtitles: `color: Theme.of(context).textTheme.bodySmall!.color`
- Keep border colors using `AppColors` for now, as they are subtle and may work in both modes; adjust if needed after testing.

## Dependent Files to Edit
- `DACN/lib/screens/library_screen.dart`
- `DACN/lib/screens/search_screen.dart`
- `DACN/lib/screens/album_detail_screen.dart`

## Followup Steps
- Run the app and toggle to dark mode to verify all pages use dark backgrounds and appropriate colors.
- Test Library, Search, and Album Detail screens specifically.
- If borders or other elements look off in dark mode, adjust colors to use theme-aware alternatives (e.g., `Theme.of(context).dividerColor`).
- Ensure no light mode remnants remain on any pages.
