#!/usr/bin/env bash
# =============================================================================
# bootstrap.sh — Create the local "demo world" for Git Submodules & Subtrees
#
# This script creates:
#   1. Local bare repositories that act as "remote" repos (no network needed)
#   2. Initial commits and tags in the dependency repos
#   3. A main repo remote with the baseline application committed
#
# Usage:
#   cd <project-root>
#   bash scripts/bootstrap.sh
#
# After running, the directory "demo/" will contain everything you need.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEMO_DIR="$PROJECT_ROOT/demo"

# ---- Colors (if terminal supports them) ----
if [ -t 1 ]; then
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    RESET='\033[0m'
else
    GREEN='' YELLOW='' CYAN='' RESET=''
fi

info()  { echo -e "${CYAN}[INFO]${RESET}  $*"; }
ok()    { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${RESET}  $*"; }

# ---- Ensure local file:// transport is allowed (Git >= 2.38.1 security) ----
git config --global protocol.file.allow always 2>/dev/null || true

# ---- Clean slate ----
if [ -d "$DEMO_DIR" ]; then
    warn "Removing existing demo/ directory..."
    rm -rf "$DEMO_DIR"
fi

mkdir -p "$DEMO_DIR/remotes"
info "Demo directory created at: $DEMO_DIR"

# =============================================================================
# 1. Create dep-lib-a (bare remote + working clone for committing)
# =============================================================================
info "Creating dep-lib-a remote..."

# Init bare remote
git init --bare "$DEMO_DIR/remotes/dep-lib-a.git" >/dev/null 2>&1
ok "Bare remote: demo/remotes/dep-lib-a.git"

# Temporary working clone to make commits
WORK_A=$(mktemp -d)
git clone "$DEMO_DIR/remotes/dep-lib-a.git" "$WORK_A" >/dev/null 2>&1
pushd "$WORK_A" >/dev/null

git config user.email "demo@example.com"
git config user.name  "Demo User"
git config commit.gpgsign false
git config tag.gpgsign false

# ---- v1 commit ----
mkdir -p dep_lib_a
cat > dep_lib_a/__init__.py << 'PYEOF'
"""dep-lib-a — a tiny demo dependency (v1)."""

def version():
    return "1.0.0"

def hello():
    return "Hello from dep-lib-a v1!"
PYEOF

cat > README.md << 'MDEOF'
# dep-lib-a

A tiny Python library used as a dependency in the Git Submodules & Subtrees demo.
MDEOF

git add -A
git commit -m "dep-lib-a: initial release (v1)" >/dev/null
git tag v1
ok "dep-lib-a v1 committed and tagged"

# ---- v2 commit (changed behavior for update demo) ----
cat > dep_lib_a/__init__.py << 'PYEOF'
"""dep-lib-a — a tiny demo dependency (v2)."""

def version():
    return "2.0.0"

def hello():
    return "Hello from dep-lib-a v2 — now with improvements!"

def extras():
    return "This function was added in v2."
PYEOF

git add -A
git commit -m "dep-lib-a: release v2 with extras()" >/dev/null
git tag v2
ok "dep-lib-a v2 committed and tagged"

git push origin main --tags >/dev/null 2>&1 || git push origin master --tags >/dev/null 2>&1
ok "dep-lib-a pushed to bare remote"

popd >/dev/null
rm -rf "$WORK_A"

# =============================================================================
# 2. Create dep-lib-b (bare remote + working clone for committing)
# =============================================================================
info "Creating dep-lib-b remote..."

git init --bare "$DEMO_DIR/remotes/dep-lib-b.git" >/dev/null 2>&1
ok "Bare remote: demo/remotes/dep-lib-b.git"

WORK_B=$(mktemp -d)
git clone "$DEMO_DIR/remotes/dep-lib-b.git" "$WORK_B" >/dev/null 2>&1
pushd "$WORK_B" >/dev/null

git config user.email "demo@example.com"
git config user.name  "Demo User"
git config commit.gpgsign false
git config tag.gpgsign false

# ---- v1 commit ----
mkdir -p dep_lib_b
cat > dep_lib_b/__init__.py << 'PYEOF'
"""dep-lib-b — a second demo dependency (v1)."""

def version():
    return "1.0.0"

def hello():
    return "Greetings from dep-lib-b v1!"
PYEOF

cat > README.md << 'MDEOF'
# dep-lib-b

A second tiny Python library for the Git Submodules & Subtrees demo.
MDEOF

git add -A
git commit -m "dep-lib-b: initial release (v1)" >/dev/null
git tag v1
ok "dep-lib-b v1 committed and tagged"

# ---- v2 commit ----
cat > dep_lib_b/__init__.py << 'PYEOF'
"""dep-lib-b — a second demo dependency (v2)."""

def version():
    return "2.0.0"

def hello():
    return "Greetings from dep-lib-b v2 — upgraded!"

def info():
    return "dep-lib-b now includes an info() function in v2."
PYEOF

git add -A
git commit -m "dep-lib-b: release v2 with info()" >/dev/null
git tag v2
ok "dep-lib-b v2 committed and tagged"

git push origin main --tags >/dev/null 2>&1 || git push origin master --tags >/dev/null 2>&1
ok "dep-lib-b pushed to bare remote"

popd >/dev/null
rm -rf "$WORK_B"

# =============================================================================
# 3. Create main-app bare remote and seed it with the baseline app
# =============================================================================
info "Creating main-app remote..."

git init --bare "$DEMO_DIR/remotes/main-app.git" >/dev/null 2>&1
ok "Bare remote: demo/remotes/main-app.git"

WORK_MAIN=$(mktemp -d)
git clone "$DEMO_DIR/remotes/main-app.git" "$WORK_MAIN" >/dev/null 2>&1
pushd "$WORK_MAIN" >/dev/null

git config user.email "demo@example.com"
git config user.name  "Demo User"
git config commit.gpgsign false
git config tag.gpgsign false

# Copy the app from the project
mkdir -p app
cp "$PROJECT_ROOT/app/main.py" app/main.py

cat > README.md << 'MDEOF'
# main-app

The primary application for the Git Submodules & Subtrees demo.

Run with:

    python3 app/main.py
MDEOF

git add -A
git commit -m "main-app: baseline application (no dependencies yet)" >/dev/null
ok "main-app baseline committed"

git push origin main >/dev/null 2>&1 || git push origin master >/dev/null 2>&1
ok "main-app pushed to bare remote"

popd >/dev/null
rm -rf "$WORK_MAIN"

# =============================================================================
# Done!
# =============================================================================
echo ""
echo -e "${GREEN}============================================================${RESET}"
echo -e "${GREEN}  Bootstrap complete!${RESET}"
echo -e "${GREEN}============================================================${RESET}"
echo ""
echo "  The following local bare remotes have been created:"
echo ""
echo "    demo/remotes/main-app.git     — the main application"
echo "    demo/remotes/dep-lib-a.git    — dependency A (tags: v1, v2)"
echo "    demo/remotes/dep-lib-b.git    — dependency B (tags: v1, v2)"
echo ""
echo "  These bare repos act as 'remote' repositories — like a local"
echo "  version of GitHub. They store Git history but have no working"
echo "  tree (no checked-out files). You will clone from them in the"
echo "  demo steps."
echo ""
echo "  Next step: follow the README.md instructions starting at"
echo "  'Baseline: single repository'."
echo ""
