---
inclusion: auto
---

# SDL Visual Test — Multi-Repo Workflow

This steering doc defines how SDL_VisualTest changes are executed from the Game-Dev-Supreme multi-root workspace.

---

## Execution Context

All GitHub issues are worked on from the **Game-Dev-Supreme** multi-root workspace (`Game-Dev-Supreme.code-workspace`), which includes:

- Game-Dev-Supreme (orchestration, hooks, issue tracking)
- SDL_VisualTest (visual testing framework)
- Zeitgeist-Evolved (game project, primary consumer)
- Super-Civ-16, TerrorForm (additional game projects)
- Kiro-Tooling (automation scripts)
- SDL, SDL_image, SDL_ttf, picojson (dependencies)

Issues may be filed in Game-Dev-Supreme but target a different repo. Always deduce the correct target from the issue title/body.

---

## SDL_VisualTest Change Workflow

When an issue requests changes to **SDL_VisualTest**:

1. **Make primary changes** in `c:\Users\Daniel Sawitzki\Desktop\github\SDL_VisualTest`
2. **Deploy to consuming game projects** if the change affects their test setup, build scripts, or API usage. Affected projects typically need updates in:
   - Their `build_test_visual.bat` (if build/link flags change)
   - Their `tests/test_visual.cpp` (if API changes)
   - Their `.kiro/steering/visual-testing.md` (if workflow instructions change)
3. **Open the PR in SDL_VisualTest's repo** (the target project), not Game-Dev-Supreme
4. **If game projects need separate changes**, create separate commits/PRs in those repos

---

## When to Run Visual Tests

Run the SDL_VisualTest suite and generate reports when changes **directly or indirectly affect visual output** in a game project:

### Run visual tests when:

- SDL_VisualTest framework code changes (renderer, comparison, reporting)
- Game project rendering code changes (draw calls, shaders, layout)
- Asset pipeline changes that affect loaded textures/sprites
- Build configuration changes that could alter compiled rendering behavior

### Skip visual tests when:

- Changes are documentation-only (steering docs, README, guides)
- Changes are pure logic with no rendering impact
- Changes are to Kiro-Tooling or automation scripts only

---

## Running Tests and Generating Reports

For each affected game project (e.g., Zeitgeist-Evolved):

```batch
cd c:\Users\Daniel Sawitzki\Desktop\github\Zeitgeist Evolved
build_test_visual.bat
```

To generate a Markdown report with screenshots:

```batch
cd c:\Users\Daniel Sawitzki\Desktop\github\SDL_VisualTest
generate_report.bat
```

Attach the report to the GitHub issue:

```bash
gh issue comment <number> --repo <repo> --body-file <path-to-report.md>
```

---

## Cross-Repo Coordination

When a single issue requires changes across multiple repos:

1. Implement and commit in each repo separately
2. Create PRs in each affected repo, cross-referencing the issue
3. Note all affected repos in the issue completion comment
4. Ensure builds pass in each repo independently before posting completion

---

## Steering Doc Locations

| Scope | Location | Purpose |
|---|---|---|
| Global workflow | `~/.kiro/steering/github-issue-workflow.md` | Issue pickup, lifecycle, communication rules |
| Workspace orchestration | `Game-Dev-Supreme/.kiro/steering/` | Multi-repo coordination, SDL_VisualTest workflow |
| Per-project visual testing | `Zeitgeist-Evolved/.kiro/steering/visual-testing.md` | Project-specific test scenarios, hooks, commands |
| SDL_VisualTest template | `SDL_VisualTest/steering/visual-testing.md` | Template for new consuming projects to copy |

Changes to **how the workflow operates** (this doc) belong in Game-Dev-Supreme.
Changes to **project-specific test configuration** belong in that project's `.kiro/steering/` folder.
Changes to **the reusable template** belong in `SDL_VisualTest/steering/`.
