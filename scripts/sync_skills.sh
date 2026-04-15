#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/sync_skills.sh .claude
  ./scripts/sync_skills.sh .agent
  ./scripts/sync_skills.sh .agents

Behavior:
  - Copies <source>/skills to the other two folders' skills directories.
  - Copies <source>/shared to the other two folders' shared directories when present.
  - Normalizes text inside each synced skills/shared directory so references use that folder name:
      .claude/  .agent/  .agents/  -> <current-folder>/
EOF
}

if [[ $# -ne 1 ]]; then
  usage
  exit 1
fi

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

SOURCE="${1%/}"
case "$SOURCE" in
  .claude|.agent|.agents) ;;
  *)
    echo "Error: source must be one of .claude, .agent, .agents" >&2
    usage
    exit 1
    ;;
esac

if [[ ! -d "$SOURCE/skills" ]]; then
  echo "Error: '$SOURCE/skills' does not exist." >&2
  exit 1
fi

ALL_DIRS=(.claude .agent .agents)

copy_subtree() {
  local src="$1"
  local dst="$2"
  local name="$3"

  if [[ ! -d "$src/$name" ]]; then
    return 0
  fi

  mkdir -p "$dst"
  rm -rf "$dst/$name"
  mkdir -p "$dst/$name"

  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete "$src/$name/" "$dst/$name/"
  else
    cp -R "$src/$name/." "$dst/$name/"
  fi
}

normalize_folder_refs() {
  local folder="$1"
  local sync_dir

  for sync_dir in "$folder/skills" "$folder/shared"; do
    [[ -d "$sync_dir" ]] || continue

    if command -v rg >/dev/null 2>&1; then
      while IFS= read -r -d '' file; do
        perl -i -pe "s#\\.(?:claude|agent|agents)/#${folder}/#g" "$file"
      done < <(rg -l -0 '\.(claude|agent|agents)/' "$sync_dir" || true)
    else
      while IFS= read -r file; do
        perl -i -pe "s#\\.(?:claude|agent|agents)/#${folder}/#g" "$file"
      done < <(
        grep -Ilr \
          -e '.claude/' \
          -e '.agent/' \
          -e '.agents/' \
          "$sync_dir" || true
      )
    fi
  done
}

for dir in "${ALL_DIRS[@]}"; do
  if [[ "$dir" != "$SOURCE" ]]; then
    copy_subtree "$SOURCE" "$dir" "skills"
    copy_subtree "$SOURCE" "$dir" "shared"
  fi
done

for dir in "${ALL_DIRS[@]}"; do
  normalize_folder_refs "$dir"
done

echo "Done."
echo "Source: $SOURCE/skills"
if [[ -d "$SOURCE/shared" ]]; then
  echo "Source: $SOURCE/shared"
fi
echo "Synced: .claude/{skills,shared}, .agent/{skills,shared}, .agents/{skills,shared}"
