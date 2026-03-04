# Requirements Document: Git Submodules + Subtrees Demonstration Repo

## 1. Purpose

Create a self-contained learning project that demonstrates, from a single starting
repository, how:

- **Git submodules** embed an external repository reference at a specific commit
  (superproject + submodule relationship).
- **Git subtrees** (and/or subtree merges) bring another repository's content into a
  subdirectory of the main repo in a way that can be committed/merged with the main
  project.

## 2. Target audience

- Engineers who know basic Git (clone/add/commit/push) but don't understand
  submodules/subtrees in practice.
- Viewers of an internal workshop / onboarding session.

## 3. Non-goals

- Not a full Git tutorial.
- Not a dependency management recommendation for all teams (the repo should explain
  tradeoffs, but not dictate policy).

## 4. Deliverables

### 4.1 Repository contents (top-level)

The repository MUST include:

- **README.md**
  - Step-by-step demo instructions for:
    - Baseline single repo setup
    - Submodule workflow
    - Subtree workflow
  - For each workflow: commands to run + expected repo state and what "exists" locally
    vs. in Git history.

- **REQUIREMENTS.md** (this document)

- **scripts/** folder containing automation helpers:
  - `scripts/bootstrap.sh` (or `.ps1` on Windows) to create local demo remotes and
    initialize the walkthrough from scratch.
  - `scripts/verify.sh` to assert the repo is in the expected state after each step.

- Two tiny "external" repositories used as dependencies (created locally by bootstrap):
  - `dep-lib-a` (example library)
  - `dep-lib-b` (optional second dependency to show multiple submodules/subtrees)

These "external repos" MUST be created as local bare repositories (or local working
repos + local bare remotes) so the demo works offline and clearly shows what is
"external."

## 5. Implementation requirements

### 5.1 Language / content

- The code examples MAY be Python or Java (either is acceptable).
- The "dependency" repos should expose a tiny callable artifact:
  - **Python**: a module with a function like `dep_lib_a.version()` and/or
    `dep_lib_a.hello()`
  - **Java**: a minimal class with a static method

### 5.2 Repository design constraints

- The primary repo MUST start as a plain single repository with a working app that runs
  before any submodule/subtree steps.
- The demo MUST be runnable without needing network access (use local remotes).
- The README MUST show commands exactly and include expected outputs/state checks.

## 6. README requirements (step-by-step)

### 6.1 "What you will learn"

- Definitions and mental model:
  - **Submodule** = embedded repo with its own history; superproject tracks the submodule
    via metadata (including `.gitmodules`) and commit pointer.
  - **Subtree/subtree merge** = another repo's content stored in a folder of the main
    repo; changes live in the main repo history.

### 6.2 "Prerequisites"

- Git installed
- Shell environment (bash or PowerShell)
- Optional: Python 3.x or Java + build tool (depending on your choice)

### 6.3 "Bootstrap: create the demo world locally"

README MUST instruct the user to run a bootstrap script that creates:
- A main repo remote (bare)
- One or two dependency remotes (bare)
- Initial commits and tags to demonstrate pinning/updating

Explain what a "bare remote" is in plain terms (a repository store without a working
tree), since the user will be interacting with it conceptually as the "external repo."

### 6.4 "Baseline: single repository"

Must include commands to:
- Clone the main repo
- Run the app
- Show that dependencies are not yet included

### 6.5 "Demo A: Submodules"

The README MUST demonstrate at least these actions and explain the resulting state:

1. **Add a submodule** into a subdirectory
2. **Clone behavior** — show that a normal `git clone` does not automatically populate
   submodule working directories
3. **Initialize and update** — include `git submodule init` and `git submodule update`
4. **Pinning** — demonstrate that the superproject points to a specific submodule commit
5. **State inspection** — show how to inspect `.gitmodules`, submodule status, etc.

### 6.6 "Demo B: Subtrees"

Demonstrate:
- **Option 1** (preferred): `git subtree` workflow
- **Option 2**: subtree merge workflow (as fallback)

### 6.7 "Comparison table"

README MUST include a short comparison emphasizing:
- What lives in main repo history vs. what remains external
- Clone UX and developer friction
- Updating workflows and risk of drift

## 7. Scripts requirements

### 7.1 scripts/bootstrap.*

Must create demo remotes locally with initial commits and tags.

### 7.2 scripts/verify.*

Must validate after each step (submodule state, subtree directory contents, etc.).

## 8. Acceptance criteria (testable)

A solution is "done" when:
1. A fresh user can run bootstrap and complete both demos without manual repo creation.
2. README instructions work verbatim on at least one platform (Linux/macOS bash).
3. The README clearly answers "how do the external repos exist?"
4. The user can reproduce both submodule and subtree clone scenarios.

## 9. Suggested repo layout

```
/README.md
/REQUIREMENTS.md
/scripts/bootstrap.sh
/scripts/verify.sh
/app/                # main app
/vendor/             # subtree target folder(s)
```
