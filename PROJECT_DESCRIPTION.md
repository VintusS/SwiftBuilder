# SwiftBuilder — Visual iOS App Builder

## Overview

**SwiftBuilder** is a native macOS application that enables users to visually design multi-screen iOS app prototypes through a no-code drag-and-compose interface. Built entirely in Swift and SwiftUI with zero external dependencies, it targets designers, students, and rapid prototypers who want to go from idea to interactive prototype without writing code.

The tool operates as a dual-target Xcode project: a **macOS builder** (`SwiftBuilder`) where screens are composed and customized, and an **iOS runner** (`PreviewRunner`) that renders the exported prototype on a real device or simulator with full navigation.

---

## Application Architecture

### Dual-Target Structure

| Target | Platform | Role |
|--------|----------|------|
| `SwiftBuilder` | macOS | The visual builder IDE — compose screens, customize properties, preview on device frames, export code |
| `PreviewRunner` | iOS | Lightweight runner app that loads an exported JSON project and renders it as a live, navigable prototype |

Both targets share code through the `SwiftBuilder/Core/` and `SwiftBuilder/Components/` folders, which contain all data models, export/import logic, and component rendering views. The PreviewRunner target includes a subset of these files via Xcode's file system synchronization exceptions.

### State Management

All application state lives in a single `@Observable` class called `ProjectStore`. It holds the screen list, selected screen/block, device settings, appearance, zoom level, project name, build state, and undo manager. Every view in the builder reads from and writes to this store.

Undo/redo is implemented via snapshot-based `UndoManager` integration. Before any structural change (adding/removing/reordering blocks, screen management), the store captures a snapshot of `screens`, `selectedScreenID`, and `selectedBlockID`, then registers an undo action that restores that snapshot. Standard macOS Cmd+Z / Cmd+Shift+Z work through the menu system.

### Persistence Format

Projects are saved as JSON files with the following schema:

```
BuilderProject {
    name: String
    device: String              // DevicePreset raw value
    appearance: String          // "light" or "dark"
    blocks: [ExportedBlock]     // Legacy: primary screen blocks
    screens: [ExportedScreen]?  // Multi-screen array (preferred)
    exportedAt: Date            // ISO 8601
}
```

Each `ExportedBlock` contains all visual properties: `kind`, `content`, `symbolName`, `alignment`, `fontSize`, `fontWeight`, text/fill colors as RGBA components, layout values (spacing, padding, corner radius), `symbolScale`, `listItems`, optional `navigationTarget` UUID, and style properties (`opacity`, `borderWidth`, `lineSpacing`, `shadowRadius`). New properties are encoded as optional fields so older JSON files still load with sensible defaults.

Save locations:
- Primary: `SavedProjects/<ProjectName>.json` relative to the project root
- Mirror: `~/Documents/SwiftUIBuilderProjects/<ProjectName>.json` (for simulator access)
- Bundle fallback: `PreviewRunner/Prototype.json` (copied at build time)

---

## Workspace Layout

The builder window (minimum 1080×700) is divided into four zones:

```
┌──────────────────────────────────────────────────────────────────┐
│                         TOOLBAR                                  │
├────────────┬──────────────────────────────┬───────────────────────┤
│  SCREENS   │                              │                       │
│  ────────  │                              │      INSPECTOR        │
│  LIBRARY   │     DEVICE PREVIEW           │   (300pt, scrollable) │
│   or       │     (zoomable, scrollable)   │                       │
│  OUTLINE   │                              │                       │
│  (250pt)   │                              │                       │
└────────────┴──────────────────────────────┴───────────────────────┘
```

### Toolbar

The top toolbar uses an ultra-thin material backdrop and is divided into three zones:

- **Left zone**: App title "SwiftBuilder" in bold rounded 18pt, followed by a pill divider, then an editable project name field (160pt wide).
- **Center zone**: Device picker (dropdown menu, 180pt), Appearance segmented picker (Light / Dark, 200pt), zoom slider (65%–135% with magnifying glass icons and percentage readout).
- **Right zone**: More actions menu (Reset Canvas, Run Preview Guide), Save button, Export Code button, and a prominent Run button that shows a spinner while building.

### Left Panel (250pt)

The left panel is split vertically:

1. **Screen List** (top): Shows all screens with selection highlight, block count badges, and hover effects. Each screen row supports:
   - Click to select
   - Context menu: Rename, Duplicate, Delete (delete disabled when only one screen remains)
   - Inline rename via text field
   - Add screen button with spring animation on new rows

2. **Tab Bar**: Switches between Library and Outline views with animated tab selection.

3. **Component Library** (tab 1): Displays all 21 component types organized into 6 categories (Text, Buttons, Inputs, Media, Data Display, Layout). Each component shows its SF Symbol icon, display name, and description. A search field at the top filters components by name or description. Clicking a component adds it to the canvas after the currently selected block, or at the end if nothing is selected.

4. **Canvas Outline** (tab 2): A flat list of all blocks on the current screen showing kind icon, summary text, and navigation indicator (arrow icon for blocks with navigation targets). Supports:
   - Click to select (with spring animation)
   - Drag-and-drop reordering via `.draggable` / `.dropDestination`
   - Context menu Move Up / Move Down
   - Dragged items show at 40% opacity

### Canvas (center)

The center area displays the selected screen inside a realistic device frame. The canvas sits inside a rounded panel with shadow and supports both vertical and horizontal scrolling. A header above the device shows the screen name, device model, appearance mode, and component count.

### Inspector (300pt, right)

The inspector panel shows property controls for the currently selected block, organized into collapsible sections. When no block is selected, it shows an empty state with a "No selection" message and hint text. See the **Inspector** section below for full details.

---

## Component Types (21)

SwiftBuilder provides 21 UI component types organized into 6 categories:

### Text (4)
| Component | Description | Default Template |
|-----------|-------------|------------------|
| **Heading** | Large bold title or headline | 32pt bold, dark text |
| **Body Text** | Paragraph text with line spacing | 18pt regular, grey text |
| **Caption** | Small label or helper text | 13pt regular, muted text |
| **Badge** | Pill-shaped tag or status label | 13pt semibold white on red capsule |

### Buttons (3)
| Component | Description | Default Template |
|-----------|-------------|------------------|
| **Primary Button** | Filled call-to-action button | 18pt semibold white on blue, rounded |
| **Secondary Button** | Outlined secondary action | 17pt semibold blue text, blue border |
| **Link Button** | Text-only tappable link | 16pt medium blue text |

### Inputs (5)
| Component | Description | Default Template |
|-----------|-------------|------------------|
| **Text Field** | Input field with placeholder | 16pt, grey placeholder, light bg |
| **Search Bar** | Search input with magnifying glass icon | 16pt, grey placeholder, light bg |
| **Toggle** | On/off switch with label | 17pt label, green tint |
| **Slider** | Adjustable value slider | Label + track with progress fill |
| **Segmented Control** | Horizontal tab picker | 3 segments, pill selection indicator |

### Media (4)
| Component | Description | Default Template |
|-----------|-------------|------------------|
| **Icon** | Large SF Symbol icon | 80pt light weight, blue |
| **Image** | Image placeholder area | Grey background with photo icon |
| **Avatar** | Circular profile image | 64pt circle with person icon |
| **Map** | Map area placeholder | Green background with map pin |

### Data Display (3)
| Component | Description | Default Template |
|-----------|-------------|------------------|
| **List** | Vertical list of text rows | 3 items, bullet dots, light bg |
| **Card** | Rounded card with title and description | Icon + title + subtitle, shadow |
| **Info Row** | Icon, label, value, and chevron row | Settings-style row with icon badge |

### Layout (3)
| Component | Description | Default Template |
|-----------|-------------|------------------|
| **Divider** | Horizontal separator line | 1pt grey line |
| **Spacer** | Flexible vertical space | 32pt height |
| **Progress Bar** | Horizontal progress indicator | 60% fill, blue tint |

Each component has a palette color used in the inspector chip and component library for visual identification.

---

## Inspector — Property Editor

The inspector is organized into 6 collapsible sections, each with a header showing an SF Symbol icon, uppercase title, and a rotation-animated chevron. Sections expand/collapse with 0.2s easeInOut animation.

### Content Section
Controls specific to the component's primary content:
- **Text components**: Multi-line or single-line text field for the displayed text
- **Buttons**: Title text field + optional SF Symbol icon name for icon-text buttons
- **Toggle**: Label text field + On/Off initial state segmented picker
- **Slider**: Label text field + value percentage slider (0–100%)
- **Segmented Control**: Editable list of segment labels (add/remove, max 5) + selected index stepper
- **Symbol / Image / Avatar**: SF Symbol name field + scale slider
- **Map**: Height scale slider
- **List**: Editable item list (add/remove, max 10)
- **Card**: Title, description, icon SF Symbol fields
- **Info Row**: Title, value/detail, icon SF Symbol, show chevron toggle
- **Progress Bar**: Progress percentage slider

### Typography Section
Available for text-heavy components (headings, body, captions, badges, buttons, inputs, toggles, sliders, lists, cards, info rows, segmented controls, icons, images, avatars):
- **Font size stepper**: Component-specific range (e.g., 16–60pt for headings, 12–30pt for buttons)
- **Font weight picker**: Dropdown menu with 6 options — Thin, Light, Regular, Medium, Semibold, Bold
- **Alignment picker**: Segmented control with left/center/right alignment icons
- **Line spacing slider**: Available for headings (0–20pt), body text (0–20pt), captions (0–12pt), and cards (0–12pt)

### Colors Section
Component-specific color pickers:
- **Text components**: Text Color + Background color (allows colored text blocks)
- **Primary Button**: Label Color + Background
- **Secondary Button**: Label/Border Color + Background
- **Toggle / Slider**: Label Color + Tint
- **Image / Avatar**: Icon Color + Background
- **Card / List / Info Row**: Text Color + Background
- **Divider**: Line Color
- **Progress Bar**: Tint

### Layout Section
- **Spacing Above**: Universal slider (0–60pt, or 4–200pt for spacers)
- **Horizontal / Vertical Padding**: Component-specific ranges (e.g., 4–40pt for buttons, 0–32pt for text)
- **Corner Radius**: Component-specific ranges (e.g., 0–40pt for buttons and images, 0–32pt for cards)
- **Alignment picker**: For symbols, images, avatars
- **Bar Height**: For progress bars (via vertical padding, 4–24pt)
- **Thickness**: For dividers (via border width, 0–6pt)
- **Horizontal inset**: For dividers (0–60pt)

### Style & Effects Section
Available for all non-spacer components:
- **Opacity slider**: 5%–100%
- **Shadow slider**: 0–30pt radius (for headings, body, buttons, badges, cards, info rows, images, avatars, lists, text fields, search bars, maps, symbols)
- **Border Width slider**: 0–6pt (for headings, body, captions, badges, buttons, cards, info rows, images, avatars, lists, text fields, search bars, maps)

Components with internal border rendering (secondary button, text field, card, avatar, list, divider) use the border width property for their own stroke rather than an external overlay, preventing double borders.

### Navigation Section
Shown only when the project has more than one screen:
- **Destination picker**: Dropdown listing all screens plus "None". Wiring a component to a screen means tapping it in the preview runner navigates to that screen.

### Action Buttons
- **Duplicate**: Creates a copy of the selected block
- **Reset**: Reverts the block to its default template values (preserving its ID)
- **Delete**: Removes the block from the canvas

---

## Device Preview

The canvas renders a realistic device frame with proper chrome elements. Seven device presets are available:

### Device Presets

| Device | Screen (pt) | Form Factor | Corner Radius |
|--------|------------|-------------|---------------|
| iPhone SE | 375 × 667 | Home Button | 0 (screen), 36 (frame) |
| iPhone 16 | 393 × 852 | Dynamic Island | 50 / 54 |
| iPhone 16 Pro | 402 × 874 | Dynamic Island | 55 / 59 |
| iPhone 16 Pro Max | 440 × 956 | Dynamic Island | 55 / 59 |
| iPhone Air | 430 × 932 | Dynamic Island | 53 / 57 |
| iPad mini | 744 × 1133 | iPad | 22 / 28 |
| iPad Air 11" | 820 × 1180 | iPad | 22 / 28 |

### Device Chrome

Each device form factor renders different physical elements:

**Dynamic Island devices** (iPhone 16 / Pro / Pro Max / Air):
- Metallic titanium-gradient frame with light/dark edge strokes
- Black pill-shaped Dynamic Island at the top with camera lens and sensor dots
- Home indicator bar near the bottom edge
- Side buttons: power button (right), action button + volume up/down (left)
- 5pt thin bezel all around

**Home Button device** (iPhone SE):
- Thicker top bezel (56pt) with speaker grille
- Thicker bottom bezel (56pt) with circular Touch ID home button and ring
- Classic form factor with flat-edge screen corners
- Side buttons

**iPad devices** (mini / Air 11"):
- 12pt uniform bezel
- Home indicator bar at the bottom
- No side buttons rendered

### Appearance Modes

- **Light**: White canvas background, dark frame shell
- **Dark**: Near-black canvas background (`rgb(0.09, 0.1, 0.12)`), very dark frame

All component colors automatically adjust for dark mode via the `ensuringContrast` system — colors that would be too dark against a dark background are blended toward white to maintain a minimum luminance threshold.

### Zoom

The device preview scales from 65% to 135% with smooth 0.2s animation. The zoom level is controlled via the toolbar slider.

---

## Navigation System

Any component can be wired to navigate to another screen via the Inspector's Navigation section. The navigation target is stored as an optional UUID on the `CanvasBlock`.

**In the Canvas Outline**, blocks with navigation targets display an arrow indicator icon.

**In the PreviewRunner**, navigation is implemented via `NavigationStack` + `NavigationLink`. Tapping a wired component pushes the target screen onto the navigation stack. Buttons without navigation targets show an alert on tap. Missing navigation targets display a small red "nav target not found" badge.

---

## SwiftUI Code Export

The `CodeGenerator` translates the visual design into clean, standalone `.swift` source code:

- **Multi-screen projects** generate a root `NavigationStack` view plus individual `View` structs for each screen (named from the screen name, e.g., "Login" → `LoginView`).
- **Single-screen projects** generate just the screen view.
- Each component maps to its SwiftUI equivalent with all configured properties inlined.
- Navigation links between screens generate `NavigationLink { DestinationView() } label: { ... }`.
- Colors are exported as `Color(red:green:blue:)` literals, with `.clear`, `.black`, `.white` shortcuts.
- Strings are properly escaped for Swift string literals.

Export is triggered via Cmd+Shift+E or the toolbar button, which opens an `NSSavePanel` defaulting to `<ProjectName>.swift`. On success, the exported file is revealed in Finder.

---

## Screen Templates

The Template Gallery (Cmd+Shift+T or toolbar menu) presents 6 pre-built screen templates in a material sheet (640×440 minimum):

| Template | Components | Description |
|----------|-----------|-------------|
| **Onboarding** | Icon, heading, body, primary button | Welcome / feature introduction |
| **Login** | Heading, body, email/password fields, sign in button, forgot password link | Authentication form |
| **Profile** | Avatar, name heading, badge, divider, 4 info rows | User profile with settings rows |
| **Settings** | Heading, search bar, toggles, slider, section captions, info rows, logout button | Full settings screen |
| **Home Feed** | Heading, search bar, segmented control, 2 cards, progress bar, caption | Dashboard with content cards |
| **Empty State** | Spacer, icon, heading, body, primary button | Zero-data placeholder |

Each template card shows a hover effect (1.02 scale, stronger shadow, accent-tinted stroke). Selecting a template creates a new screen with fresh UUIDs for all blocks and selects it.

A "Blank Screen" option is also available, which creates an empty screen with starter blocks (icon, heading, body text, primary button).

---

## Simulator Integration

The "Run on Simulator" pipeline (Cmd+R or toolbar Run button) automates the full build-deploy-launch cycle:

1. **Save & mirror**: The current project JSON is saved to `SavedProjects/` and mirrored to `~/Documents/SwiftUIBuilderProjects/`.
2. **Copy to bundle**: The JSON is copied to `PreviewRunner/Prototype.json` as a build-time fallback.
3. **Open Simulator.app**: Launches the iOS Simulator application.
4. **Find/boot simulator**: Multi-strategy discovery — (1) any already-booted iPhone, (2) exact device name match, (3) fuzzy word match on available iPhone simulators, (4) any available iPhone.
5. **Build PreviewRunner**: Runs `xcodebuild` targeting `PreviewRunner` with the `iphonesimulator` SDK in Debug configuration. Build output is captured to a temp log file.
6. **Install**: Uses `simctl install` to deploy the `.app` bundle to the booted simulator.
7. **Launch**: Uses `simctl launch` with the `SIMCTL_CHILD_ALPHA_PROJECT_DIR` environment variable pointing to the `SavedProjects` directory, so the runner can find the latest export.

The PreviewRunner loads projects in priority order: `ALPHA_PROJECT_DIR` environment → host Documents folder → app sandbox Documents → bundle `Prototype.json`. It picks the newest `.json` file by modification date.

Error handling covers: simulator boot failure, simulator not found, build failure (with truncated log output), app not found, install failure, launch failure, and project not found.

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘S | Save project |
| ⌘⇧E | Export SwiftUI code |
| ⌘R | Run on Simulator |
| ⌘D | Duplicate selected component |
| ⌫ Delete | Delete selected component |
| ⌘⇧T | Open Template Gallery |
| ⌘⇧N | Add new blank screen |
| ⌘Z | Undo |
| ⌘⇧Z | Redo |

---

## Design System

### Spacing Tokens
| Token | Value |
|-------|-------|
| `xs` | 4pt |
| `sm` | 8pt |
| `md` | 12pt |
| `lg` | 16pt |
| `xl` | 20pt |
| `xxl` | 24pt |

### Typography Presets
| Preset | Spec |
|--------|------|
| Section Header | 11pt semibold rounded, uppercase |
| Control Label | 12pt medium |
| Control Value | 12pt regular, monospaced digits |
| Panel Title | 15pt semibold rounded |
| Toolbar Title | 18pt bold rounded |

### Theme Colors
The `WorkspaceTheme` provides light/dark adaptive colors for:
- Workspace background, panel background, elevated background
- Panel and card shadow colors
- Outline stroke and fill (active/inactive)
- Subtle divider
- Hover overlay, pressed overlay, hover stroke
- Secondary and tertiary text

Reusable components `PanelHeader` and `PanelDivider` ensure consistent section chrome across all panels.

---

## Animations & Interactions

- **Block selection**: Spring animation (response 0.32, damping 0.82)
- **Block add/remove**: Opacity + scale(0.95) transition with spring (response 0.35, damping 0.8)
- **Screen add/remove**: Opacity + scale transition with spring
- **Hover effects**: 0.12s easeInOut on canvas blocks (accent outline), screen rows (overlay tint), template cards (scale 1.02 + shadow + accent stroke), component library cards (shadow)
- **Selection outline**: Active = 2pt accent, Hovered = 1.5pt accent at 35% opacity
- **Section collapse**: 0.2s easeInOut with chevron rotation
- **Tab switching**: 0.15s easeInOut
- **Zoom**: 0.2s easeOut
- **Drag-and-drop**: Dragged item at 40% opacity

---

## iOS Preview Runner

The `PreviewRunner` iOS app is a minimal renderer that:

1. Loads the latest exported JSON project on launch
2. Constructs `Screen` and `CanvasBlock` models from the JSON
3. Renders screens inside a `NavigationStack` with `NavigationLink` wiring
4. Applies the project's appearance mode (light/dark) via `preferredColorScheme`
5. Supports legacy single-screen projects (wraps `blocks` array in a single "Main" screen)
6. Shows loading, error, and empty states appropriately
7. Displays a debug overlay (toggled by shaking the device) showing load source, screen count, navigation wiring, and any errors

The runner reuses the exact same `CanvasBlockView` rendering code as the macOS builder, ensuring pixel-perfect fidelity between the builder preview and the running prototype.

---

## Project Structure

```
SwiftBuilder/
├── SwiftBuilder/                   # macOS builder app
│   ├── App/
│   │   ├── SwiftBuilderApp.swift  # @main entry + BuilderCommands (keyboard shortcuts)
│   │   └── ContentView.swift      # Root view, owns @State ProjectStore
│   ├── Core/
│   │   ├── Models/                # CanvasBlock, Screen, DevicePreset, etc.
│   │   ├── Export/                # ExportModels, ProjectExporter, CanvasBlock+Export
│   │   ├── Extensions/            # Color+Utilities
│   │   ├── Theme/                 # WorkspaceTheme, DesignTokens
│   │   └── Services/              # ProjectStore, SimulatorLauncher, CodeGenerator
│   ├── Components/
│   │   ├── Atoms/                 # BlockRow, SelectionOutline, PanelHeader, etc.
│   │   ├── Molecules/             # CanvasBlockView, ScreenRow, TemplateCard
│   │   └── Organisms/             # DevicePreview, InspectorView, ComponentLibrary, etc.
│   ├── Screens/                   # BuilderWorkspaceV2
│   └── Resources/                 # ScreenTemplates
├── PreviewRunner/                 # iOS preview app
│   ├── App/                       # PreviewRunnerApp
│   ├── Views/                     # ContentView, ScreenContentView
│   ├── Services/                  # ProjectLoader
│   └── Utilities/                 # ShakeGesture
├── SavedProjects/                 # Persisted project JSON files
└── SwiftBuilder.xcodeproj/        # Xcode project (dual-target)
```

---

## Technical Highlights

- **Zero external dependencies** — pure Swift 5.9+ / SwiftUI, no SPM packages
- **Shared rendering** — identical `CanvasBlockView` code renders in both macOS builder and iOS runner
- **Backward-compatible JSON** — new properties use optional fields with defaults; old projects load without migration
- **Dark mode contrast** — `Color.ensuringContrast(in:minimumLuminance:)` automatically lightens colors that would be unreadable against dark backgrounds using relative luminance calculation and linear blending
- **Cross-platform color extraction** — `Color.toComponents()` / `rgbComponents()` handles both `NSColor` (macOS) and `UIColor` (iOS)
- **Multi-strategy project discovery** — both `ProjectStore` (finding the Xcode project for builds) and `PreviewRunner` (finding the latest JSON) use cascading fallback strategies with debug logging
