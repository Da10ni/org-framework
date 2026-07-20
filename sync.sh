#!/usr/bin/env bash
#
# sync.sh — vendors org-framework into a consumer repo's .framework/ folder.
#
# Implementation note (flagged, not yet formally re-confirmed per the
# handoff's open item): this is written as a POSIX-compatible bash
# script, since that's the default assumption for a repo-management
# script and requires no extra runtime beyond git + bash. If the team
# needs first-class Windows support without WSL/Git Bash, a .js (Node)
# or .py (Python) equivalent implementing the same four steps below
# (fetch → strip .git → copy into .framework/ → stamp VERSION) is a
# straightforward port — ask if you want that variant generated
# instead of, or alongside, this one.
#
# Usage:
#   ./sync.sh [--repo <git-url>] [--branch <branch>] [--ref <commit-sha>] [--yes]
#
#   --repo    Git URL of the central org-framework repo.
#             Defaults to $ORG_FRAMEWORK_REPO if set.
#   --branch  Branch to sync from. Defaults to "main".
#   --ref     Exact commit SHA to pin to, instead of a branch's latest.
#             If set, takes priority over --branch.
#   --yes     Skip the overwrite confirmation prompt (for CI use).
#
# What it does:
#   1. Fetches the central org-framework repo at the requested
#      branch/ref into a temporary directory.
#   2. Strips the fetched copy's own .git history — the consumer repo
#      tracks .framework/ as plain committed files, not as a nested
#      git repo or submodule.
#   3. Replaces this repo's .framework/ directory with the fetched
#      contents.
#   4. Writes .framework/VERSION with the exact commit SHA and the
#      sync timestamp, for traceability.
#
# This script does NOT commit the result — review the diff under
# .framework/ and commit it yourself, the same as any other change.

set -euo pipefail

# ---- Defaults -----------------------------------------------------------

REPO_URL="${ORG_FRAMEWORK_REPO:-}"
BRANCH="main"
REF=""
ASSUME_YES="false"
TARGET_DIR=".framework"

# ---- Argument parsing ----------------------------------------------------

usage() {
  sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO_URL="$2"
      shift 2
      ;;
    --branch)
      BRANCH="$2"
      shift 2
      ;;
    --ref)
      REF="$2"
      shift 2
      ;;
    --yes|-y)
      ASSUME_YES="true"
      shift
      ;;
    -h|--help)
      usage 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage 1
      ;;
  esac
done

if [[ -z "$REPO_URL" ]]; then
  echo "Error: no repo URL given." >&2
  echo "Pass --repo <git-url>, or set \$ORG_FRAMEWORK_REPO." >&2
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "Error: git is required and was not found on PATH." >&2
  exit 1
fi

# ---- Confirm we're at a repo root, not buried in a subdirectory --------

if [[ ! -d ".git" ]]; then
  echo "Warning: no .git directory found in the current working" >&2
  echo "directory. sync.sh should normally be run from the root of" >&2
  echo "the consumer repo." >&2
  if [[ "$ASSUME_YES" != "true" ]]; then
    read -r -p "Continue anyway? [y/N] " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
  fi
fi

# ---- Overwrite confirmation ---------------------------------------------

if [[ -d "$TARGET_DIR" && "$ASSUME_YES" != "true" ]]; then
  echo "This will replace the existing contents of '$TARGET_DIR/' with"
  echo "a fresh copy from the central framework repo."
  read -r -p "Continue? [y/N] " confirm
  [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
fi

# ---- Fetch into a temp directory ----------------------------------------

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Fetching framework from: $REPO_URL"

if [[ -n "$REF" ]]; then
  echo "Pinning to commit: $REF"
  git clone --quiet "$REPO_URL" "$TMP_DIR"
  git -C "$TMP_DIR" checkout --quiet "$REF"
else
  echo "Using branch: $BRANCH"
  git clone --quiet --depth 1 --branch "$BRANCH" "$REPO_URL" "$TMP_DIR"
fi

SYNCED_SHA="$(git -C "$TMP_DIR" rev-parse HEAD)"
SYNCED_SHORT_SHA="$(git -C "$TMP_DIR" rev-parse --short HEAD)"

# Strip the fetched copy's own git history — it's vendored as plain
# files in the consumer repo, never as a nested repo.
rm -rf "$TMP_DIR/.git"

# If the source repo declares its own version (e.g. a top-level
# VERSION or a tag), surface it; otherwise fall back to "unversioned".
SOURCE_VERSION="unversioned"
if [[ -f "$TMP_DIR/VERSION" ]]; then
  SOURCE_VERSION="$(head -n 1 "$TMP_DIR/VERSION")"
fi

# ---- Replace .framework/ -------------------------------------------------

rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"
cp -R "$TMP_DIR"/. "$TARGET_DIR"/

# ---- Stamp VERSION --------------------------------------------------------

SYNC_TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

cat > "$TARGET_DIR/VERSION" <<EOF
framework@${SOURCE_VERSION} (commit ${SYNCED_SHA}, synced ${SYNC_TIMESTAMP})
EOF

# ---- Instantiate CLAUDE.md at repo root on first sync only --------------
#
# CLAUDE.md is the thin root pointer file an agent session reads FIRST,
# before .framework/AGENT.md. It must exist at the consumer repo root
# (never inside .framework/), and must never be silently overwritten on
# a resync, since a project may have appended project-specific notes
# below the marker line in templates/CLAUDE.template.md.

CLAUDE_INSTANTIATED="false"
if [[ ! -f "CLAUDE.md" ]]; then
  if [[ -f "$TARGET_DIR/templates/CLAUDE.template.md" ]]; then
    cp "$TARGET_DIR/templates/CLAUDE.template.md" "CLAUDE.md"
    CLAUDE_INSTANTIATED="true"
  fi
fi

# ---- Auto-detect stack from project files --------------------------------
#
# Implements AGENT.md Section 4.2: detect first, declared block as fallback.
# Used to pre-fill the stack: block in PROJECT_KNOWLEDGE.md on first sync.

detect_stack() {
  local frontend="none"
  local backend="none"
  local database="none"
  local infra="none"
  local layout="N/A"

  # Frontend detection — check root package.json first, then common subfolder names.
  # Subfolder scan covers the common monorepo pattern where the frontend lives in
  # frontend/, client/, web/, or app/ with its own package.json separate from the
  # root (which may belong to the backend or to tooling only).
  # If root package.json exists but contains no known frontend framework, we fall
  # through to subfolders before giving up — a root package.json that is just
  # tooling/orchestration should not block detection of a real frontend below it.
  local frontend_pkg=""

  _detect_frontend_from_pkg() {
    local pkg="$1"
    if grep -q '"react"' "$pkg" 2>/dev/null; then
      frontend="react"; return 0
    elif grep -q '"vue"' "$pkg" 2>/dev/null; then
      frontend="vue"; return 0
    elif grep -q '"next"' "$pkg" 2>/dev/null; then
      frontend="nextjs"; return 0
    elif grep -q '"angular"' "$pkg" 2>/dev/null; then
      frontend="angular"; return 0
    elif grep -q '"svelte"' "$pkg" 2>/dev/null; then
      frontend="svelte"; return 0
    fi
    return 1  # no known framework found
  }

  if [[ -f "package.json" ]]; then
    frontend_pkg="package.json"
    if ! _detect_frontend_from_pkg "package.json"; then
      # Root package.json has no known framework — check subfolders before
      # falling back to plain node-js
      for subdir in frontend client web app; do
        if [[ -f "$subdir/package.json" ]]; then
          if _detect_frontend_from_pkg "$subdir/package.json"; then
            frontend_pkg="$subdir/package.json"
            break
          fi
        fi
      done
      # If still no framework found anywhere, root package.json = node-js
      if [[ "$frontend" == "none" ]]; then
        frontend="node-js"
      fi
    fi
  else
    # No root package.json — check subfolders directly
    for subdir in frontend client web app; do
      if [[ -f "$subdir/package.json" ]]; then
        if _detect_frontend_from_pkg "$subdir/package.json"; then
          frontend_pkg="$subdir/package.json"
          break
        fi
      fi
    done
  fi

  # Backend conflict detection — count how many distinct backend markers are
  # present at root level. If more than one is found, we must ask rather than
  # silently picking one. package.json is excluded from this count because it
  # is legitimately present alongside any backend in a fullstack/monorepo setup
  # (it handles the frontend or tooling layer, not the backend). The conflict
  # guard is for cases where two genuine backend markers coexist — e.g. both
  # pom.xml (Java) and requirements.txt (Python) at root simultaneously.
  local backend_marker_count=0
  [[ -f "pom.xml" ]] && ((backend_marker_count++))
  [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]] && ((backend_marker_count++))
  [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]] && ((backend_marker_count++))
  [[ -f "go.mod" ]] && ((backend_marker_count++))
  [[ -f "Cargo.toml" ]] && ((backend_marker_count++))
  [[ -f "Gemfile" ]] && ((backend_marker_count++))

  if [[ "$backend_marker_count" -gt 1 ]]; then
    # Emit a special value the caller checks for — do not guess
    echo "frontend=$frontend"
    echo "backend=AMBIGUOUS"
    echo "database=$database"
    echo "infra=$infra"
    echo "layout=$layout"
    return
  fi

  # Backend detection — separate from frontend (may overlap in fullstack)
  if [[ -f "pom.xml" ]]; then
    if grep -q "spring-boot" pom.xml 2>/dev/null; then
      backend="java-spring-boot"
    else
      backend="java-maven"
    fi
  elif [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; then
    backend="java-gradle"
  elif [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]]; then
    if grep -qE "fastapi|FastAPI" requirements.txt pyproject.toml 2>/dev/null; then
      backend="python-fastapi"
    elif grep -qE "django|Django" requirements.txt pyproject.toml 2>/dev/null; then
      backend="python-django"
      layout="Django-style app layout"
    elif grep -qE "flask|Flask" requirements.txt pyproject.toml 2>/dev/null; then
      backend="python-flask"
    else
      backend="python"
    fi
  elif [[ -f "go.mod" ]]; then
    backend="go"
  elif [[ -f "Cargo.toml" ]]; then
    backend="rust"
  elif [[ -f "Gemfile" ]]; then
    if grep -q "rails" Gemfile 2>/dev/null; then
      backend="ruby-on-rails"
    else
      backend="ruby"
    fi
  elif [[ -f "*.csproj" ]] || ls *.csproj 2>/dev/null | grep -q .; then
    backend="dotnet"
  fi

  # Express check — always checks root package.json specifically, not frontend_pkg.
  # frontend_pkg may point to a subfolder (frontend/, client/ etc.) which won't
  # have express even in a fullstack monorepo — express lives at root or in
  # backend/, not in the frontend subfolder.
  if [[ "$backend" == "none" ]] || [[ "$backend" == "node-js" ]]; then
    if [[ -f "package.json" ]] && grep -q '"express"' "package.json" 2>/dev/null; then
      backend="node-express"
    elif [[ -n "$frontend_pkg" ]] && [[ "$frontend_pkg" != "package.json" ]]; then
      # frontend_pkg is a subfolder — backend stays node-js (no express at root)
      :
    elif [[ -n "$frontend_pkg" ]]; then
      backend="node-js"
    fi
  fi

  # Backend subfolder scan — runs only when root-level detection found nothing.
  # Covers the common monorepo pattern where the backend lives in backend/,
  # server/, or api/ with its own marker files separate from the root.
  # Purely additive: root-level detection is unchanged, this is a fallback only.
  if [[ "$backend" == "none" ]] || [[ "$backend" == "node-js" ]]; then
    for subdir in backend server api; do
      if [[ -f "$subdir/pom.xml" ]]; then
        if grep -q "spring-boot" "$subdir/pom.xml" 2>/dev/null; then
          backend="java-spring-boot"
        else
          backend="java-maven"
        fi
        break
      elif [[ -f "$subdir/build.gradle" ]] || [[ -f "$subdir/build.gradle.kts" ]]; then
        backend="java-gradle"
        break
      elif [[ -f "$subdir/requirements.txt" ]] || [[ -f "$subdir/pyproject.toml" ]]; then
        if grep -qE "fastapi|FastAPI" "$subdir/requirements.txt" "$subdir/pyproject.toml" 2>/dev/null; then
          backend="python-fastapi"
        elif grep -qE "django|Django" "$subdir/requirements.txt" "$subdir/pyproject.toml" 2>/dev/null; then
          backend="python-django"
          layout="Django-style app layout"
        elif grep -qE "flask|Flask" "$subdir/requirements.txt" "$subdir/pyproject.toml" 2>/dev/null; then
          backend="python-flask"
        else
          backend="python"
        fi
        break
      elif [[ -f "$subdir/go.mod" ]]; then
        backend="go"
        break
      elif [[ -f "$subdir/Cargo.toml" ]]; then
        backend="rust"
        break
      elif [[ -f "$subdir/Gemfile" ]]; then
        if grep -q "rails" "$subdir/Gemfile" 2>/dev/null; then
          backend="ruby-on-rails"
        else
          backend="ruby"
        fi
        break
      elif [[ -f "$subdir/package.json" ]]; then
        if grep -q '"express"' "$subdir/package.json" 2>/dev/null; then
          backend="node-express"
        fi
        break
      fi
    done
  fi

  # Database hints from common config files / dependency names
  if grep -qE "postgres|postgresql" requirements.txt pyproject.toml pom.xml package.json go.mod Cargo.toml Gemfile 2>/dev/null; then
    database="postgres"
  elif grep -qE "mysql|mariadb" requirements.txt pyproject.toml pom.xml package.json go.mod Cargo.toml Gemfile 2>/dev/null; then
    database="mysql"
  elif grep -qE "mongo|pymongo" requirements.txt pyproject.toml pom.xml package.json go.mod Cargo.toml Gemfile 2>/dev/null; then
    database="mongodb"
  elif grep -qE "redis" requirements.txt pyproject.toml pom.xml package.json go.mod Cargo.toml Gemfile 2>/dev/null; then
    database="redis"
  elif grep -qE "sqlite" requirements.txt pyproject.toml pom.xml package.json go.mod Cargo.toml Gemfile 2>/dev/null; then
    database="sqlite"
  fi

  # Infra hints
  if [[ -f "Dockerfile" ]] || [[ -f "docker-compose.yml" ]]; then
    infra="docker"
  fi
  if [[ -f "serverless.yml" ]] || [[ -f "serverless.yaml" ]]; then
    infra="serverless"
  fi
  if [[ -f ".vercel" ]] || [[ -f "vercel.json" ]]; then
    infra="vercel"
  fi
  if [[ -f "fly.toml" ]]; then
    infra="fly-io"
  fi

  # Emit as key=value pairs for the caller to consume
  echo "frontend=$frontend"
  echo "backend=$backend"
  echo "database=$database"
  echo "infra=$infra"
  echo "layout=$layout"
}

# ---- Instantiate PROJECT_KNOWLEDGE.md and DECISIONS.md on first sync -----
#
# Like CLAUDE.md, these are only written on first sync — never overwritten —
# since a project may have filled in content. On first sync, we pre-fill
# the stack: block using auto-detection so the file isn't left with bare
# placeholders.

PK_INSTANTIATED="false"
PK_AMBIGUOUS="false"
DECISIONS_INSTANTIATED="false"

if [[ ! -f "PROJECT_KNOWLEDGE.md" ]]; then
  if [[ -f "$TARGET_DIR/templates/PROJECT_KNOWLEDGE.template.md" ]]; then

    # Run detection and capture results into simple variables.
    # Using plain variables instead of declare -A associative arrays because
    # Git Bash on Windows ships bash 4.x where declare -A can be unreliable
    # depending on the build — plain variables work everywhere.
    _raw=""
    _raw="$(detect_stack)"
    _frontend="" _backend="" _database="" _infra="" _layout=""
    _frontend="$(echo "$_raw" | grep '^frontend=' | cut -d= -f2)"
    _backend="$(echo "$_raw"  | grep '^backend='  | cut -d= -f2)"
    _database="$(echo "$_raw" | grep '^database=' | cut -d= -f2)"
    _infra="$(echo "$_raw"    | grep '^infra='    | cut -d= -f2)"
    _layout="$(echo "$_raw"   | grep '^layout='   | cut -d= -f2)"

    # Defaults
    _frontend="${_frontend:-none}"
    _backend="${_backend:-none}"
    _database="${_database:-none}"
    _infra="${_infra:-unknown}"
    _layout="${_layout:-N/A}"

    # If detection found conflicting backend markers, do not guess — copy the
    # template as-is with placeholders intact so the developer fills it in,
    # and print a clear warning below.
    if [[ "$_backend" == "AMBIGUOUS" ]]; then
      cp "$TARGET_DIR/templates/PROJECT_KNOWLEDGE.template.md" "PROJECT_KNOWLEDGE.md"
      PK_INSTANTIATED="true"
      PK_AMBIGUOUS="true"
    else
      sed \
        -e "s@\[e\.g\. react-18 | vue-3 | none\]@${_frontend}@g" \
        -e "s@\[e\.g\. python-fastapi | node-express | java-spring-boot | none\]@${_backend}@g" \
        -e "s@\[e\.g\. postgres-15 | mongodb | none\]@${_database}@g" \
        -e "s@\[e\.g\. aws-ecs | vercel | self-hosted-docker\]@${_infra}@g" \
        -e "s@\[e\.g\. \"Django-style app layout\" | \"FastAPI-style routers\" | \"N/A\"\]@${_layout}@g" \
        "$TARGET_DIR/templates/PROJECT_KNOWLEDGE.template.md" > "PROJECT_KNOWLEDGE.md"
      PK_INSTANTIATED="true"
    fi
  fi
fi

if [[ ! -f "DECISIONS.md" ]]; then
  if [[ -f "$TARGET_DIR/templates/DECISIONS.template.md" ]]; then
    cp "$TARGET_DIR/templates/DECISIONS.template.md" "DECISIONS.md"
    DECISIONS_INSTANTIATED="true"
  fi
fi

# ---- Create .claude/commands/ native slash commands (parallel to .framework/commands/) ----
#
# Implements the native CLI slash command layer. .framework/commands/ remains
# unchanged as the source of truth. These are thin wrappers so Claude Code's
# native slash-command picker (the / menu in VS Code extension and terminal)
# discovers the same commands without requiring any tool to read .framework/.
#
# Per AGENT.md Section 5 research: .claude/commands/ is the correct project-
# scoped location. Filename → command name. YAML frontmatter is optional but
# used for description. $ARGUMENTS is available for arguments.

CLAUDE_COMMANDS_CREATED="false"
if [[ -d "$TARGET_DIR/commands" ]]; then
  mkdir -p ".claude/commands"
  for CMD_FILE in "$TARGET_DIR/commands/"*.md; do
    CMD_NAME="$(basename "$CMD_FILE" .md)"
    NATIVE_FILE=".claude/commands/${CMD_NAME}.md"
    # Only create; never overwrite — project may have customized a wrapper
    if [[ ! -f "$NATIVE_FILE" ]]; then
      cat > "$NATIVE_FILE" <<EOF
---
description: org-framework ${CMD_NAME} command — delegates to .framework/commands/${CMD_NAME}.md
---

Read and execute the instructions in \`.framework/commands/${CMD_NAME}.md\`, then proceed as directed there.
\$ARGUMENTS
EOF
      CLAUDE_COMMANDS_CREATED="true"
    fi
  done
fi

echo ""
echo "Synced org-framework into ${TARGET_DIR}/"
echo "  Source:  ${REPO_URL}"
echo "  Ref:     ${SYNCED_SHORT_SHA}"
echo "  Synced:  ${SYNC_TIMESTAMP}"
echo ""

if [[ "$CLAUDE_INSTANTIATED" == "true" ]]; then
  echo "Created CLAUDE.md at the repo root (first sync) — review it before committing."
fi

if [[ "$PK_INSTANTIATED" == "true" ]]; then
  if [[ "$PK_AMBIGUOUS" == "true" ]]; then
    echo "WARNING: Multiple conflicting backend markers found at repo root."
    echo "  Detection found more than one of: pom.xml, build.gradle, requirements.txt,"
    echo "  pyproject.toml, go.mod, Cargo.toml, Gemfile."
    echo "  Stack detection cannot safely pick one — PROJECT_KNOWLEDGE.md was created"
    echo "  with blank placeholders. Fill in the stack: block manually before the"
    echo "  first agent session, or the agent will offer to detect and fill it then."
  else
    echo "Created PROJECT_KNOWLEDGE.md with auto-detected stack (first sync) — review and adjust before committing."
    echo "  Detected: frontend=${_frontend} | backend=${_backend} | database=${_database} | infra=${_infra}"
  fi
fi

if [[ "$DECISIONS_INSTANTIATED" == "true" ]]; then
  echo "Created DECISIONS.md from template (first sync)."
fi

if [[ "$CLAUDE_COMMANDS_CREATED" == "true" ]]; then
  echo "Created .claude/commands/ native slash command wrappers — commit alongside .framework/."
fi

echo ""
echo "Next steps:"
echo "  1. Review the diff under ${TARGET_DIR}/ (git diff -- ${TARGET_DIR})."
if [[ "$PK_INSTANTIATED" == "true" ]]; then
  echo "  2. Review auto-detected stack in PROJECT_KNOWLEDGE.md and add any version pins"
  echo "     or layout conventions that file detection can't express."
else
  echo "  2. If PROJECT_KNOWLEDGE.md exists but has a missing/blank stack: block, fill it"
  echo "     in — or let the agent auto-detect and offer to fill it at next session start."
fi
echo "  3. Commit ${TARGET_DIR}/, CLAUDE.md, PROJECT_KNOWLEDGE.md, DECISIONS.md, and"
echo "     .claude/commands/ together — none of these are gitignored."
