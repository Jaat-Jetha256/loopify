# Loopify iOS Widget — Wire Up in Xcode

All Swift / asset / entitlement files are already on disk. You just need to add a Widget Extension target to the Xcode project and point it at this folder.

## 1. Open the workspace

```
open "ios/Runner.xcworkspace"
```

## 2. Add a Widget Extension target

1. File → New → Target…
2. Pick **Widget Extension** (iOS) → Next
3. Product Name: **LoopifyWidget**
4. Bundle Identifier: **com.loopify.loopify.LoopifyWidget**
5. Language: **Swift**
6. **UNCHECK** "Include Configuration Intent" (we use StaticConfiguration)
7. Finish. When asked to "Activate scheme", click **Activate**.

Xcode will create a folder `LoopifyWidget/` with stub files. **Delete** Xcode's stubs (the auto-generated `LoopifyWidget.swift`, `LoopifyWidgetBundle.swift`, `Assets.xcassets`, `Info.plist`) — choose **Move to Trash** so they're gone from disk. Don't worry, the real ones are already in this folder.

## 3. Re-add the real files

In Finder, the folder `ios/LoopifyWidget/` already contains:

- `LoopifyWidget.swift`
- `Info.plist`
- `LoopifyWidget.entitlements`
- `Assets.xcassets/` (with widget_1, widget_2, widget_3, AccentColor, WidgetBackground)

In Xcode, right-click the `LoopifyWidget` group → **Add Files to "Runner"…** → select all four items above. In the dialog:

- ✅ "Copy items if needed" — **OFF** (they're already there)
- ✅ "Create groups"
- ✅ Target membership: **LoopifyWidget only** (not Runner)

## 4. Point Info.plist + entitlements at the right files

Select the **LoopifyWidget** target → **Build Settings**:

- `INFOPLIST_FILE` → `LoopifyWidget/Info.plist`
- `CODE_SIGN_ENTITLEMENTS` → `LoopifyWidget/LoopifyWidget.entitlements`

## 5. Add App Group to the Runner target

Select the **Runner** target → **Signing & Capabilities**:

1. **+ Capability** → **App Groups**
2. Add group: `group.com.loopify.loopify`
3. Xcode should create / update `Runner/Runner.entitlements` — the file already exists with the correct content; just make sure `CODE_SIGN_ENTITLEMENTS` on the Runner target is set to `Runner/Runner.entitlements`.

Then select the **LoopifyWidget** target → **Signing & Capabilities** → **+ Capability** → **App Groups** → tick the same `group.com.loopify.loopify`.

Both targets must show the **same** app group with a green check.

## 6. Deployment target

LoopifyWidget target → General → **Minimum Deployments** → **iOS 14.0** (WidgetKit minimum).

## 7. Build

```
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter build ios --release --no-codesign
```

Then re-sign / package as usual for iLoader.

## 8. After install

Long-press home screen → **+** → search **Loopify** → add the small or medium widget. It should pull live data from the app the next time you log a habit (the app calls `WidgetService.updateWidget()` automatically).

---

### Files at a glance

```
ios/LoopifyWidget/
├─ LoopifyWidget.swift          ← Provider + glassmorphism SwiftUI view
├─ Info.plist                   ← WidgetKit extension declaration
├─ LoopifyWidget.entitlements   ← App group for shared UserDefaults
└─ Assets.xcassets/
   ├─ AccentColor.colorset/
   ├─ WidgetBackground.colorset/
   ├─ widget_1.imageset/
   ├─ widget_2.imageset/
   └─ widget_3.imageset/

ios/Runner/Runner.entitlements  ← App group for the main app
```

### Where the data comes from

`WidgetService.updateWidget()` (lib/services/widget_service.dart) writes 4 keys via `home_widget`:

- `streak` (Int)
- `habits_completed` (Int)
- `quip` (String)
- `image` (String — `"1.png" | "2.png" | "3.png"`)

These land in `UserDefaults(suiteName: "group.com.loopify.loopify")`. The widget reads them in `LoopifyProvider.currentEntry()`.
