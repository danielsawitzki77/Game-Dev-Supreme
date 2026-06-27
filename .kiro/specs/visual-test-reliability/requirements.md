# Requirements Document

## Introduction

This feature hardens the visual test infrastructure across three repositories (Zeitgeist-Evolved, SDL_VisualTest, Game-Dev-Supreme) to eliminate four recurring systemic failure modes: stale code built into the test executable, old test output not cleaned between runs, broken relative paths in GitHub-posted reports, and stale GIFs uploaded as fresh recordings. The solution introduces staleness detection guards, automatic output cleanup, a GitHub-compatible report output mode, build provenance files, and steering doc updates that enforce provenance verification before uploading.

## Glossary

- **Build_Script**: The batch file (`run_diverse_tests.bat` or `build_and_record.bat`) responsible for compiling the test executable from source and executing test runs
- **Test_Output_Directory**: The folder `test_output/diverse_runs/` containing per-seed run subdirectories with screenshots, GIFs, and reports
- **Staleness_Guard**: A pre-build check that compares the local branch HEAD against the remote tracking branch and warns when the local branch is behind
- **Build_Info_File**: A provenance file (`build_info.txt`) written into the test output directory after each run, recording branch, commit, timestamp, and run parameters
- **Report_Generator**: The `generate_report.exe` tool that scans test output directories and produces Markdown reports with embedded images
- **GitHub_Output_Mode**: A report generation mode (`--mode github`) that produces absolute GitHub-hosted URLs instead of relative file paths, making reports renderable when pasted into issue comments
- **Upload_Script**: The `upload_gif.bat` tool that uploads GIF files to a GitHub release asset and posts them as inline-rendered comments
- **Steering_Doc**: The `github-issue-workflow.md` file in Game-Dev-Supreme that instructs Kiro on autonomous workflow behavior
- **Remote_Main**: The `origin/main` branch as fetched from the remote repository

## Requirements

### Requirement 1: Staleness Detection in Build Scripts

**User Story:** As a developer, I want build scripts to detect when local code is behind remote main, so that test runs always exercise the latest logic rather than stale code.

#### Acceptance Criteria

1. WHEN the Build_Script is invoked, THE Staleness_Guard SHALL run `git fetch origin` with a timeout of 30 seconds and compare the local HEAD commit against Remote_Main
2. WHEN the local branch HEAD is behind Remote_Main by one or more commits, THE Staleness_Guard SHALL print a warning message containing the text "WARNING: LOCAL BRANCH IS BEHIND REMOTE" and the number of commits behind
3. WHEN the local branch HEAD is behind Remote_Main, THE Staleness_Guard SHALL set the exit code to 0 and continue the build (warning only, not blocking)
4. WHEN the local branch HEAD is equal to or ahead of Remote_Main, THE Staleness_Guard SHALL print "Branch is up to date with remote", set the exit code to 0, and proceed without warning
5. IF `git fetch origin` fails for any reason (network unavailability, authentication error, invalid remote, or timeout), THEN THE Staleness_Guard SHALL print "WARNING: Could not reach remote — staleness check skipped" and continue the build with exit code 0

### Requirement 2: Test Output Cleanup Before Each Run

**User Story:** As a developer, I want old test output to be automatically removed before each new test run, so that stale screenshots and GIFs from previous runs cannot contaminate the current results.

#### Acceptance Criteria

1. WHEN the Build_Script begins a new test run, THE Build_Script SHALL recursively delete all files and subdirectories within the Test_Output_Directory for the target seed before the test executable is launched
2. IF the Test_Output_Directory does not exist at the start of cleanup, THEN THE Build_Script SHALL create it as an empty directory and proceed without error
3. WHEN the deletion of the Test_Output_Directory contents completes successfully, THE Build_Script SHALL log the message "Cleaned test output directory: <path>" to standard output
4. IF the deletion of the Test_Output_Directory contents fails due to a locked file or insufficient permissions, THEN THE Build_Script SHALL log an error message indicating the path that could not be deleted and SHALL exit with a non-zero exit code without launching the test executable

### Requirement 3: Build Provenance File Generation

**User Story:** As a developer, I want each test run to produce a provenance file recording exactly what code was built and when, so that staleness can be detected before uploading results.

#### Acceptance Criteria

1. WHEN the test executable completes a run (whether the run succeeds or fails), THE Build_Script SHALL write a file named `build_info.txt` into the run's output directory, overwriting any existing file of the same name
2. THE Build_Info_File SHALL contain the following fields, each on its own line in `key=value` format: `branch`, `commit`, `timestamp`, `seed`, `runs`, `flow`
3. THE Build_Info_File SHALL use ISO 8601 format in UTC with seconds precision for the `timestamp` field (format: `YYYY-MM-DDTHH:MM:SSZ`)
4. THE Build_Info_File SHALL use the short (7-character) git commit hash for the `commit` field
5. IF the git branch or commit cannot be determined (e.g., git not available or not a git repository), THEN THE Build_Script SHALL write `branch=unknown` and `commit=unknown` to the Build_Info_File and still populate all remaining fields
6. IF the Build_Script fails to write the Build_Info_File (e.g., directory does not exist or permission denied), THEN THE Build_Script SHALL exit with a non-zero exit code and print an error message indicating the file path that could not be written

### Requirement 4: GitHub-Compatible Report Output Mode

**User Story:** As a developer, I want the report generator to produce reports with absolute URLs that render correctly when pasted into GitHub issue comments, so that screenshots and links are visible without a local file server.

#### Acceptance Criteria

1. WHEN the Report_Generator is invoked with `--mode github --repo <owner/repo> --branch <branch> --root <relative_path>`, THE Report_Generator SHALL produce image references as absolute GitHub raw content URLs in the format `https://raw.githubusercontent.com/<owner>/<repo>/<branch>/<root>/<image_path>`, using Markdown image syntax `![<alt_text>](<url>)`
2. WHEN the Report_Generator is invoked with `--mode github`, THE Report_Generator SHALL produce inter-report links as absolute GitHub blob URLs in the format `https://github.com/<owner>/<repo>/blob/<branch>/<root>/<report_path>`, using Markdown link syntax `[<link_text>](<url>)`
3. WHEN the Report_Generator is invoked without `--mode`, THE Report_Generator SHALL produce all image references and inter-report links as relative paths from the report file to the referenced resource
4. IF the `--mode github` flag is provided without the required `--repo`, `--branch`, or `--root` arguments, THEN THE Report_Generator SHALL print an error message to stderr indicating which argument is missing and exit with code 1
5. WHEN the Report_Generator is invoked with `--mode github` and any path segment in `<image_path>` or `<report_path>` contains characters outside unreserved URI characters (A-Z, a-z, 0-9, `-`, `_`, `.`, `~`), THE Report_Generator SHALL percent-encode those characters per RFC 3986 in the generated URLs

### Requirement 5: Provenance Verification Before GIF Upload

**User Story:** As a developer using Kiro's autonomous workflow, I want the steering doc to require build provenance verification before uploading GIFs, so that stale recordings from previous runs are never posted as fresh evidence.

#### Acceptance Criteria

1. THE Steering_Doc SHALL instruct Kiro to read the Build_Info_File from the test output directory before uploading any GIF
2. THE Steering_Doc SHALL instruct Kiro to verify that the `commit` field in the Build_Info_File matches the full 40-character HEAD commit SHA of the currently checked-out branch
3. IF the `commit` field does not match the current HEAD commit SHA, THEN THE Steering_Doc SHALL instruct Kiro to abort the upload and post a comment on the issue stating "GIF upload aborted: build_info.txt commit (<recorded>) does not match current HEAD (<actual>). Re-run tests before uploading."
4. IF the Build_Info_File does not exist in the test output directory, THEN THE Steering_Doc SHALL instruct Kiro to abort the upload and post a comment on the issue stating "GIF upload aborted: build_info.txt not found. Run tests before uploading."
5. IF the `timestamp` field in the Build_Info_File is older than 60 minutes relative to the current system time, THEN THE Steering_Doc SHALL instruct Kiro to post a comment on the issue containing "WARNING: Test results are over 60 minutes old" but still allow the upload to proceed
6. IF the Build_Info_File exists but does not contain both a `commit` field and a `timestamp` field, THEN THE Steering_Doc SHALL instruct Kiro to abort the upload and post a comment on the issue stating "GIF upload aborted: build_info.txt is malformed (missing required fields). Re-run tests before uploading."

### Requirement 6: Staleness Guard in build_and_record.bat

**User Story:** As a developer, I want the SDL_VisualTest build_and_record script to also detect staleness against remote, so that GIFs recorded via this tool reflect up-to-date code.

#### Acceptance Criteria

1. WHEN `build_and_record.bat` is invoked, THE Staleness_Guard SHALL run `git fetch origin` in the target project directory (the `<project_path>` argument) before the build step begins
2. IF `git fetch origin` fails in the target project directory, THEN THE Staleness_Guard SHALL print a warning message indicating that the remote could not be reached and continue with the build without aborting
3. WHEN the target project's local HEAD is behind `origin/main` by 1 or more commits (determined by counting commits in `origin/main` that are not in `HEAD`), THE Staleness_Guard SHALL print "WARNING: Target project is behind remote main by N commit(s). GIF may reflect stale code." where N is the exact commit count
4. WHEN the SDL_VisualTest repository's local HEAD is behind its own `origin/main` by 1 or more commits, THE Staleness_Guard SHALL print "WARNING: SDL_VisualTest is behind remote main by N commit(s). Test harness may be stale."
5. WHEN the test executable exits with code 0 and a GIF file exists in the output directory, THE build_and_record.bat SHALL write a Build_Info_File (named `build_info.txt`) into the GIF output directory containing: the target project branch name, the target project commit hash, the SDL_VisualTest commit hash, the staleness status of each repository (commits behind or "up-to-date"), and the timestamp of the recording

### Requirement 7: Generic Level Gameplay Test Flow

**User Story:** As a developer, I want the visual test system to exercise any campaign level generically (including gadget placement and simulation), so that I don't need to write a bespoke test flow function for each individual level.

#### Acceptance Criteria

1. WHEN the `--flow` argument specifies a campaign category (e.g., `challenges`, `tutorials`, `examples`), THE test flow SHALL navigate to that category folder and select a level based on the seed value, then attempt to interact with the level generically
2. THE generic gameplay flow SHALL attempt gadget placement by: cycling through available item pool entries using Tab and arrow keys, placing items at grid positions derived from the seed, and rotating placed gadgets a seed-determined number of times
3. WHEN the generic gameplay flow completes gadget placement, THE flow SHALL start the simulation using the P key and wait for an outcome (win/lose/timeout) for at least 600 frames (~10 seconds)
4. THE generic gameplay flow SHALL NOT require hardcoded grid coordinates, specific gadget names, or level-specific knowledge — all interactions SHALL use relative navigation (Tab between panels, arrow keys within panels, Enter to select/place)
5. WHEN a named flow is requested for a specific level (e.g., `--flow challenge3`), THE system SHALL use the generic campaign flow with a seed that selects that level's position in the list, rather than requiring a separate hardcoded flow function
6. THE `BuildFlowChallenge3` function (and any similar bespoke per-level flow functions) SHALL be removed and replaced by the generic mechanism described above

### Requirement 8: Upload Script Provenance Check

**User Story:** As a developer, I want the upload_gif.bat script to refuse uploading when provenance cannot be confirmed, so that stale files are never accidentally posted to GitHub issues.

#### Acceptance Criteria

1. WHEN `upload_gif.bat` is invoked, THE Upload_Script SHALL search for a Build_Info_File by starting in the GIF file's parent directory and walking up the directory tree one level at a time until either a `build_info.txt` file is found or the filesystem root is reached
2. WHEN a Build_Info_File is found, THE Upload_Script SHALL extract the `commit` field value and validate that it is a hexadecimal string of exactly 7 or 40 characters before proceeding with comparison
3. WHEN the `commit` field is valid, THE Upload_Script SHALL compare it against the output of `git rev-parse HEAD` (or its first 7 characters if the manifest contains a 7-character short hash) executed in the GIF file's parent directory
4. WHEN the `commit` field does not match the current HEAD, THE Upload_Script SHALL print "ERROR: GIF was generated from commit <recorded> but current HEAD is <actual>. Aborting upload." and exit with code 1
5. IF the Build_Info_File exists but does not contain a `commit` field or the `commit` value is not a valid hexadecimal string of 7 or 40 characters, THEN THE Upload_Script SHALL print an error message indicating the manifest is malformed and exit with code 1
6. IF `git rev-parse HEAD` fails in the GIF file's directory, THEN THE Upload_Script SHALL print an error message indicating that the current HEAD cannot be determined and exit with code 1
7. WHEN no Build_Info_File is found after traversing to the filesystem root, THE Upload_Script SHALL print "WARNING: No build_info.txt found alongside GIF. Cannot verify freshness." and proceed with the upload for backward compatibility
