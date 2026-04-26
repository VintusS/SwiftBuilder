# SwiftBuilder

## Project Title

**MacOS Platform for Real-Time Visual Interface Prototyping for iOS Applications**

SwiftBuilder is the implemented prototype for the bachelor thesis with the subject above. The system provides a native macOS environment for visually composing multi-screen iOS interface prototypes, exporting SwiftUI source code, and validating the result through a companion iOS runner application.

## Project Purpose

The purpose of SwiftBuilder is to reduce the distance between an interface idea and a realistic native iOS prototype. Static design tools are useful for visual exploration, while Xcode provides full native control, but early validation of screen flow, navigation, component behavior, and device-specific presentation still requires significant manual SwiftUI work. SwiftBuilder addresses this gap by combining visual authoring, structured project persistence, SwiftUI export, and runner-backed native execution in one local-first workflow.

The project is intended for:

- students learning SwiftUI-oriented interface architecture;
- independent iOS developers validating early product ideas;
- designers and product stakeholders who need more realistic prototypes than static boards;
- academic evaluation of a native visual builder architecture.

## Technologies and Tools

| Area | Technology / Tool | Role |
|------|-------------------|------|
| Main language | Swift | Implementation language for the builder and runner targets. |
| UI framework | SwiftUI | Builder interface, component rendering, generated source, and runner presentation. |
| macOS integration | AppKit and Foundation | File dialogs, file-system access, image handling, process execution, and local storage. |
| iOS runtime | PreviewRunner target | Runs saved prototypes on simulator or connected physical device. |
| Shared package | SwiftBuilderComponents | Reusable project model, component rendering, export transport types, and screen templates. |
| Persistence | JSON with Codable | Local project format and builder-to-runner transfer contract. |
| Build and run automation | Xcode command-line tools, simctl, devicectl | Builds, installs, transfers project data, and launches the runner target. |
| Code quality | SwiftLint | Development-time linting through target build phases and a root `.swiftlint.yml`. |
| IDE | Xcode | Project editing, build, simulator execution, and device signing. |

## Requirements

- macOS 14 or newer;
- Xcode with command-line tools installed;
- iOS 17 simulator runtime or a connected iPhone for runner validation;
- SwiftLint installed locally if lint warnings should be checked during build.

SwiftLint is optional for running the application. If it is not installed, the build phase emits guidance instead of blocking the build.

## Running the Application

1. Keep the application and component package available as sibling folders:

   ```text
   SwiftBuilder/
   SwiftBuilderComponents/
   ```

2. Open the Xcode project:

   ```bash
   open SwiftBuilder.xcodeproj
   ```

3. Select the `SwiftBuilder` scheme and a macOS run destination.

4. Build and run the macOS builder from Xcode.

5. In the builder, create or edit a project by adding screens, inserting components, editing properties, configuring navigation, and saving the project.

6. To export SwiftUI source code, use the `Export Code` action and choose an output file.

7. To execute the prototype natively:

   - choose a simulator or connected-device run target in the toolbar;
   - save the current project;
   - press `Run`;
   - allow the builder to build, install, transfer data to, and launch `PreviewRunner`.

For physical-device execution, the iPhone must be connected, trusted, available for development, and compatible with the signing configuration in Xcode.

## Application Structure

```text
SwiftBuilder/
  SwiftBuilder.xcodeproj          Xcode project for the macOS builder and iOS runner
  .swiftlint.yml                  SwiftLint configuration used by the build phases
  CHANGELOG.md                    Development history and implementation notes
  PROJECT_DESCRIPTION.md          Detailed internal project description
  deploy_preview.sh               Helper script for preview deployment
  SavedProjects/                  Local saved JSON project examples

  SwiftBuilder/
    App/                          macOS application entry point and root content view
    Screens/                      Builder workspace screen
    Core/
      Models/                     Device, zoom, and run-target models
      Export/                     Project export logic
      Services/                   ProjectStore, simulator/device launch, code generation, app icon generation
      Theme/                      Workspace styling and design tokens
    Components/
      Atoms/                      Small reusable visual elements
      Molecules/                  Mid-level reusable UI rows and cards
      Organisms/                  Workspace panels, toolbar, canvas, library, inspector, template gallery

  PreviewRunner/
    App/                          iOS runner application entry point
    Services/                     Project loading from local, mirrored, or bundled sources
    Views/                        Runtime screen and component presentation
    Utilities/                    Runner-specific helpers
    Assets.xcassets/              Runner assets and generated app icon set
    Prototype.json                Bundle fallback project
```

## Main Features

- multi-screen project management with create, rename, duplicate, select, and delete actions;
- component library with 22 built-in UI component types grouped into 6 categories;
- contextual inspector for content, typography, colors, layout, style, and navigation;
- device-aware preview with light and dark appearance modes;
- JSON project persistence with backward-compatible loading;
- SwiftUI source-code export for single-screen and multi-screen projects;
- runner execution on simulator or connected iPhone;
- app icon handoff to the runner build;
- undo/redo, keyboard shortcuts, and template-driven screen creation.

## Relationship to SwiftBuilderComponents

`SwiftBuilderComponents` contains the reusable parts that should remain stable across the macOS builder and the iOS runner:

- project entities such as screens and canvas blocks;
- component metadata and rendering logic;
- export transport structures;
- pre-built screen templates;
- color and rendering utilities.

This separation keeps the host application focused on editing workflow, file operations, code export, and runner orchestration, while the package preserves the shared interpretation of project data and visual components.

