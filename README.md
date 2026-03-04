# Git Submodules & Subtrees — Hands-On Demo

A self-contained, offline-capable walkthrough that shows two ways to include
external repositories inside a main project: **Git submodules** and **Git
subtrees**.

---

## Table of Contents

1. [What You Will Learn](#1-what-you-will-learn)
2. [Prerequisites](#2-prerequisites)
3. [Bootstrap: Create the Demo World Locally](#3-bootstrap-create-the-demo-world-locally)
4. [Baseline: Single Repository](#4-baseline-single-repository)
5. [Demo A: Submodules](#5-demo-a-submodules)
6. [Demo B: Subtrees](#6-demo-b-subtrees)
7. [Comparison Table](#7-comparison-table)
8. [Cleanup](#8-cleanup)

---

## 1. What You Will Learn

### Mental models

| Concept | One-liner |
|---------|-----------|
| **Submodule** | An embedded repository with its own history. The superproject tracks it via a file called `.gitmodules` and a *commit pointer* — a SHA that records exactly which commit of the external repo is "pinned." |
| **Subtree / Subtree merge** | Another repository's content is copied into a folder of the main repo. The files become part of the main repo's history — there is no separate `.gitmodules` pointer. |

### Key difference at a glance

- **Submodule**: the main repo stores a *reference* (URL + commit SHA). The
  actual code lives in the submodule's own repo. After cloning, you must
  explicitly initialize and update to populate the submodule directory.
- **Subtree**: the main repo stores the *actual files*. After cloning, the
  dependency files are already there — no extra steps required.

---

## 2. Prerequisites

| Requirement | Notes |
|---|---|
| **Git** ≥ 2.20 | `git --version` to check. `git subtree` is included in most modern installs. |
| **Bash** | macOS Terminal, Linux shell, or Git Bash on Windows. |
| **Python 3.x** *(optional)* | Only needed to *run* the demo app. The Git concepts work without it. |

---

## 3. Bootstrap: Create the Demo World Locally

### What the bootstrap script does

The script creates three **local bare repositories** inside a `demo/remotes/`
folder. These act exactly like remote repos (think of them as a local GitHub)
but require no network access.

> **What is a bare repository?**
> A bare repo is a Git repository that has *no working tree* — it contains only
> the `.git` internals (objects, refs, etc.). It is the format used by hosting
> services like GitHub under the hood. You push to and fetch from bare repos,
> but you never edit files in them directly.

The three remotes are:

| Bare remote | Description |
|---|---|
| `demo/remotes/main-app.git` | The main application repo |
| `demo/remotes/dep-lib-a.git` | Dependency A — a tiny Python library (tags: `v1`, `v2`) |
| `demo/remotes/dep-lib-b.git` | Dependency B — a second tiny Python library (tags: `v1`, `v2`) |

### Run the bootstrap

```bash
# From the project root directory:
bash scripts/bootstrap.sh
```

**Expected output** (abbreviated):

```
[INFO]  Demo directory created at: .../demo
[OK]    Bare remote: demo/remotes/dep-lib-a.git
[OK]    dep-lib-a v1 committed and tagged
[OK]    dep-lib-a v2 committed and tagged
[OK]    dep-lib-a pushed to bare remote
[OK]    Bare remote: demo/remotes/dep-lib-b.git
[OK]    dep-lib-b v1 committed and tagged
[OK]    dep-lib-b v2 committed and tagged
[OK]    dep-lib-b pushed to bare remote
[OK]    Bare remote: demo/remotes/main-app.git
[OK]    main-app baseline committed
[OK]    main-app pushed to bare remote

============================================================
  Bootstrap complete!
============================================================
```

### Verify

```bash
bash scripts/verify.sh bootstrap
```

All checks should show `PASS`.

---

## 4. Baseline: Single Repository

### Clone the main-app

```bash
cd demo
git clone remotes/main-app.git main-app
cd main-app
```

### Explore the repo

```bash
ls -R
```

**Expected output:**

```
.:
README.md  app

./app:
main.py
```

There are no `libs/` or `vendor/` directories — the dependencies are not
included yet.

### Run the app (optional, requires Python 3)

```bash
python3 app/main.py
```

**Expected output:**

```
============================================================
  Git Submodules & Subtrees Demo Application
============================================================

[Dependency A — submodule target: libs/dep-lib-a]
  Status  : NOT FOUND
  (Run the Submodule demo to add this dependency)

[Dependency B — subtree target: vendor/dep-lib-b]
  Status  : NOT FOUND
  (Run the Subtree demo to add this dependency)

============================================================
```

Both dependencies report "NOT FOUND" because we haven't added them yet.

### Verify

```bash
# Run from inside demo/main-app/ — the script auto-detects the directory:
bash ../../scripts/verify.sh baseline
```

---

## 5. Demo A: Submodules

All commands below should be run from inside `demo/main-app/`.

### Step 1 — Add a submodule

The URL passed to `git submodule add` is *relative to the superproject's
origin remote*, not to your working directory. Since the main-app was cloned
from `demo/remotes/main-app.git`, the path `../dep-lib-a.git` resolves to
`demo/remotes/dep-lib-a.git` — exactly where bootstrap created it.

```bash
git submodule add ../dep-lib-a.git libs/dep-lib-a
```

> **Note:** If you see `fatal: transport 'file' not allowed`, run:
> ```bash
> git config --global protocol.file.allow always
> ```
> This is a security setting added in Git 2.38.1 that restricts local file
> transport by default. The bootstrap script sets this automatically.

**What happened:**

1. Git cloned `dep-lib-a.git` into the `libs/dep-lib-a/` directory.
2. A `.gitmodules` file was created (or updated) in the repo root.
3. Git staged both `.gitmodules` and the `libs/dep-lib-a` entry.

Inspect `.gitmodules`:

```bash
cat .gitmodules
```

**Expected output:**

```ini
[submodule "libs/dep-lib-a"]
	path = libs/dep-lib-a
	url = ../dep-lib-a.git
```

This tells Git: "there is a submodule at `libs/dep-lib-a`, and its remote URL
is `../dep-lib-a.git` (relative to the superproject's origin remote)."

### Step 2 — Commit the submodule addition

```bash
git add .gitmodules libs/dep-lib-a
git commit -m "Add dep-lib-a as a submodule in libs/"
```

### Step 3 — Inspect the state

Check which commit the superproject has pinned:

```bash
git submodule status
```

**Expected output** (SHA will vary):

```
 <sha> libs/dep-lib-a (v2)
```

The SHA shown is the *exact commit* of dep-lib-a that this superproject
references. Notice it says `(v2)` — the latest commit. The superproject
records this SHA in its tree; it does **not** track a branch.

You can also see what Git stores for the submodule entry:

```bash
git ls-tree HEAD libs/dep-lib-a
```

**Expected output:**

```
160000 commit <sha>	libs/dep-lib-a
```

The special mode `160000` marks this tree entry as a submodule — it records a
commit SHA, not a blob or subtree.

### Step 4 — Push the superproject

```bash
git push origin main 2>/dev/null || git push origin master
```

### Step 5 — Clone behavior (submodule directory is empty!)

This is one of the most important things to understand about submodules. Let's
simulate what a teammate sees when they clone:

```bash
cd ..
git clone remotes/main-app.git main-app-fresh-clone
cd main-app-fresh-clone
```

Now look at the submodule directory:

```bash
ls libs/dep-lib-a/
```

**Expected output:**

```
(empty — no files listed)
```

The directory exists but is **empty**. A plain `git clone` does NOT
automatically fetch and check out submodule contents. The `.gitmodules` file is
there, but the submodule working tree is not populated.

### Step 6 — Initialize and update the submodule

```bash
git submodule init
```

**What `init` does:** copies submodule URL information from `.gitmodules` into
your local `.git/config`. After this, Git knows *where* to fetch the submodule
from, but it hasn't fetched anything yet.

```bash
git submodule update
```

**What `update` does:** fetches the submodule repository and checks out the
exact commit that the superproject has pinned.

Now check:

```bash
ls libs/dep-lib-a/dep_lib_a/
```

**Expected output:**

```
__init__.py
```

The submodule is now populated. You can combine both steps in one:

```bash
# Equivalent shorthand (for future reference):
git submodule update --init
```

Or clone with submodules from the start:

```bash
# Alternative: clone + initialize all submodules in one step:
# git clone --recurse-submodules remotes/main-app.git main-app-recursive
```

### Step 7 — Pinning: update the submodule to a different commit

Let's go back to the original main-app and pin the submodule to v1 instead of
v2, to show how pinning works:

```bash
cd ../main-app
```

First, see what version we currently have:

```bash
cd libs/dep-lib-a
git log --oneline
```

**Expected output:**

```
<sha2> dep-lib-a: release v2 with extras()
<sha1> dep-lib-a: initial release (v1)
```

Check out the v1 tag:

```bash
git checkout v1
```

Go back to the superproject root and see the change:

```bash
cd ../..
git submodule status
```

**Expected output:**

```
+<sha1> libs/dep-lib-a (v1)
```

The `+` prefix means the submodule's checked-out commit differs from what the
superproject has recorded. To *commit* this pin change:

```bash
git add libs/dep-lib-a
git commit -m "Pin dep-lib-a to v1"
```

Now the superproject records that it wants v1. Any teammate who runs
`git submodule update` will get v1.

To move back to v2 later:

```bash
cd libs/dep-lib-a
git checkout v2
cd ../..
git add libs/dep-lib-a
git commit -m "Update dep-lib-a to v2"
```

### Step 8 — Run the app with the submodule loaded

```bash
python3 app/main.py
```

**Expected output** (if pinned to v2):

```
============================================================
  Git Submodules & Subtrees Demo Application
============================================================

[Dependency A — submodule target: libs/dep-lib-a]
  Status  : LOADED
  Version : 2.0.0
  Message : Hello from dep-lib-a v2 — now with improvements!

[Dependency B — subtree target: vendor/dep-lib-b]
  Status  : NOT FOUND
  (Run the Subtree demo to add this dependency)

============================================================
```

### Verify

```bash
# Run from inside demo/main-app/ — the script auto-detects the directory:
bash ../../scripts/verify.sh submodule
```

Push the changes:

```bash
git push origin main 2>/dev/null || git push origin master
```

---

## 6. Demo B: Subtrees

All commands below should be run from inside `demo/main-app/`.

> **Note on `git subtree` availability:**
> `git subtree` is distributed with Git as a contributed command. It is included
> in most modern Git installations (Homebrew, official Git for Windows, Linux
> packages). If `git subtree` is not available on your system, see
> [Option 2: Subtree Merge (manual)](#option-2-subtree-merge-manual-fallback)
> below as a fallback.

### Option 1: `git subtree` (preferred)

#### Step 1 — Add a remote for the dependency

```bash
cd demo/main-app   # if not already there
git remote add dep-lib-b ../remotes/dep-lib-b.git
```

This adds a named remote so we can reference it by name instead of path.

#### Step 2 — Add the subtree

```bash
git subtree add --prefix=vendor/dep-lib-b dep-lib-b main --squash
```

> If `main` doesn't work, try `master` — it depends on which default branch
> name your Git version uses.

**What happened:**

1. Git fetched the entire history of `dep-lib-b`.
2. It squashed that history into a single commit (because of `--squash`).
3. It placed all the files under `vendor/dep-lib-b/`.
4. It created a merge commit in your main repo that records the addition.

The `--squash` flag is optional but recommended — it keeps your main repo
history clean by collapsing the dependency's history into one commit.

**Check the result:**

```bash
ls vendor/dep-lib-b/
```

**Expected output:**

```
README.md  dep_lib_b
```

```bash
ls vendor/dep-lib-b/dep_lib_b/
```

**Expected output:**

```
__init__.py
```

The files are *real files* in your repo — not pointers or references. They are
part of your main repo's history.

#### Step 3 — Verify the files are in main repo history

```bash
git log --oneline -- vendor/dep-lib-b
```

**Expected output** (SHAs will vary):

```
<sha2> Squashed 'vendor/dep-lib-b/' content from <sha>
<sha1> Merge commit '<sha>' as 'vendor/dep-lib-b'
```

These commits are in the *main repo's* history — not in a separate repo.

#### Step 4 — Update the subtree (pull new changes)

If dep-lib-b gets updated upstream, you can pull changes:

```bash
git subtree pull --prefix=vendor/dep-lib-b dep-lib-b main --squash
```

> If `main` doesn't work, try `master`.

This fetches any new commits from the dep-lib-b remote and merges them into
`vendor/dep-lib-b/`. If there are no new changes, Git will report that
everything is up to date.

#### Step 5 — Run the app

```bash
python3 app/main.py
```

**Expected output:**

```
============================================================
  Git Submodules & Subtrees Demo Application
============================================================

[Dependency A — submodule target: libs/dep-lib-a]
  Status  : LOADED
  Version : 2.0.0
  Message : Hello from dep-lib-a v2 — now with improvements!

[Dependency B — subtree target: vendor/dep-lib-b]
  Status  : LOADED
  Version : 2.0.0
  Message : Greetings from dep-lib-b v2 — upgraded!

============================================================
```

Both dependencies are now loaded.

#### Step 6 — Push

```bash
git push origin main 2>/dev/null || git push origin master
```

### Option 2: Subtree Merge (manual fallback)

If `git subtree` is not available, you can achieve a similar result with a
manual subtree merge strategy:

```bash
# 1. Add the remote
git remote add dep-lib-b ../remotes/dep-lib-b.git

# 2. Fetch its history
git fetch dep-lib-b

# 3. Create a local tracking branch (optional but helpful)
git checkout -b dep-lib-b-branch dep-lib-b/main  # or dep-lib-b/master

# 4. Switch back to your main branch
git checkout main  # or master

# 5. Read the dependency tree into vendor/dep-lib-b/
git read-tree --prefix=vendor/dep-lib-b/ -u dep-lib-b-branch

# 6. Commit
git commit -m "Add dep-lib-b via subtree merge into vendor/"

# To update later:
# git checkout dep-lib-b-branch
# git pull
# git checkout main
# git merge -s subtree dep-lib-b-branch
```

This approach stores the same files in the same place. The difference is that
you manage the merge manually instead of using the `git subtree` helper.

### Verify

```bash
# Run from inside demo/main-app/:
bash ../../scripts/verify.sh subtree
```

---

## 7. Comparison Table

| Aspect | Submodule | Subtree |
|---|---|---|
| **What's in the main repo** | A commit pointer (SHA) + `.gitmodules` metadata | The actual files — fully committed in main repo history |
| **Clone experience** | Submodule dirs are **empty** after `git clone`. Requires `--recurse-submodules` or `git submodule update --init`. | Files are **immediately present** — no extra steps |
| **Developer friction** | Higher: every developer must know to init/update submodules. CI scripts need extra steps. | Lower: the dependency is just "files in a folder" — works like any other code |
| **Version pinning** | Explicit: superproject records a specific commit SHA. Updating requires `cd`-ing into the submodule, fetching, checking out, then committing the pointer change in the superproject. | Implicit: you pull from the remote when you want updates. The current state is whatever was last merged. |
| **History** | Dependency history stays in the submodule's own repo. Main repo history is clean. | Dependency history is merged into the main repo (or squashed). Main repo history is larger. |
| **Updating** | `git submodule update --remote` or manual checkout + commit | `git subtree pull --prefix=... <remote> <branch>` |
| **Risk of drift** | High if developers forget to update submodules. "Works on my machine" when submodule SHAs diverge. | Lower — files are always there. But updates can introduce unexpected changes if not reviewed. |
| **Contributing back upstream** | Easy: `cd` into submodule, commit, push to the submodule's remote | Possible with `git subtree push` but less common in practice |
| **Removing the dependency** | `git rm <path>`, remove entry from `.gitmodules`, clean `.git/modules/` | `git rm -r <prefix>` — just delete the folder |

### When to use which?

- **Submodules** work well when the dependency is a separate project with its
  own release cycle, and you need to pin to specific versions.
- **Subtrees** work well when you want a simpler clone experience and don't
  mind the dependency's files living in your main repo history.

Neither is universally "better" — the right choice depends on your team's
workflow and the relationship between the repos.

---

## 8. Cleanup

To remove the entire demo environment and start fresh:

```bash
# From the project root:
rm -rf demo/
```

Then re-run `bash scripts/bootstrap.sh` to start over.

To remove only the fresh-clone test directories:

```bash
rm -rf demo/main-app-fresh-clone
```
