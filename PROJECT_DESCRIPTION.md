# SwiftUI Builder - Visual iOS App Builder (MVP)

## Overview

**SwiftUI Builder** is a macOS application that enables users to visually design multi-screen iOS apps through a no-code interface. Users compose screens from 16 component types, wire navigation between them, customize every property, preview on real device frames, export SwiftUI source code, and deploy prototypes to iOS Simulator with one click.

## Key Features

### Multi-Screen Builder
- Create and manage multiple screens per project
- Screen list sidebar with add/rename/duplicate/delete
- Screen templates gallery (Onboarding, Login, Profile, Settings, Home Feed, Empty State)
- Per-screen component canvas with real-time preview

### 16 Component Types
Symbol, Headline, Body Copy, Primary Button, List, Image, Text Field, Toggle, Divider, Spacer, Segmented Control, Slider, Avatar, Badge, Search Bar, Progress Bar

### Navigation Builder
- Wire any component to navigate to another screen
- Navigation indicator in canvas outline
- NavigationStack rendering in PreviewRunner

### SwiftUI Code Export
- Generates clean `.swift` source files from visual design
- Maps each component to its SwiftUI equivalent
- Includes NavigationStack + NavigationLink for multi-screen navigation
- Save-panel export to any directory

### Undo/Redo
- Full snapshot-based undo for all structural changes (add/remove/duplicate/move blocks, screen management)
- Standard Cmd+Z / Cmd+Shift+Z through macOS menu

### Keyboard Shortcuts
- Cmd+S: Save project
- Cmd+Shift+E: Export code
- Cmd+D: Duplicate component
- Delete: Remove component
- Cmd+Shift+T: Template gallery
- Cmd+Shift+N: New blank screen

### Drag-and-Drop Reordering
- Context menu Move Up/Down on canvas outline items

### Device Preview
- iPhone SE, iPhone 15 Pro, iPad mini frames
- Light/dark mode with automatic contrast adjustment
- Zoom 65%-135%

### Simulator Integration
- One-click build, install, and launch on iOS Simulator
- Multi-strategy simulator discovery

## Architecture

- **@Observable ProjectStore** -- centralized state management
- **Dual-target Xcode project** -- macOS builder (`alpha`) + iOS runner (`PreviewRunner`)
- **Shared code** -- `CanvasModels.swift` and `CanvasViews.swift` used by both targets
- **JSON persistence** -- backward-compatible schema with `blocks` + `screens` fields
- **Zero external dependencies** -- pure Swift/SwiftUI

## Project Structure

```
alpha/
├── alpha/                          # macOS builder app
│   ├── alphaApp.swift             # App + keyboard commands
│   ├── ContentView.swift          # Root view, owns ProjectStore
│   ├── ProjectStore.swift         # @Observable centralized state
│   ├── BuilderWorkspaceV2.swift   # Main workspace layout
│   ├── ScreenListView.swift       # Screen management sidebar
│   ├── ComponentLibraryView.swift # Component library + outline
│   ├── CanvasColumnView.swift     # Device preview canvas
│   ├── InspectorView.swift        # Property editor + navigation
│   ├── CodeGenerator.swift        # SwiftUI code export
│   ├── TemplateGallery.swift      # Screen template picker
│   ├── SimulatorLauncher.swift    # Build & launch automation
│   ├── WorkspaceToolbar.swift     # Top toolbar
│   ├── WorkspaceTheme.swift       # Theme system
│   └── Shared/
│       ├── CanvasModels.swift     # Screen, CanvasBlock, export models
│       └── CanvasViews.swift      # DevicePreview, CanvasBlockView
├── PreviewRunner/                 # iOS preview app
│   ├── PreviewRunnerApp.swift     # iOS entry point
│   └── ContentView.swift          # Multi-screen NavigationStack renderer
└── alpha.xcodeproj/
```
