# Adaptive Platform UI Implementation Plan

## Context
The user wants the app to have native-looking UI on both Android (Material Design) and iOS (Cupertino). Currently, the app uses Material Design on both platforms, which looks less native on iOS.

## Approach
Create adaptive wrapper widgets that automatically switch between Material and Cupertino based on `Theme.of(context).platform`. This maintains a single codebase while providing native feel on each platform.

---

## Files to Create

### 1. `lib/core/widgets/adaptive_widgets.dart`
New file containing reusable adaptive widgets:
- `AdaptiveAppBar` - Material AppBar / CupertinoNavigationBar
- `AdaptiveButton` - ElevatedButton / CupertinoButton
- `AdaptiveTextField` - TextFormField / CupertinoTextField
- `AdaptiveDialog` - AlertDialog / CupertinoAlertDialog
- `AdaptiveProgressIndicator` - CircularProgressIndicator / CupertinoActivityIndicator
- `AdaptiveScaffold` - Scaffold / CupertinoPageScaffold
- `AdaptiveTabBar` - BottomNavigationBar / CupertinoTabBar

### 2. `lib/core/utils/platform_utils.dart`
Platform detection utilities:
- `isIOS(BuildContext context)` helper
- `adaptiveIcon()` for icon mapping

---

## Files to Modify

### 1. `lib/screens/home/home_screen.dart`
- Replace `BottomNavigationBar` with `AdaptiveTabBar`
- Wrap in `CupertinoTabScaffold` for iOS

### 2. `lib/screens/home/home_view.dart`
- Replace `AppBar` with `AdaptiveAppBar`
- Replace `ElevatedButton` with `AdaptiveButton`

### 3. `lib/screens/result/result_screen.dart`
- Replace `AppBar` with `AdaptiveAppBar`
- Replace action buttons with adaptive versions

### 4. `lib/screens/history/history_screen.dart`
- Replace `AppBar` with `AdaptiveAppBar`
- Replace dialog with `AdaptiveDialog`

### 5. `lib/screens/favourites/favourites_screen.dart`
- Replace `AppBar` with `AdaptiveAppBar`

### 6. `lib/screens/templates/templates_screen.dart`
- Replace Material `TabBar` with adaptive segmented control for iOS

### 7. `lib/screens/settings/settings_screen.dart`
- Replace `SegmentedButton` with `CupertinoSegmentedControl` for iOS
- Replace `ListTile` with `CupertinoListTile` for iOS

### 8. `lib/screens/auth/login_screen.dart`
- Replace `TextFormField` with `AdaptiveTextField`
- Replace buttons with `AdaptiveButton`

### 9. `lib/screens/auth/signup_screen.dart`
- Same as login screen

### 10. `lib/screens/auth/forgot_password_screen.dart`
- Same adaptive inputs

### 11. `lib/app.dart`
- Use `CupertinoApp` for iOS, `MaterialApp` for Android (via adaptive wrapper)

---

## Implementation Order

1. **Phase 1: Core Infrastructure**
   - Create `platform_utils.dart`
   - Create `adaptive_widgets.dart`

2. **Phase 2: Main Navigation**
   - Update `home_screen.dart` (tab bar)
   - Update `app.dart` (app wrapper)

3. **Phase 3: Screen-by-Screen Updates**
   - `home_view.dart`
   - `result_screen.dart`
   - `history_screen.dart`
   - `favourites_screen.dart`
   - `templates_screen.dart`
   - `settings_screen.dart`
   - Auth screens

4. **Phase 4: Polish**
   - Test transitions and animations
   - Ensure consistent theming
   - Fix any platform-specific edge cases

---

## Key Adaptive Widget Pattern

```dart
class AdaptiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const AdaptiveAppBar({required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    if (isIOS) {
      return CupertinoNavigationBar(
        middle: Text(title),
        trailing: Row(children: actions ?? []),
      );
    }
    return AppBar(title: Text(title), actions: actions);
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
```

---

## Navigation Transitions

- **Android**: `MaterialPageRoute` (slide up)
- **iOS**: `CupertinoPageRoute` (slide from right)

Create helper:
```dart
Route adaptiveRoute(Widget page) {
  if (Platform.isIOS) {
    return CupertinoPageRoute(builder: (_) => page);
  }
  return MaterialPageRoute(builder: (_) => page);
}
```

---

## Verification

1. Run app on Android emulator - verify Material Design is intact
2. Run app on iOS simulator - verify Cupertino styling
3. Test all navigation flows
4. Test all forms and inputs
5. Test dialogs and bottom sheets
