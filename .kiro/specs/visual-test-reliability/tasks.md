# Implementation Plan: Visual Test Reliability

## Overview

This plan implements reliability hardening across three repositories to eliminate four systemic failure modes in the visual test infrastructure: stale code, old test output contamination, broken report URLs, and stale GIF uploads. Each task targets a specific script or tool, grouped by repository.

## Tasks

- [x] 1. Zeitgeist-Evolved: Staleness guard and cleanup in run_diverse_tests.bat
  - [x] 1.1 Add staleness guard to run_diverse_tests.bat
    - Insert a `:staleness_guard` section at the start of the script before the build step
    - Run `git fetch origin` and compare HEAD against `origin/main` using `git rev-list --count HEAD..origin/main`
    - Print "WARNING: LOCAL BRANCH IS BEHIND REMOTE by N commit(s)" when behind, or "Branch is up to date with remote" when not
    - On any git failure (network, auth, timeout): print "WARNING: Could not reach remote — staleness check skipped" and continue
    - Always exit with code 0 (never block the build)
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

  - [x] 1.2 Add test output cleanup to run_diverse_tests.bat
    - Insert a `:cleanup_output` section before the test executable launch
    - Use `rmdir /s /q` to recursively delete the target seed's output directory
    - If directory doesn't exist, create it with `mkdir` and proceed without error
    - Log "Cleaned test output directory: <path>" on success
    - If deletion fails (locked file), print error with the path and `exit /b 1`
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

  - [x] 1.3 Add build_info.txt writer to run_diverse_tests.bat
    - Insert a `:write_build_info` section after the test executable completes (regardless of success/failure)
    - Write `build_info.txt` to the run's output directory in `key=value` format
    - Fields: `branch`, `commit` (7-char short SHA), `timestamp` (ISO 8601 UTC), `seed`, `runs`, `flow`
    - Use PowerShell one-liner for UTC timestamp: `powershell -command "Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ' -AsUTC"`
    - Fall back to `branch=unknown` and `commit=unknown` if git is unavailable
    - Exit with non-zero code if the file cannot be written
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

  - [x] 1.4 Write property test for build_info.txt round-trip
    - **Property 2: build_info.txt round-trip preserves all fields**
    - **Validates: Requirements 3.2, 3.3, 3.4, 6.5**

  - [x] 1.5 Write property test for staleness warning message
    - **Property 1: Staleness warning includes correct commit count**
    - **Validates: Requirements 1.2, 6.3, 6.4**

- [x] 2. Zeitgeist-Evolved: Generic level gameplay flow
  - [x] 2.1 Create BuildGenericGameplayFlow function in test_integration_diverse.cpp
    - Create a new function `BuildGenericGameplayFlow(int seed, int folder_index, int level_index)` that:
    - Navigates to the specified campaign folder (0=Examples, 1=Tutorials, 2=Challenges) using Right key presses
    - Selects the level at `level_index` position using Down key presses + Enter
    - Performs generic gadget placement: Tab to item panel, navigate down by `seed % 5` steps, Tab back to grid, move cursor with WASD by seed-derived offsets, Enter to place, repeat 2-4 times based on seed
    - Rotates the last-placed gadget `seed % 4` times using R key
    - Starts simulation with P key
    - Waits 600+ frames for outcome (win/lose/timeout)
    - Captures screenshots at key checkpoints
    - All interactions use relative navigation only — no hardcoded pixel coordinates or level-specific knowledge
    - _Requirements: 7.1, 7.2, 7.3, 7.4_

  - [x] 2.2 Replace bespoke per-level flows with generic aliases
    - Remove the `BuildFlowChallenge3` function entirely
    - Remove `{"challenge3", BuildFlowChallenge3}` and `{"challenge-3", BuildFlowChallenge3}` entries from `g_namedFlows[]`
    - Add new named flow aliases that map to `BuildGenericGameplayFlow` with preset folder/level indices:
      - `challenge3` / `challenge-3` → folder=2, level=2
      - `tutorial1` → folder=1, level=0
      - etc. (extensible without new code)
    - _Requirements: 7.5, 7.6_

  - [x] 2.3 Update existing campaign flows (A, B, C) to include gadget placement
    - Modify `BuildFlowA`, `BuildFlowB`, `BuildFlowC` to include the generic gadget placement phase after level selection
    - This ensures the 128-seed diverse runs actually interact with levels rather than just watching
    - The placement uses the same seed-driven relative navigation pattern as `BuildGenericGameplayFlow`
    - _Requirements: 7.1, 7.2, 7.4_

- [x] 3. Checkpoint - Ensure Zeitgeist-Evolved changes work
  - Ensure all tests pass, ask the user if questions arise.

- [x] 4. SDL_VisualTest: Report generator GitHub mode
  - [x] 3.1 Add CLI argument parsing for --mode github in generate_report.cpp
    - Parse new arguments: `--mode github`, `--repo <owner/repo>`, `--branch <branch>`, `--root <relative_path>`
    - Store in a `GitHubModeConfig` struct (enabled, repo, branch, root)
    - If `--mode github` is given without `--repo`, `--branch`, or `--root`, print error to stderr and exit with code 1
    - Existing behavior (no `--mode` flag) must remain unchanged — all paths stay relative
    - _Requirements: 4.1, 4.3, 4.4_

  - [x] 3.2 Implement percent-encoding utility function in generate_report.cpp
    - Create a `percent_encode()` function that encodes characters outside `A-Za-z0-9-_.~/` as `%XX` per RFC 3986
    - Forward slashes (`/`) in paths are preserved (not encoded)
    - _Requirements: 4.5_

  - [x] 3.3 Implement GitHub URL generation for images and links in generate_report.cpp
    - Create `make_image_url()` using `https://raw.githubusercontent.com/<owner>/<repo>/<branch>/<root>/<image_path>`
    - Create `make_link_url()` using `https://github.com/<owner>/<repo>/blob/<branch>/<root>/<report_path>`
    - Apply percent-encoding to path segments
    - When `--mode` is not set, return the relative path unchanged (existing behavior)
    - Wire both functions into the existing report output logic
    - _Requirements: 4.1, 4.2, 4.3, 4.5_

  - [x] 3.4 Write property test for GitHub mode URL generation
    - **Property 3: GitHub mode produces correct absolute URLs for images**
    - **Validates: Requirements 4.1, 4.2**

  - [x] 3.5 Write property test for default mode relative paths
    - **Property 4: Default mode produces only relative paths**
    - **Validates: Requirements 4.3**

  - [x] 3.6 Write property test for percent-encoding round-trip
    - **Property 5: Percent-encoding of non-URI-safe characters**
    - **Validates: Requirements 4.5**

- [x] 5. SDL_VisualTest: Staleness guard in build_and_record.bat
  - [x] 4.1 Add dual staleness check to build_and_record.bat
    - Before the build step, `cd` into the target project directory (`<project_path>` argument) and run `git fetch origin`
    - Count commits behind with `git rev-list --count HEAD..origin/main`
    - Print "WARNING: Target project is behind remote main by N commit(s). GIF may reflect stale code." if behind
    - Then check SDL_VisualTest's own repo for staleness: print "WARNING: SDL_VisualTest is behind remote main by N commit(s). Test harness may be stale." if behind
    - On any fetch failure, print a warning and continue (never abort)
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

  - [x] 4.2 Add build_info.txt writer to build_and_record.bat
    - After the test executable exits with code 0 and a GIF exists, write `build_info.txt` into the GIF output directory
    - Include fields: `branch`, `commit` (target project), `sdl_visualtest_commit`, `target_staleness`, `sdl_visualtest_staleness`, `timestamp`
    - Staleness fields use "up-to-date" or "N commits behind" format
    - _Requirements: 6.5_

- [x] 6. SDL_VisualTest: Provenance check in upload_gif.bat
  - [x] 5.1 Implement directory traversal to find build_info.txt in upload_gif.bat
    - Start at the GIF file's parent directory
    - Walk up the directory tree one level at a time until `build_info.txt` is found or the filesystem root is reached
    - If not found after reaching root: print "WARNING: No build_info.txt found alongside GIF. Cannot verify freshness." and proceed with upload (backward compatibility)
    - _Requirements: 7.1, 7.7_

  - [x] 5.2 Implement commit field validation and comparison in upload_gif.bat
    - Extract the `commit` field from `build_info.txt` using `findstr /b "commit="`
    - Validate it is a hexadecimal string of exactly 7 or 40 characters
    - Compare against `git rev-parse HEAD` (use short hash for 7-char, full for 40-char)
    - If mismatch: print "ERROR: GIF was generated from commit <recorded> but current HEAD is <actual>. Aborting upload." and exit with code 1
    - If commit field missing or invalid hex: print "manifest is malformed" error and exit with code 1
    - If `git rev-parse HEAD` fails: print error and exit with code 1
    - _Requirements: 7.2, 7.3, 7.4, 7.5, 7.6_

  - [x] 5.3 Write property test for directory traversal correctness
    - **Property 6: Directory traversal finds nearest ancestor build_info.txt**
    - **Validates: Requirements 7.1**

  - [x] 5.4 Write property test for commit hash validation and comparison
    - **Property 7: Commit hash validation and comparison**
    - **Validates: Requirements 7.2, 7.3**

- [x] 7. Checkpoint - Ensure SDL_VisualTest changes work
  - Ensure all tests pass, ask the user if questions arise.

- [x] 8. Game-Dev-Supreme: Steering doc provenance verification
  - [x] 8.1 Add provenance verification section to github-issue-workflow.md
    - Add a new section under "Visual Testing (SDL Projects)" titled "Build Provenance Verification"
    - Instruct Kiro to read `build_info.txt` from the test output directory before uploading any GIF
    - Instruct Kiro to verify `commit` field matches the full 40-character HEAD SHA of the currently checked-out branch
    - If mismatch: abort upload and post comment "GIF upload aborted: build_info.txt commit (<recorded>) does not match current HEAD (<actual>). Re-run tests before uploading."
    - If `build_info.txt` not found: abort upload and post "GIF upload aborted: build_info.txt not found. Run tests before uploading."
    - If `build_info.txt` exists but missing `commit` or `timestamp` fields: abort and post "GIF upload aborted: build_info.txt is malformed (missing required fields). Re-run tests before uploading."
    - If `timestamp` is older than 60 minutes: post "WARNING: Test results are over 60 minutes old" but allow upload to proceed
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

- [x] 9. Cross-repo: Copy spec to each repo's branch
  - [x] 9.1 Copy spec files to Zeitgeist-Evolved branch
    - Copy the `.kiro/specs/visual-test-reliability/` directory (requirements.md, design.md, tasks.md, .config.kiro) into the Zeitgeist-Evolved feature branch
    - This ensures the spec is versioned alongside the implementation changes
    - _Requirements: 1.1, 2.1, 3.1_

  - [x] 9.2 Copy spec files to SDL_VisualTest branch
    - Copy the `.kiro/specs/visual-test-reliability/` directory into the SDL_VisualTest feature branch
    - _Requirements: 4.1, 6.1, 7.1_

  - [x] 9.3 Copy spec files to Game-Dev-Supreme branch
    - Copy the `.kiro/specs/visual-test-reliability/` directory into the Game-Dev-Supreme feature branch
    - _Requirements: 5.1_

- [x] 10. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties using fast-check (TypeScript)
- The batch script tasks (1.x, 4.x, 5.x) use Windows batch scripting with PowerShell one-liners where needed
- The report generator task (3.x) uses C++
- The steering doc task (7.1) is a Markdown documentation change
- Spec copying tasks (8.x) ensure all three repos have the spec alongside their implementation

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "2.1", "4.1", "8.1"] },
    { "id": 1, "tasks": ["1.2", "2.2", "4.2", "5.1"] },
    { "id": 2, "tasks": ["1.3", "2.3", "4.3", "5.2", "6.1"] },
    { "id": 3, "tasks": ["1.4", "1.5", "4.4", "4.5", "4.6", "6.2"] },
    { "id": 4, "tasks": ["6.3", "6.4"] },
    { "id": 5, "tasks": ["9.1", "9.2", "9.3"] }
  ]
}
```
