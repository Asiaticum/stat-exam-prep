#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./sync_skills.sh .claude
  ./sync_skills.sh .agent
  ./sync_skills.sh .agents

Behavior:
  - Copies <source>/skills to the other two folders' skills directories.
  - Normalizes text inside each skills directory so references use that folder name:
      .claude/  .agent/  .agents/  -> <current-folder>/
EOF
}

if [[ $# -ne 1 ]]; then
  usage
  exit 1
fi

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

copy_skills() {
  local src="$1"
  local dst="$2"
  mkdir -p "$dst"
  rm -rf "$dst/skills"
  mkdir -p "$dst/skills"

  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete "$src/skills/" "$dst/skills/"
  else
    cp -R "$src/skills/." "$dst/skills/"
  fi
}

normalize_folder_refs() {
  local folder="$1"
  local skills_dir="$folder/skills"
  [[ -d "$skills_dir" ]] || return 0

  if command -v rg >/dev/null 2>&1; then
    while IFS= read -r -d '' file; do
      perl -i -pe "s#\\.(?:claude|agent|agents)/#${folder}/#g" "$file"
    done < <(rg -l -0 '\.(claude|agent|agents)/' "$skills_dir" || true)
  else
    while IFS= read -r file; do
      perl -i -pe "s#\\.(?:claude|agent|agents)/#${folder}/#g" "$file"
    done < <(
      grep -Ilr \
        -e '.claude/' \
        -e '.agent/' \
        -e '.agents/' \
        "$skills_dir" || true
    )
  fi
}

for dir in "${ALL_DIRS[@]}"; do
  if [[ "$dir" != "$SOURCE" ]]; then
    copy_skills "$SOURCE" "$dir"
  fi
done

for dir in "${ALL_DIRS[@]}"; do
  normalize_folder_refs "$dir"
done

echo "Done."
echo "Source: $SOURCE/skills"
echo "Synced: .claude/skills, .agent/skills, .agents/skills"
