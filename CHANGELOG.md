# SwiftBuilder Changelog

All notable changes to the SwiftBuilder project are documented here.

---

## [2026-04-26] SwiftLint Project Integration

**Type:** Tooling

### Linting
- Added a root `.swiftlint.yml` for SwiftBuilder and PreviewRunner sources.
- Added SwiftLint build phases to both Xcode targets.
- Build phases run SwiftLint when installed and emit a warning with install guidance when missing.

---

## [2026-04-26] Preview Pinch Zoom and Canvas Scrolling

**Type:** Bug Fix / UX

### Preview Canvas Zoom
- Replaced visual-only preview scaling with a native macOS zoomable scroll container.
- Added touchpad pinch zoom support for the SwiftBuilder center preview canvas.
- Expanded preview zoom range to 25%-300%.
- Added preview fit-to-window and reset-to-100% controls.

### Preview Canvas Scrolling
- Fixed zoomed preview scrolling so the full top, bottom, left, and right edges remain reachable.
- Centered fitted and zoomed-out previews inside the canvas viewport.
- Kept PreviewRunner simulator/device launch behavior unchanged.

---

## [2026-04-26] Custom App Icon Upload for PreviewRunner

**Type:** Feature / Bug Fix

### App Icon Upload
- Added a toolbar app icon control that lets users upload, replace, or remove a custom app icon for the current project.
- Added `Shift+Cmd+I` menu support for uploading an app icon.
- Selected images are normalized to a 1024x1024 PNG before use.
- Added security-scoped file access for selected image files from the macOS file picker.

### PreviewRunner Icon Build Integration
- PreviewRunner simulator and real-device builds now use the selected project icon when launching previews.
- Generated PreviewRunner icon assets are written to `PreviewRunner/Assets.xcassets/SwiftBuilderGeneratedAppIcon.appiconset/`.
- Added `.gitignore` coverage for generated PreviewRunner icon assets so default tracked assets remain unchanged.

### App Icon Upload Crash Fix
- Replaced the crashing AppKit `NSGraphicsContext` drawing path with a CoreGraphics/ImageIO renderer.
- Smoke-tested icon generation with a repo PNG and confirmed a valid 1024x1024 RGB PNG output.

---

## [2026-04-26] Real-Device PreviewRunner Launch

**Type:** Feature

### Run Target Selection
- Added `RunTarget` support for choosing between Simulator and Real Device.
- Added physical-device state to `ProjectStore`, including connected iPhone discovery, selected device tracking, and refresh status messaging.
- Updated the workspace toolbar with a compact run-target selector and connected-iPhone picker.

### Physical iPhone Launch Flow
- Added connected-device discovery using `xcrun devicectl list devices --json-output`.
- Added PreviewRunner device builds with `xcodebuild -sdk iphoneos -destination id=<deviceID>`.
- Added install, project JSON transfer, and launch support using `devicectl`.
- Kept the existing simulator launch path intact while routing both targets through one high-level launch flow.

### User Guidance
- Added clearer errors for missing or unavailable iPhones, locked/untrusted devices, Developer Mode issues, signing/provisioning failures, and incomplete Xcode CLI setup.

---

## [2026-03-25] Full Project Rename, Fullscreen, Interactivity Fix, Template Redesign

**Type:** Refactor / Feature / Bug Fix

### Full Rename: alpha -> SwiftBuilder
- Renamed repo root folder, source folder, and Xcode project from `alpha` to `SwiftBuilder`
- Updated `project.pbxproj`: target name, product name, product reference, bundle ID (`com.vintuss.SwiftBuilder`), build configuration labels, synchronized root group path
- Renamed `struct alphaApp` to `struct SwiftBuilderApp` in `SwiftBuilderApp.swift`
- Updated all hard-coded `alpha.xcodeproj` paths in `SimulatorLauncher.swift`, `ProjectStore.swift`, and `deploy_preview.sh`
- Updated scheme management plist from `alpha.xcscheme` to `SwiftBuilder.xcscheme`
- Updated `PROJECT_DESCRIPTION.md` directory tree to reflect new atomic design structure
- Updated file header comments across all Swift files

### Auto Fullscreen on Launch
- macOS builder now automatically enters fullscreen mode 0.5s after launch via `NSApplication.shared.mainWindow?.toggleFullScreen(nil)` in `ContentView.onAppear`

### Component Interactivity Fix (Invisible Shield)
- **Root cause**: `CanvasBlockView.body` unconditionally applied `.contentShape(Rectangle())` and `.onHover`, which interfered with gesture recognition on interactive child views (TextField, Toggle, Slider, etc.) on iOS
- **Fix**: In interactive mode (PreviewRunner), the view now renders `buildContent()` directly without `SelectionOutline`, `.contentShape`, or `.onHover` wrappers
- **NavigationLink fix**: Only button-type and navigable components (primaryButton, secondaryButton, linkButton, card, iconRow) are wrapped in `NavigationLink`; interactive controls (toggle, slider, textField, searchBar, segmentedControl) are never wrapped, preventing tap interception

### Redesigned Initial Screen Template
- Replaced the minimal 4-component starter (icon, title, body, button) with a richer 8-component layout:
  - Heading ("Good Morning"), subtitle, search bar, card with description, section caption, icon row, toggle, and primary CTA button
- Showcases more component variety to new users on first launch

---

## [2026-03-25] Atomic Design File Reorganization

**Type:** Refactor

Reorganized the entire project from 17 monolithic files into 40 focused, single-responsibility modules using Atomic Design principles (Atoms, Molecules, Organisms).

### New Directory Structure

```
SwiftBuilder/
  App/                     Entry point (SwiftBuilderApp, ContentView)
  Core/
    Models/                Data models (CanvasBlock, Screen, DevicePreset, etc.)
    Export/                Serialization (ExportModels, ProjectExporter, CanvasBlock+Export)
    Extensions/            Color+Utilities
    Theme/                 WorkspaceTheme, DesignTokens (Spacing, TypographyPreset)
    Services/              ProjectStore, SimulatorLauncher, CodeGenerator
  Components/
    Atoms/                 BlockRow, SelectionOutline, PanelHeader, PanelDivider, PillDivider
    Molecules/             CanvasBlockView, ScreenRow, TemplateCard
    Organisms/             DevicePreview, InspectorView, ComponentLibraryView,
                           CanvasOutlineView, ScreenListView, WorkspaceToolbar,
                           TemplateGallery, CanvasColumnView
  Screens/                 BuilderWorkspaceV2
  Resources/               ScreenTemplates (static template data)

PreviewRunner/
  App/                     PreviewRunnerApp
  Views/                   ContentView, ScreenContentView
  Services/                ProjectLoader
  Utilities/               ShakeGesture
```

### Files Split

| Original File | Lines | Split Into |
|---|---|---|
| Shared/CanvasModels.swift | 875 | 10 files across Core/Models, Core/Export, Core/Extensions |
| Shared/CanvasViews.swift | 911 | BlockRow, DevicePreview, CanvasBlockView, SelectionOutline |
| ComponentLibraryView.swift | 307 | ComponentLibraryView + CanvasOutlineView |
| TemplateGallery.swift | 407 | TemplateGallery + TemplateCard + ScreenTemplates |
| WorkspaceTheme.swift | 146 | WorkspaceTheme + DesignTokens + PanelHeader + PanelDivider |
| ScreenListView.swift | 150 | ScreenListView + ScreenRow |
| WorkspaceToolbar.swift | 173 | WorkspaceToolbar + PillDivider |
| PreviewRunner/ContentView.swift | 336 | ContentView + ScreenContentView + ProjectLoader + ShakeGesture |

---

## [2026-03-25] Component Interactivity & Navigation Fixes

**Type:** Feature / Bug Fix

### Interactive Components
- **Toggle**: Replaced broken custom Capsule/Circle implementation with native SwiftUI `Toggle` using `.toggleStyle(.switch)` and `.frame(maxWidth: .infinity)` for correct iOS-style appearance on all platforms.
- **Segmented Control**: Added `@State selectedSegment` with tap-to-switch and spring animation in interactive mode.
- **Slider**: Added `@State sliderValue` with native `Slider(value:in:)` in interactive mode; static mode retains custom capsule bar.

### Navigation
- Fixed missing back button on pushed screens in PreviewRunner by removing blanket `.toolbar(.hidden)` and adding `isRoot` parameter to `ScreenContentView`.
- All screens now show their name as an inline navigation title.

---

## [Earlier] UI/UX Overhaul & Feature Development

### Selection Outline Redesign
- Replaced padding-based corner handles with clean dashed-border overlay and subtle tint background.

### TextField Interactivity
- Made text fields and search bars typable in PreviewRunner with `.foregroundColor(.primary)` for entered text.

### Multi-Column Layout
- Added `rowGroupID` to `CanvasBlock` for grouping blocks into horizontal rows.
- Context menu actions: "Merge with Next into Row" / "Remove from Row" in outline view.
- `BlockRow` helper groups consecutive same-group blocks into `HStack` rendering.

### Device Previews
- Expanded to 7 device models: iPhone SE, iPhone 16, 16 Pro, 16 Pro Max, iPhone Air, iPad mini, iPad Air 11".
- Realistic device chrome with dynamic island, home button, side buttons, and speaker grille.

### Inspector Enhancements
- Collapsible sections for content, typography, colors, layout, style, and navigation.
- Extended controls: opacity, border width, line spacing, shadow radius.

### Template Gallery
- 6 pre-built screen templates: Onboarding, Login, Profile, Settings, Home Feed, Empty State.

### App Rename
- Renamed from "alpha" to "SwiftBuilder" across UI and documentation.
