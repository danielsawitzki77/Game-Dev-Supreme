# Requirements Document

## Introduction

This specification defines the requirements for a comprehensive code style refactoring of the TerrorForm project. The project currently has 260+ methods using snake_case naming and hundreds of struct fields violating the workspace code-style conventions. This refactoring brings all identifiers across 70+ source files into compliance with the code-style.md naming rules without altering runtime behavior.

## Glossary

- **Refactor_Tool**: The automated or manual rename mechanism (IDE refactoring, find-and-replace scripts, or manual edits) used to perform identifier renames across the TerrorForm codebase
- **Build_System**: The MSVC Visual Studio solution and project files that compile TerrorForm into a working executable
- **Integration_Test_Suite**: The SDL_VisualTest-based integration test harness that runs 64+ seeded test executions and produces a Markdown report with screenshots
- **GIF_Recorder**: The SDL_VisualTest_GifRecorder component that captures animated GIF recordings of test runs for visual verification
- **Source_File**: Any `.cpp` or `.h` file within the TerrorForm project that contains C++ code
- **Identifier**: A named entity in source code including method names, struct fields, member variables, local variables, parameters, classes, enums, enum values, constants, and file names
- **PascalCase**: Naming convention where each word starts with an uppercase letter with no separators (e.g., `BeginLaunch`, `HandleEvent`)
- **camelCase**: Naming convention where the first word is lowercase and subsequent words start with uppercase (e.g., `deltaTime`, `targetWidth`)
- **m_camelCase**: Member variable convention using `m_` prefix followed by camelCase (e.g., `m_cacheValid`, `m_pivotX`)
- **snake_case**: Naming convention using lowercase words separated by underscores (e.g., `is_launch_eligible`, `begin_launch`)
- **UPPER_SNAKE_CASE**: Naming convention using uppercase words separated by underscores for constants (e.g., `MAX_LIGHTS`, `DEFAULT_SEED`)

## Requirements

### Requirement 1: Rename Methods to PascalCase

**User Story:** As a developer, I want all TerrorForm methods renamed from snake_case to PascalCase, so that the codebase complies with the workspace code-style guide.

#### Acceptance Criteria

1. WHEN a public method in TerrorForm uses snake_case naming (identifiers containing at least one underscore separating lowercase words), THE Refactor_Tool SHALL rename the method to PascalCase at the declaration, definition, and all call sites within the TerrorForm codebase
2. WHEN a private method in TerrorForm uses snake_case naming, THE Refactor_Tool SHALL rename the method to PascalCase at the declaration, definition, and all internal call sites within the TerrorForm codebase
3. THE Refactor_Tool SHALL rename all snake_case methods listed in the project's method inventory to their PascalCase equivalents (e.g., `is_launch_eligible` becomes `IsLaunchEligible`, `begin_launch` becomes `BeginLaunch`, `handle_event` becomes `HandleEvent`), where the total count of renamed methods matches the inventory exactly
4. WHEN a method name appears in a code comment (inline or block), THE Refactor_Tool SHALL update the comment to reflect the new PascalCase name
5. WHEN all renames are applied, THE Refactor_Tool SHALL produce a build that compiles with zero errors and zero new warnings attributable to the rename
6. IF a snake_case method's PascalCase equivalent conflicts with an existing identifier in the same scope, THEN THE Refactor_Tool SHALL report the conflict and skip that method without modifying it

### Requirement 2: Rename Struct POD Fields to camelCase

**User Story:** As a developer, I want all TerrorForm struct POD fields renamed from snake_case to camelCase, so that data structures follow the workspace naming conventions.

#### Acceptance Criteria

1. WHEN a struct POD field (a public data member of a struct that has no user-defined constructors, no virtual functions, and no private/protected non-static data members) uses snake_case naming, THE Refactor_Tool SHALL rename the field to camelCase by removing each underscore and capitalizing the immediately following letter (e.g., `my_field_name` becomes `myFieldName`, `http_url` becomes `httpUrl`) at the declaration and all usage sites within the TerrorForm project source tree
2. THE Refactor_Tool SHALL update all struct initializer lists, member access expressions, and designated initializers that reference the renamed field
3. IF a struct field rename causes a name collision with an existing identifier in the same struct scope, THEN THE Refactor_Tool SHALL report the collision to stderr indicating the file path, line number, original field name, and conflicting identifier name, and SHALL exit with a non-zero exit code without applying that rename
4. WHEN all renames for a translation unit are applied, THE Refactor_Tool SHALL produce output that compiles without errors using the same build configuration as before the rename

### Requirement 3: Rename Class Member Variables to m_camelCase

**User Story:** As a developer, I want all TerrorForm class member variables renamed to m_camelCase convention, so that member variables are visually distinct from local variables and parameters.

#### Acceptance Criteria

1. WHEN a class member variable uses snake_case naming without the `m_` prefix, THE Refactor_Tool SHALL rename it to m_camelCase at the declaration and all usage sites including constructor initializer lists, method bodies, and friend function accesses
2. WHEN a class member variable uses snake_case naming with an existing `m_` prefix but incorrect casing, THE Refactor_Tool SHALL correct the casing to m_camelCase at the declaration and all usage sites
3. THE Refactor_Tool SHALL skip any class member variable that already conforms to the m_camelCase convention
4. IF renaming a class member variable to m_camelCase would produce an identifier that conflicts with an existing identifier in the same class scope, THEN THE Refactor_Tool SHALL report the conflict and skip that variable without modifying it
5. WHEN all class member renames are applied, THE Build_System SHALL compile with zero errors confirming all references were updated consistently

### Requirement 4: Rename Local Variables and Parameters to camelCase

**User Story:** As a developer, I want all local variables and function parameters renamed from snake_case to camelCase, so that all identifiers within function bodies follow consistent naming.

#### Acceptance Criteria

1. WHEN a local variable uses snake_case naming, THE Refactor_Tool SHALL rename it to camelCase by removing each underscore and capitalizing the immediately following letter within its containing scope
2. WHEN a function parameter uses snake_case naming, THE Refactor_Tool SHALL rename it to camelCase at the declaration and all usages within the function body
3. THE Refactor_Tool SHALL preserve any shadowing relationships between local variables and outer-scope identifiers after renaming
4. THE Refactor_Tool SHALL NOT modify identifier names appearing inside string literals or preprocessor-stringified macro arguments
5. IF renaming a local variable or parameter to camelCase would produce a name collision with another identifier in the same scope, THEN THE Refactor_Tool SHALL report the conflict and skip that variable without modifying it

### Requirement 5: Rename Source Files to PascalCase

**User Story:** As a developer, I want all TerrorForm source files renamed to PascalCase convention, so that file names match the workspace code-style guide.

#### Acceptance Criteria

1. WHEN a `.cpp` or `.h` file within the TerrorForm project source tree (excluding vendor/ and third-party/ directories) uses snake_case or other non-PascalCase naming, THE Refactor_Tool SHALL rename the file to PascalCase by capitalizing the first letter of each underscore-separated segment and removing underscores (e.g., `launch_manager.cpp` becomes `LaunchManager.cpp`)
2. WHEN a file is renamed, THE Refactor_Tool SHALL update all `#include` directives across the entire TerrorForm project source tree that reference the old file name to use the new PascalCase name
3. WHEN a file is renamed, THE Refactor_Tool SHALL update the Visual Studio project file (`.vcxproj`) and filter file (`.vcxproj.filters`) to reference the new file name
4. IF renaming a file to PascalCase would produce a name that already exists in the same directory, THEN THE Refactor_Tool SHALL report the collision and skip that file rename
5. WHEN all file renames are applied, THE Build_System SHALL compile with zero errors confirming all include paths and project references are correct

### Requirement 6: Rename Enum Types and Values to PascalCase

**User Story:** As a developer, I want all enum types and enum values renamed to PascalCase without underscores, so that enumerations follow the code-style guide.

#### Acceptance Criteria

1. WHEN an enum type uses snake_case naming, THE Refactor_Tool SHALL rename it to PascalCase by capitalizing the first letter of each underscore-separated word and removing all underscores, at the declaration and all usage sites within the project source tree
2. WHEN an enum value uses snake_case or UPPER_SNAKE_CASE naming and is declared within an enum body, THE Refactor_Tool SHALL rename it to PascalCase by capitalizing the first letter of each underscore-separated word (lowercasing the remaining letters of each word) and removing all underscores
3. WHEN enum types or enum values are renamed, THE Refactor_Tool SHALL update all switch-case statements, comparisons, assignments, and function arguments that reference the renamed identifiers across all files in the project source tree
4. IF renaming an enum type or value to PascalCase would produce an identifier that already exists in the same scope, THEN THE Refactor_Tool SHALL report a naming collision error identifying both the source name and the conflicting target name, and SHALL skip that rename
5. THE Refactor_Tool SHALL NOT rename identifiers defined via preprocessor `#define` directives, even if they use UPPER_SNAKE_CASE naming

### Requirement 7: Preserve Build Integrity

**User Story:** As a developer, I want the TerrorForm project to compile without errors after each logical batch of renames, so that the refactoring does not introduce regressions.

#### Acceptance Criteria

1. WHEN a batch of renames is completed, THE Build_System SHALL compile the TerrorForm solution with zero errors using MSVC in both Debug and Release configurations for the x64 platform
2. WHEN a batch of renames is completed, THE Build_System SHALL produce zero new warnings that did not exist in the compilation output immediately prior to that rename batch
3. IF a rename introduces a compilation error, THEN THE Refactor_Tool SHALL identify and fix the incomplete reference, attempting no more than 3 automatic corrections per error before proceeding to the next batch
4. IF the Refactor_Tool fails to resolve a compilation error within 3 attempts, THEN THE Refactor_Tool SHALL halt processing, report the unresolved error with the affected file and symbol name, and not proceed to the next batch

### Requirement 8: Preserve Runtime Behavior

**User Story:** As a developer, I want the TerrorForm application to behave identically before and after the refactoring, so that no gameplay logic is altered.

#### Acceptance Criteria

1. THE Refactor_Tool SHALL perform only identifier renames with no changes to control flow, algorithms, data structures, or logic
2. WHEN the Integration_Test_Suite executes 64 seeded runs after the refactor, THE Integration_Test_Suite SHALL produce byte-identical stdout and stderr output compared to the pre-refactor baseline captured from the same 64 seeds
3. THE Refactor_Tool SHALL not modify any string literals, resource identifiers, serialized data field names, or preprocessor-stringified identifier values that are read at runtime (e.g., JSON keys, file paths, macro-generated strings)

### Requirement 9: Visual Verification via Test Report and GIF

**User Story:** As a developer, I want a visual test report with an animated GIF generated after the refactor, so that rendering correctness is visually confirmed.

#### Acceptance Criteria

1. WHEN the refactored code builds successfully, THE Integration_Test_Suite SHALL execute a minimum of 64 seeded integration test runs, each using a distinct deterministic seed value
2. WHEN integration tests complete, THE Integration_Test_Suite SHALL generate a single Markdown report containing the pass/fail status for each run with at least one embedded screenshot per run
3. WHEN integration tests complete, THE GIF_Recorder SHALL capture an animated GIF of at least 3 seconds duration from a test run selected by the first seed value used in the suite
4. THE Integration_Test_Suite SHALL report zero failures across all seeded runs to confirm rendering correctness
5. IF one or more integration test runs fail, THEN THE Integration_Test_Suite SHALL still generate the Markdown report documenting which runs failed, including the failing screenshot for each failed run

### Requirement 10: Consistent Cross-Cutting Renames

**User Story:** As a developer, I want every reference to a renamed identifier updated consistently across all 70+ source files, so that no stale references remain.

#### Acceptance Criteria

1. WHEN an identifier is renamed, THE Refactor_Tool SHALL update all code references (declarations, definitions, call sites, type annotations, template instantiations) to that identifier across every Source_File in the TerrorForm project
2. WHEN a renamed identifier is referenced via a macro expansion, THE Refactor_Tool SHALL update the macro definition or usage to reflect the new name
3. IF an identifier is referenced across translation unit boundaries (declared in a header, used in multiple `.cpp` files), THEN THE Refactor_Tool SHALL update the declaration and all usages atomically within the same rename batch
4. THE Refactor_Tool SHALL not leave any orphaned references that would cause linker errors (unresolved external symbols)
5. IF renaming an identifier would cause a name conflict in any of the target scopes, THEN THE Refactor_Tool SHALL detect the conflict before applying the rename and report it without modifying the source

### Requirement 11: Constants and Defines Remain UPPER_SNAKE_CASE

**User Story:** As a developer, I want constants and preprocessor defines to remain in UPPER_SNAKE_CASE convention, so that the refactoring does not over-correct already-compliant identifiers.

#### Acceptance Criteria

1. WHEN a `#define` macro or `constexpr` constant variable already uses UPPER_SNAKE_CASE, THE Refactor_Tool SHALL leave its name unchanged at the definition and all usage sites within the project
2. THE Refactor_Tool SHALL not rename any identifier that is already compliant with its category's naming convention as defined in the project's code-style rules
3. WHEN a `#define` macro or `constexpr` constant variable uses snake_case or any casing other than UPPER_SNAKE_CASE, THE Refactor_Tool SHALL rename it to UPPER_SNAKE_CASE at the definition and all usage sites within the same project
4. THE Refactor_Tool SHALL classify only `#define` macros and `constexpr`-qualified variable declarations as constants eligible for UPPER_SNAKE_CASE enforcement, excluding `constexpr` functions, enum values, and `const`-qualified local variables
