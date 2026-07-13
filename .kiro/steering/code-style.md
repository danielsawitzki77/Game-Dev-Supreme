# Code Style Guide (All C++ Projects)

When writing or modifying C++ code in ANY project in this workspace, follow these conventions **strictly**. Non-compliance will be flagged and must be fixed before a PR is created.

This applies to: Particluar, Zeitgeist Evolved, TerrorForm, Super Civ 16, SDL_VisualTest — all game/engine projects.

## Design Philosophy: OOP First

All projects use **object-oriented design as the default paradigm**. Every piece of meaningful logic belongs in a class.

### Classes Over Free Functions

- **Prefer classes and methods** for any logic that is reusable, testable, or stateful.
- Each class should have a single responsibility and a clear public interface.
- State is private; access is through public methods.
- Init/Load methods are separate from constructors (allow re-initialization).
- If logic operates on data that could evolve, it belongs in a class — not a standalone function.

### Static Functions: Strongly Discouraged

**Do NOT use static (free-standing) functions** except in these narrow cases:

1. **Truly private single-use helpers** within a single `.cpp` file (< 10 lines, not reusable)
2. **Static factory methods** on a class (e.g., `Shape::CreateCylinder(...)`)

Everything else must be a class method. If you find yourself writing a static helper that does math, geometry, or any transformation — it belongs in the **math library** (`math_lib/`).

### Math Belongs in math_lib

Every project in this workspace has (or will have) a `math_lib/` static library containing shared math types and utilities (`Vec3`, `Mat4`, geometric helpers, etc.).

**Rules:**
- **Never put math helper functions in `main.cpp` or application code.** Move them to `math_lib/`.
- If a math function is needed by multiple files, it MUST be in `math_lib/`.
- If a math function is only needed in one place but performs a general operation (dot product, normalize, distance, interpolation), it still goes in `math_lib/` — it will be reused later.
- `math_lib/` functions should be organized in focused classes (e.g., `MathUtil`, `GeomUtil`, `Interpolation`) rather than dumped into a single utility header.

### main.cpp Must Stay Minimal

The application entry point (`main.cpp`) must:
- Only create SDL/platform resources (window, renderer, GL context)
- Load config
- Instantiate high-level manager objects
- Run the main loop: poll events → update → render
- **Never** contain domain logic, math helpers, or algorithm implementations

**If a feature requires more than 10 lines of new code in main.cpp, it belongs in a library class.**

---

## Folder Naming
- All lowercase, underscore-separated: `body_renderer`, `tile_renderer`, `math_lib`
- These are filesystem folder names only — NOT Visual Studio project/filter names

## Visual Studio Project & Filter Naming
- PascalCase, no underscores: `BodyRenderer`, `TileRenderer`, `MathLib`, `BodyRendererTests`
- The `.vcxproj` file name matches the project name: `BodyRenderer.vcxproj`
- Solution folders / filters also use PascalCase: `BodyRenderer`, `Tests`

## File Naming
- Source files (`.cpp`, `.h`): PascalCase — `BodyTypes.h`, `WFCGenerator.cpp`, `TestBodyLoader.cpp`
- vcxproj files: PascalCase — `TileRenderer.vcxproj`, `BodyViewer.vcxproj`

## Subsystem Prefixes (folder names only)
| Folder prefix | Domain |
|---------------|--------|
| `tile_` | 2D tile/map rendering and WFC generation |
| `body_` | 3D body/shape rendering and joint system |
| `math_` | Shared math library |

These prefixes apply **only to filesystem folder names**. The corresponding VS project names use PascalCase without underscores (e.g., folder `body_renderer/` → VS project `BodyRenderer`).

## Code Identifiers

| Category | Convention | Example |
|----------|-----------|---------|
| Namespaces | PascalCase | `BodyRenderer`, `Particluar` |
| Classes / Structs | PascalCase | `WFCGenerator`, `BodyNode`, `PlacedTile` |
| Enum types | PascalCase | `ShapeType`, `WFCStatus` |
| Enum values | PascalCase (no underscores) | `FaceConnection`, `TopCap` |
| Public methods | PascalCase | `SetPosition`, `GenerateJigsaw` |
| Private methods | PascalCase | `RenderNode`, `SplitGap` |
| Member variables | `m_` + camelCase | `m_cacheValid`, `m_pivotX` |
| Struct POD fields | camelCase (no prefix) | `targetWidth`, `parentFaceIndex` |
| Function parameters | camelCase | `deltaTime`, `startRow` |
| Local variables | camelCase | `tileSize`, `numSamples` |
| Constants / defines | UPPER_SNAKE_CASE | `MAX_LIGHTS`, `DEFAULT_SEED` |

## Naming Enforcement

These naming rules are **not suggestions**. Every variable, class, method, and file must follow the table above. Common mistakes to avoid:

- ❌ `snake_case` local variables — use `camelCase`
- ❌ `PascalCase` local variables — use `camelCase`
- ❌ `camelCase` methods — use `PascalCase`
- ❌ `m_PascalCase` members — use `m_camelCase`
- ❌ Free functions where a class method would work
- ❌ Math helpers in main.cpp or test files — move to `math_lib/`
