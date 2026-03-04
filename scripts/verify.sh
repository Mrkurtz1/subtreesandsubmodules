#!/usr/bin/env bash
# =============================================================================
# verify.sh — Validate the repo state after each demo step
#
# Usage:
#   bash scripts/verify.sh <step>
#
# Steps:
#   bootstrap   — verify that bare remotes exist and have the expected tags
#   baseline    — verify the cloned main-app has the app but no deps
#   submodule   — verify submodule was added correctly
#   sub-clone   — verify that a fresh clone has empty submodule dirs
#   sub-init    — verify that submodule init+update populated the directory
#   subtree     — verify subtree directory contains dependency files
#   all         — run all checks in sequence
# =============================================================================
set -euo pipefail

# ---- Colors ----
if [ -t 1 ]; then
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    CYAN='\033[0;36m'
    RESET='\033[0m'
else
    GREEN='' RED='' CYAN='' RESET=''
fi

pass() { echo -e "  ${GREEN}PASS${RESET}  $*"; }
fail() { echo -e "  ${RED}FAIL${RESET}  $*"; FAILURES=$((FAILURES + 1)); }
info() { echo -e "${CYAN}[CHECK]${RESET} $*"; }

FAILURES=0

# Auto-detect paths — the script can be run from the project root or demo/main-app
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEMO_DIR="$PROJECT_ROOT/demo"

# If the user is inside the cloned main-app, detect that
if [ -d "$PWD/app" ] && [ -f "$PWD/app/main.py" ]; then
    MAIN_APP_DIR="$PWD"
else
    MAIN_APP_DIR="$DEMO_DIR/main-app"
fi

# ---- Step functions ----

check_bootstrap() {
    info "Verifying bootstrap..."

    # Check bare remotes exist
    for repo in main-app.git dep-lib-a.git dep-lib-b.git; do
        if [ -d "$DEMO_DIR/remotes/$repo" ]; then
            pass "Bare remote exists: demo/remotes/$repo"
        else
            fail "Bare remote missing: demo/remotes/$repo"
        fi
    done

    # Check dep-lib-a tags
    pushd "$DEMO_DIR/remotes/dep-lib-a.git" >/dev/null
    for tag in v1 v2; do
        if git tag -l "$tag" | grep -q "$tag"; then
            pass "dep-lib-a has tag $tag"
        else
            fail "dep-lib-a missing tag $tag"
        fi
    done
    popd >/dev/null

    # Check dep-lib-b tags
    pushd "$DEMO_DIR/remotes/dep-lib-b.git" >/dev/null
    for tag in v1 v2; do
        if git tag -l "$tag" | grep -q "$tag"; then
            pass "dep-lib-b has tag $tag"
        else
            fail "dep-lib-b missing tag $tag"
        fi
    done
    popd >/dev/null
}

check_baseline() {
    info "Verifying baseline (cloned main-app)..."

    if [ -f "$MAIN_APP_DIR/app/main.py" ]; then
        pass "app/main.py exists"
    else
        fail "app/main.py not found in $MAIN_APP_DIR"
    fi

    # Dependencies should NOT be present yet
    if [ ! -d "$MAIN_APP_DIR/libs/dep-lib-a/dep_lib_a" ]; then
        pass "libs/dep-lib-a is not present (expected — no submodule yet)"
    else
        fail "libs/dep-lib-a already present (should not exist at baseline)"
    fi

    if [ ! -d "$MAIN_APP_DIR/vendor/dep-lib-b/dep_lib_b" ]; then
        pass "vendor/dep-lib-b is not present (expected — no subtree yet)"
    else
        fail "vendor/dep-lib-b already present (should not exist at baseline)"
    fi
}

check_submodule() {
    info "Verifying submodule addition..."

    pushd "$MAIN_APP_DIR" >/dev/null

    # .gitmodules must exist
    if [ -f ".gitmodules" ]; then
        pass ".gitmodules exists"
    else
        fail ".gitmodules not found"
    fi

    # .gitmodules must reference dep-lib-a
    if grep -q "dep-lib-a" .gitmodules 2>/dev/null; then
        pass ".gitmodules contains dep-lib-a entry"
    else
        fail ".gitmodules does not contain dep-lib-a entry"
    fi

    # Submodule directory should exist
    if [ -d "libs/dep-lib-a" ]; then
        pass "libs/dep-lib-a directory exists"
    else
        fail "libs/dep-lib-a directory not found"
    fi

    # Check submodule status
    if git submodule status | grep -q "libs/dep-lib-a"; then
        pass "git submodule status lists libs/dep-lib-a"
    else
        fail "git submodule status does not list libs/dep-lib-a"
    fi

    popd >/dev/null
}

check_sub_clone() {
    info "Verifying fresh clone (submodule dirs should be empty)..."

    CLONE_DIR="$DEMO_DIR/main-app-clone-test"
    rm -rf "$CLONE_DIR"
    git clone "$DEMO_DIR/remotes/main-app.git" "$CLONE_DIR" >/dev/null 2>&1

    pushd "$CLONE_DIR" >/dev/null

    if [ -f ".gitmodules" ]; then
        pass ".gitmodules present in clone"
    else
        fail ".gitmodules missing in clone"
        popd >/dev/null
        return
    fi

    # The submodule directory should exist but be empty (no populated files)
    if [ -d "libs/dep-lib-a" ]; then
        FILE_COUNT=$(find "libs/dep-lib-a" -type f 2>/dev/null | wc -l)
        if [ "$FILE_COUNT" -eq 0 ]; then
            pass "libs/dep-lib-a exists but is empty (submodule not initialized)"
        else
            fail "libs/dep-lib-a has $FILE_COUNT file(s) — expected empty before init"
        fi
    else
        pass "libs/dep-lib-a directory not yet created (expected before submodule init)"
    fi

    popd >/dev/null
    rm -rf "$CLONE_DIR"
}

check_sub_init() {
    info "Verifying submodule init + update..."

    pushd "$MAIN_APP_DIR" >/dev/null

    # After init+update, the submodule should have files
    if [ -f "libs/dep-lib-a/dep_lib_a/__init__.py" ]; then
        pass "libs/dep-lib-a/dep_lib_a/__init__.py exists (submodule populated)"
    else
        fail "libs/dep-lib-a/dep_lib_a/__init__.py not found (submodule not populated)"
    fi

    popd >/dev/null
}

check_subtree() {
    info "Verifying subtree addition..."

    pushd "$MAIN_APP_DIR" >/dev/null

    # vendor/dep-lib-b should have the dependency files
    if [ -f "vendor/dep-lib-b/dep_lib_b/__init__.py" ]; then
        pass "vendor/dep-lib-b/dep_lib_b/__init__.py exists"
    else
        fail "vendor/dep-lib-b/dep_lib_b/__init__.py not found"
    fi

    # Main repo history should contain commits touching vendor/dep-lib-b
    COMMITS=$(git log --oneline -- vendor/dep-lib-b 2>/dev/null | wc -l)
    if [ "$COMMITS" -gt 0 ]; then
        pass "git log -- vendor/dep-lib-b shows $COMMITS commit(s) in main history"
    else
        fail "git log -- vendor/dep-lib-b shows no commits (subtree not in history)"
    fi

    popd >/dev/null
}

# ---- Main dispatch ----
STEP="${1:-help}"

case "$STEP" in
    bootstrap)
        check_bootstrap
        ;;
    baseline)
        check_baseline
        ;;
    submodule)
        check_submodule
        ;;
    sub-clone)
        check_sub_clone
        ;;
    sub-init)
        check_sub_init
        ;;
    subtree)
        check_subtree
        ;;
    all)
        check_bootstrap
        check_baseline
        check_submodule
        check_sub_init
        check_subtree
        ;;
    *)
        echo "Usage: bash scripts/verify.sh <step>"
        echo ""
        echo "Steps:"
        echo "  bootstrap   — verify bare remotes and tags"
        echo "  baseline    — verify cloned main-app (no deps)"
        echo "  submodule   — verify submodule was added"
        echo "  sub-clone   — verify fresh clone has empty submodule dirs"
        echo "  sub-init    — verify submodule init populated files"
        echo "  subtree     — verify subtree directory and history"
        echo "  all         — run all checks"
        exit 1
        ;;
esac

# ---- Summary ----
echo ""
if [ "$FAILURES" -eq 0 ]; then
    echo -e "${GREEN}All checks passed.${RESET}"
else
    echo -e "${RED}$FAILURES check(s) failed.${RESET}"
    exit 1
fi
