#!/usr/bin/env python3
"""
Main application for the Git Submodules & Subtrees demo.

This app tries to import two dependency libraries (dep-lib-a and dep-lib-b).
Before the submodule/subtree demos, these imports will fail gracefully,
showing that the dependencies are not yet available.
"""

import sys
import os

def try_import_submodule_dep():
    """Try to import dep_lib_a from the submodule location (libs/dep-lib-a)."""
    submodule_path = os.path.join(os.path.dirname(__file__), "..", "libs", "dep-lib-a")
    submodule_path = os.path.normpath(submodule_path)
    if submodule_path not in sys.path:
        sys.path.insert(0, submodule_path)
    try:
        import dep_lib_a
        return dep_lib_a
    except ImportError:
        return None

def try_import_subtree_dep():
    """Try to import dep_lib_b from the subtree location (vendor/dep-lib-b)."""
    subtree_path = os.path.join(os.path.dirname(__file__), "..", "vendor", "dep-lib-b")
    subtree_path = os.path.normpath(subtree_path)
    if subtree_path not in sys.path:
        sys.path.insert(0, subtree_path)
    try:
        import dep_lib_b
        return dep_lib_b
    except ImportError:
        return None

def main():
    print("=" * 60)
    print("  Git Submodules & Subtrees Demo Application")
    print("=" * 60)
    print()

    # --- Dependency A (submodule target) ---
    print("[Dependency A — submodule target: libs/dep-lib-a]")
    dep_a = try_import_submodule_dep()
    if dep_a:
        print(f"  Status  : LOADED")
        print(f"  Version : {dep_a.version()}")
        print(f"  Message : {dep_a.hello()}")
    else:
        print("  Status  : NOT FOUND")
        print("  (Run the Submodule demo to add this dependency)")
    print()

    # --- Dependency B (subtree target) ---
    print("[Dependency B — subtree target: vendor/dep-lib-b]")
    dep_b = try_import_subtree_dep()
    if dep_b:
        print(f"  Status  : LOADED")
        print(f"  Version : {dep_b.version()}")
        print(f"  Message : {dep_b.hello()}")
    else:
        print("  Status  : NOT FOUND")
        print("  (Run the Subtree demo to add this dependency)")
    print()

    print("=" * 60)
    return 0

if __name__ == "__main__":
    sys.exit(main())
