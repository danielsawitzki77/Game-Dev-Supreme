# Implementation Plan: TerrorForm Code Style Refactor

## Overview

This plan implements a comprehensive, behavior-preserving rename refactoring of the TerrorForm C++ codebase (~120 non-vendor files). The refactoring brings all identifiers into compliance with the workspace code-style.md naming conventions using a phased, category-ordered approach with build verification gates after each batch. Each phase targets a single identifier category and produces a compilable intermediate state.

## Tasks

- [x] 1. Phase 0 — Baseline capture
  - [x] 1.1 Build baseline and record warning counts
    - Build the TerrorForm solution in Debug|x64 and Release|x64 using MSVC
    - Record the warning count for each configuration as the baseline reference
    - Confirm zero errors in both configurations before proceeding
    - _Requirements: 7.1, 7.2_
  - [x] 1.2 Run integration test suite and capture baseline output
    - Execute the 64-seed integration test suite (SDL_VisualTest)
    - Capture stdout/stderr output for each seed as the pre-refactor baseline
    - Record the GIF from seed 1 as the visual baseline
    - Generate the baseline Markdown report with screenshots
    - _Requirements: 8.2, 9.1, 9.2, 9.3_

- [x] 2. Checkpoint — Confirm baseline is green
  - Ensure all tests pass, ask the user if questions arise.

- [x] 3. Phase 1 — File renames
  - [x] 3.1 Rename UI_System files to UISystem
    - Rename `UI_System.h` → `UISystem.h` and `UI_System.cpp` → `UISystem.cpp` on disk
    - Update all `#include "UI_System.h"` directives to `#include "UISystem.h"` across all source files
    - Update the `.vcxproj` and `.vcxproj.filters` to reference the new file names
    - _Requirements: 5.1, 5.2, 5.3_
  - [x] 3.2 Build verify after file renames
    - Build Debug|x64 and confirm zero errors
    - Confirm zero new warnings compared to Phase 0 baseline
    - _Requirements: 7.1, 7.2_

- [x] 4. Phase 2 — Class and struct type renames
  - [x] 4.1 Rename Launch_System to LaunchSystem
    - Rename at header declaration, forward declarations, all usages (member types, parameter types, template args, friend declarations)
    - Update across all source files including test files
    - Build verify Debug|x64
    - _Requirements: 10.1, 10.3, 7.1_
  - [x] 4.2 Rename World_Manager to WorldManager
    - Rename at header declaration, forward declarations, all usages
    - Update across all source files including test files
    - Build verify Debug|x64
    - _Requirements: 10.1, 10.3, 7.1_
  - [x] 4.3 Rename Exe_Writer to ExeWriter
    - Rename at header declaration, forward declarations, all usages
    - Update across all source files including test files
    - Build verify Debug|x64
    - _Requirements: 10.1, 10.3, 7.1_
  - [x] 4.4 Rename AI_Title_Service to AITitleService
    - Rename at header declaration, forward declarations, all usages
    - Update across all source files including test files
    - Build verify Debug|x64
    - _Requirements: 10.1, 10.3, 7.1_
  - [x] 4.5 Rename Playstyle_Term_Threshold to PlaystyleTermThreshold
    - Rename at header declaration, forward declarations, all usages
    - Update across all source files including test files
    - Build verify Debug|x64
    - _Requirements: 10.1, 10.3, 7.1_
  - [x] 4.6 Rename Gameplay_Stats to GameplayStats
    - Rename at header declaration, forward declarations, all usages
    - Update across all source files including test files
    - Build verify Debug|x64
    - _Requirements: 10.1, 10.3, 7.1_
  - [x] 4.7 Rename UI_System class to UISystem
    - Rename the class/struct type at header declaration, forward declarations, all usages
    - Update across all source files including test files
    - Build verify Debug|x64
    - _Requirements: 10.1, 10.3, 7.1_
  - [x] 4.8 Build verify Release|x64 after all class renames
    - Build Release|x64 and confirm zero errors and zero new warnings
    - _Requirements: 7.1, 7.2_

- [x] 5. Phase 3 — Enum type and value renames
  - [x] 5.1 Audit all enum declarations for naming violations
    - Scan all enum type names for snake_case or underscore-separated naming
    - Scan all enum values for snake_case or UPPER_SNAKE_CASE (excluding `#define` constants)
    - Skip any that are already PascalCase-compliant
    - Document which enums (if any) need renaming
    - _Requirements: 6.1, 6.2, 6.5_
  - [x] 5.2 Rename non-compliant enum types and values
    - For each violating enum type: rename to PascalCase at declaration and all usage sites
    - For each violating enum value: rename to PascalCase at declaration, switch/case statements, comparisons, assignments, and function arguments
    - Build verify Debug|x64 after each enum rename batch
    - If no violations found, document that enums are already compliant and skip
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 7.1_

- [x] 6. Checkpoint — Build and smoke test after type-level renames
  - Ensure all tests pass, ask the user if questions arise.

- [x] 7. Phase 4 — Method renames (largest phase)
  - [x] 7.1 Rename methods in LaunchSystem class
    - Collect all snake_case methods in the LaunchSystem header
    - Generate PascalCase mappings (longest names first to prevent substring collisions)
    - Rename at declaration (.h), definition (.cpp), all call sites across all files, and test files
    - Build verify Debug|x64
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 10.1, 10.3_
  - [x] 7.2 Rename methods in WorldManager class
    - Collect all snake_case methods, generate PascalCase mappings
    - Rename at declaration, definition, all call sites, and test files
    - Build verify Debug|x64
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 10.1, 10.3_
  - [x] 7.3 Rename methods in UISystem class
    - Collect all snake_case methods, generate PascalCase mappings
    - Rename at declaration, definition, all call sites, and test files
    - Build verify Debug|x64
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 10.1, 10.3_
  - [x] 7.4 Rename methods in ExeWriter class
    - Collect all snake_case methods, generate PascalCase mappings
    - Rename at declaration, definition, all call sites, and test files
    - Build verify Debug|x64
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 10.1, 10.3_
  - [x] 7.5 Rename methods in AITitleService class
    - Collect all snake_case methods, generate PascalCase mappings
    - Rename at declaration, definition, all call sites, and test files
    - Build verify Debug|x64
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 10.1, 10.3_
  - [x] 7.6 Rename methods in remaining classes (batch 1 of 2)
    - Process approximately half of the remaining classes with snake_case methods
    - For each class: rename at declaration, definition, all call sites, test files
    - Build verify Debug|x64 after each class
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 10.1, 10.3_
  - [x] 7.7 Rename methods in remaining classes (batch 2 of 2)
    - Process the second half of remaining classes with snake_case methods
    - For each class: rename at declaration, definition, all call sites, test files
    - Build verify Debug|x64 after each class
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 10.1, 10.3_
  - [x] 7.8 Build Release|x64 and run full integration test suite
    - Build Release|x64 — confirm zero errors, zero new warnings
    - Run 64-seed integration test suite
    - Compare stdout/stderr output byte-for-byte against Phase 0 baseline
    - _Requirements: 7.1, 7.2, 8.2, 9.1_

- [x] 8. Checkpoint — Verify method renames preserve behavior
  - Ensure all tests pass, ask the user if questions arise.

- [x] 9. Phase 5 — Member variable renames
  - [x] 9.1 Rename member variables in core classes (batch 1)
    - For each class: identify all `m_snake_case` members in the header
    - Convert to `m_camelCase` at declaration and all usages (method bodies, constructor initializer lists, friend accesses)
    - Skip members already conforming to m_camelCase
    - Build verify Debug|x64 after each class
    - _Requirements: 3.1, 3.2, 3.3, 3.5, 10.1_
  - [x] 9.2 Rename member variables in remaining classes (batch 2)
    - Continue processing remaining classes with m_snake_case members
    - Convert to m_camelCase at declaration and all usages
    - Build verify Debug|x64 after each class
    - _Requirements: 3.1, 3.2, 3.3, 3.5, 10.1_
  - [x] 9.3 Build verify Release|x64 after all member renames
    - Build Release|x64 — confirm zero errors, zero new warnings
    - _Requirements: 7.1, 7.2_

- [x] 10. Phase 6 — Struct POD field renames
  - [x] 10.1 Rename fields in PlaystyleTermThreshold and GameplayStats
    - Rename all snake_case POD fields to camelCase
    - Update all member access expressions (`.field` and `->field`), designated initializers, aggregate initializations
    - Do NOT modify JSON key strings that happen to match field names
    - Build verify Debug|x64
    - _Requirements: 2.1, 2.2, 8.3, 10.1_
  - [x] 10.2 Rename fields in ProgressBarState, MorphAnimationState, and other POD structs
    - Rename all snake_case POD fields to camelCase
    - Update all member access expressions, designated initializers, aggregate initializations
    - Do NOT modify JSON key strings or string literals
    - Build verify Debug|x64
    - _Requirements: 2.1, 2.2, 2.4, 8.3, 10.1_
  - [x] 10.3 Build verify Release|x64 after all POD field renames
    - Build Release|x64 — confirm zero errors, zero new warnings
    - _Requirements: 7.1, 7.2_

- [x] 11. Checkpoint — Verify struct field renames preserve behavior
  - Ensure all tests pass, ask the user if questions arise.

- [x] 12. Phase 7 — Local variable and parameter renames
  - [x] 12.1 Rename locals and parameters in src/ files (batch 1)
    - Process approximately one-third of source files in src/
    - For each file: identify all snake_case locals and parameters, convert to camelCase
    - Preserve shadowing relationships; skip conflicts per Requirement 4.5
    - Do NOT modify string literals or preprocessor-stringified macro arguments
    - Build verify Debug|x64 (can batch multiple files per build check)
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_
  - [x] 12.2 Rename locals and parameters in src/ files (batch 2)
    - Process the second third of source files in src/
    - Same rules: camelCase conversion, skip conflicts, preserve string literals
    - Build verify Debug|x64
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_
  - [x] 12.3 Rename locals and parameters in src/ files (batch 3)
    - Process the final third of source files in src/
    - Same rules: camelCase conversion, skip conflicts, preserve string literals
    - Build verify Debug|x64
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_
  - [x] 12.4 Rename locals and parameters in include/ header files
    - Process all header files with inline function bodies or template definitions
    - Convert snake_case locals and parameters to camelCase
    - Build verify Debug|x64
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_
  - [x] 12.5 Rename locals and parameters in tests/ files
    - Process all 43 test .cpp files
    - Convert snake_case locals and parameters to camelCase
    - Build verify Debug|x64
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_
  - [x] 12.6 Build Release|x64 and run full integration test suite
    - Build Release|x64 — confirm zero errors, zero new warnings
    - Run 64-seed integration test suite
    - Compare output byte-for-byte against Phase 0 baseline
    - _Requirements: 7.1, 7.2, 8.2, 9.1_

- [x] 13. Checkpoint — Verify local/param renames preserve behavior
  - Ensure all tests pass, ask the user if questions arise.

- [x] 14. Phase 8 — Constants audit
  - [x] 14.1 Audit constants and defines for UPPER_SNAKE_CASE compliance
    - Scan all `#define` macros and `constexpr` constant variables
    - Identify any that do NOT use UPPER_SNAKE_CASE
    - Skip identifiers that are already compliant (expected: most/all are compliant)
    - If violations found: rename to UPPER_SNAKE_CASE at definition and all usage sites
    - Do NOT rename `constexpr` functions, enum values, or `const`-qualified local variables
    - Build verify Debug|x64
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 7.1_

- [x] 15. Phase 9 — Final verification and integration tests
  - [x] 15.1 Clean rebuild in both configurations
    - Perform a clean (non-incremental) build in Debug|x64
    - Perform a clean (non-incremental) build in Release|x64
    - Confirm zero errors and zero new warnings in both
    - _Requirements: 7.1, 7.2_
  - [x] 15.2 Run full 64-seed integration test suite
    - Execute all 64 seeded integration test runs
    - Compare stdout/stderr byte-for-byte against Phase 0 baseline
    - Confirm all 64 runs pass identically
    - _Requirements: 8.1, 8.2, 9.1, 9.4_
  - [x] 15.3 Generate final test report and GIF
    - Generate Markdown report with pass/fail status and screenshots for each run
    - Record animated GIF (minimum 3 seconds) from seed 1 test run
    - Compare GIF visually against Phase 0 baseline GIF
    - _Requirements: 9.2, 9.3, 9.5_

- [x] 16. Final checkpoint — All phases complete
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Each phase targets a single identifier category and produces a compilable intermediate state
- Build verification (Debug|x64) is performed after every rename batch within a phase
- Release|x64 builds are verified at the end of each phase
- Full 64-seed integration tests run at major phase boundaries (after methods, after locals, and at final)
- JSON key strings and string literals are NEVER modified regardless of content
- External API identifiers (SDL_*, IMG_*, picojson::*) are excluded from all renames
- Vendor/third-party directories are excluded from all renames
- Renames are applied longest-first within each batch to prevent substring collisions
- Word-boundary matching prevents partial identifier matches
- If a rename conflict is detected, it is skipped and logged for manual review

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["1.2"] },
    { "id": 2, "tasks": ["3.1"] },
    { "id": 3, "tasks": ["3.2"] },
    { "id": 4, "tasks": ["4.1", "4.2", "4.3"] },
    { "id": 5, "tasks": ["4.4", "4.5", "4.6"] },
    { "id": 6, "tasks": ["4.7"] },
    { "id": 7, "tasks": ["4.8"] },
    { "id": 8, "tasks": ["5.1"] },
    { "id": 9, "tasks": ["5.2"] },
    { "id": 10, "tasks": ["7.1", "7.2", "7.3"] },
    { "id": 11, "tasks": ["7.4", "7.5"] },
    { "id": 12, "tasks": ["7.6"] },
    { "id": 13, "tasks": ["7.7"] },
    { "id": 14, "tasks": ["7.8"] },
    { "id": 15, "tasks": ["9.1"] },
    { "id": 16, "tasks": ["9.2"] },
    { "id": 17, "tasks": ["9.3"] },
    { "id": 18, "tasks": ["10.1"] },
    { "id": 19, "tasks": ["10.2"] },
    { "id": 20, "tasks": ["10.3"] },
    { "id": 21, "tasks": ["12.1", "12.4"] },
    { "id": 22, "tasks": ["12.2", "12.5"] },
    { "id": 23, "tasks": ["12.3"] },
    { "id": 24, "tasks": ["12.6"] },
    { "id": 25, "tasks": ["14.1"] },
    { "id": 26, "tasks": ["15.1"] },
    { "id": 27, "tasks": ["15.2"] },
    { "id": 28, "tasks": ["15.3"] }
  ]
}
```
