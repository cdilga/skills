#!/usr/bin/env bash
# cdilga/skills installer
# Usage:
#   Install:  curl -fsSL https://raw.githubusercontent.com/cdilga/skills/main/install.sh | bash
#   Update:   curl -fsSL https://raw.githubusercontent.com/cdilga/skills/main/install.sh | bash -s -- --update
#   Or just:  git -C ~/.local/share/cdilga-skills pull

set -euo pipefail

REPO_URL="https://github.com/cdilga/skills.git"
REPO_GITHUB="cdilga/skills"
INSTALL_DIR="$HOME/.local/share/cdilga-skills"
AGENTS_SKILLS="$HOME/.agents/skills"

# ── colours ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
info()    { echo -e "${CYAN}▸${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warn()    { echo -e "${YELLOW}⚠${NC}  $*"; }
header()  { echo -e "\n${BOLD}$*${NC}"; }

header "cdilga/skills installer"

# ── 1. Clone or update ────────────────────────────────────────────────────────
if [[ -d "$INSTALL_DIR/.git" ]]; then
    info "Pulling latest..."
    git -C "$INSTALL_DIR" pull --ff-only --quiet
    success "Updated to $(git -C "$INSTALL_DIR" log --oneline -1)"
else
    info "Cloning $REPO_GITHUB → $INSTALL_DIR"
    git clone --quiet "$REPO_URL" "$INSTALL_DIR"
    success "Cloned"
fi

# Discover skills (bash 3 compatible)
SKILLS_DIR="$INSTALL_DIR/skills"
AVAILABLE_SKILLS=()
while IFS= read -r skill_md; do
    AVAILABLE_SKILLS+=("$(basename "$(dirname "$skill_md")")")
done < <(find "$SKILLS_DIR" -maxdepth 2 -name "SKILL.md" | sort)

header "Skills (${#AVAILABLE_SKILLS[@]})"
for s in "${AVAILABLE_SKILLS[@]}"; do
    desc=$(awk '/^description:/{sub(/^description: /,""); print; exit}' "$SKILLS_DIR/$s/SKILL.md" 2>/dev/null || true)
    echo -e "  ${BOLD}$s${NC}  $desc"
done

# ── 2. Install into ~/.agents/skills (shared hub for all agents) ──────────────
header "Installing to shared hub (~/.agents/skills)"
mkdir -p "$AGENTS_SKILLS"

for skill in "${AVAILABLE_SKILLS[@]}"; do
    target="$AGENTS_SKILLS/$skill"
    source="$SKILLS_DIR/$skill"
    if [[ -L "$target" ]]; then
        ln -sfn "$source" "$target"
        info "Updated symlink: ~/.agents/skills/$skill"
    elif [[ -d "$target" ]]; then
        warn "~/.agents/skills/$skill exists and is not a symlink — skipping (remove manually to replace)"
    else
        ln -s "$source" "$target"
        success "~/.agents/skills/$skill"
    fi
done

# ── 3. Per-agent symlinks (each agent reads from its own dir → ~/.agents/skills) ──
# Relative symlink helper: ln -s <relative-path> <link>
# All agent skill dirs are one level deep (e.g. ~/.cursor/skills/) so relative = ../../.agents/skills/<skill>
# Windsurf is two levels deep (~/.codeium/windsurf/skills/) so relative = ../../../.agents/skills/<skill>

symlink_for_agent() {
    local agent_skills_dir="$1"   # e.g. ~/.cursor/skills
    local rel_prefix="$2"          # e.g. ../../.agents/skills
    local label="$3"

    mkdir -p "$agent_skills_dir"
    local added=0
    for skill in "${AVAILABLE_SKILLS[@]}"; do
        local link="$agent_skills_dir/$skill"
        if [[ -L "$link" ]]; then
            ln -sfn "$rel_prefix/$skill" "$link"
        elif [[ ! -e "$link" ]]; then
            ln -s "$rel_prefix/$skill" "$link"
            (( added++ )) || true
        fi
    done
    success "$label (${#AVAILABLE_SKILLS[@]} skills)"
}

header "Registering with agents"

# Claude Code  (~/.claude/)
symlink_for_agent "$HOME/.claude/skills"           "../../.agents/skills"              "Claude Code (~/.claude/skills)"

# Cursor  (~/.cursor/)
symlink_for_agent "$HOME/.cursor/skills"           "../../.agents/skills"              "Cursor (~/.cursor/skills)"

# Codex  (~/.codex/)
symlink_for_agent "$HOME/.codex/skills"            "../../.agents/skills"              "Codex (~/.codex/skills)"

# Gemini CLI  (~/.gemini/)
symlink_for_agent "$HOME/.gemini/skills"           "../../.agents/skills"              "Gemini CLI (~/.gemini/skills)"

# Windsurf  (~/.codeium/windsurf/)
symlink_for_agent "$HOME/.codeium/windsurf/skills" "../../../.agents/skills"           "Windsurf (~/.codeium/windsurf/skills)"

# Kimi  (~/.kimi/)
symlink_for_agent "$HOME/.kimi/skills"             "../../.agents/skills"              "Kimi (~/.kimi/skills)"

# OpenCode  (~/.config/opencode/skills/)  — also reads ~/.agents/skills natively, but explicit is cleaner
symlink_for_agent "$HOME/.config/opencode/skills"  "../../../.agents/skills"           "OpenCode (~/.config/opencode/skills)"

# GitHub Copilot  (~/.copilot/skills/)
symlink_for_agent "$HOME/.copilot/skills"          "../../.agents/skills"              "Copilot (~/.copilot/skills)"

# ── 4. Claude Code plugin system (marketplace registration) ───────────────────
CLAUDE_PLUGINS="$HOME/.claude/plugins"
if [[ -d "$CLAUDE_PLUGINS" ]]; then
    header "Claude Code plugin system"
    MARKETPLACE_ID="cdilga-skills"
    PLUGIN_NAME="all-skills"

    # known_marketplaces.json
    KM="$CLAUDE_PLUGINS/known_marketplaces.json"
    if [[ -f "$KM" ]]; then
        python3 - "$KM" "$MARKETPLACE_ID" "$REPO_GITHUB" <<'PYEOF'
import json, sys, datetime, os
path, mid, repo = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path) as f: d = json.load(f)
if mid not in d:
    d[mid] = {"source": {"source": "github", "repo": repo},
              "installLocation": f"{os.path.expanduser('~')}/.claude/plugins/marketplaces/{mid}",
              "lastUpdated": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.000Z")}
    with open(path, 'w') as f: json.dump(d, f, indent=4)
PYEOF
    fi

    # Marketplace dir → symlink to live clone
    MP_DIR="$CLAUDE_PLUGINS/marketplaces/$MARKETPLACE_ID"
    if [[ -d "$MP_DIR" && ! -L "$MP_DIR" ]]; then
        mv "$MP_DIR" "${MP_DIR}.bak"
    fi
    [[ -L "$MP_DIR" ]] && ln -sfn "$INSTALL_DIR" "$MP_DIR" || ln -s "$INSTALL_DIR" "$MP_DIR"

    # Cache → symlink so git pull = instant update
    VERSION=$(python3 -c "
import json
try: print(json.load(open('$INSTALL_DIR/.claude-plugin/marketplace.json')).get('version','current'))
except: print('current')
")
    CACHE_DIR="$CLAUDE_PLUGINS/cache/$MARKETPLACE_ID/$PLUGIN_NAME/$VERSION"
    mkdir -p "$(dirname "$CACHE_DIR")"
    if [[ -d "$CACHE_DIR" && ! -L "$CACHE_DIR" ]]; then mv "$CACHE_DIR" "${CACHE_DIR}.bak"; fi
    [[ -L "$CACHE_DIR" ]] && ln -sfn "$INSTALL_DIR" "$CACHE_DIR" || ln -s "$INSTALL_DIR" "$CACHE_DIR"

    # installed_plugins.json
    IP="$CLAUDE_PLUGINS/installed_plugins.json"
    if [[ -f "$IP" ]]; then
        python3 - "$IP" "$PLUGIN_NAME" "$MARKETPLACE_ID" "$CACHE_DIR" "$VERSION" <<'PYEOF'
import json, sys, datetime
path, plugin, marketplace, install_path, version = sys.argv[1:6]
key = f"{plugin}@{marketplace}"
with open(path) as f: d = json.load(f)
d.setdefault("plugins", {})
now = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.000Z")
entry = {"scope": "user", "installPath": install_path, "version": version, "installedAt": now, "lastUpdated": now}
if key not in d["plugins"]: d["plugins"][key] = [entry]
else:
    for e in d["plugins"][key]:
        if e.get("scope") == "user": e.update({"installPath": install_path, "version": version, "lastUpdated": now})
with open(path, 'w') as f: json.dump(d, f, indent=4)
PYEOF
    fi

    # settings.json enabledPlugins
    SETTINGS="$HOME/.claude/settings.json"
    if [[ -f "$SETTINGS" ]]; then
        python3 - "$SETTINGS" "$PLUGIN_NAME" "$MARKETPLACE_ID" <<'PYEOF'
import json, sys
path, plugin_name, marketplace = sys.argv[1:4]
with open(path) as f: d = json.load(f)
d.setdefault("enabledPlugins", {})[f"{plugin_name}@{marketplace}"] = True
with open(path, 'w') as f: json.dump(d, f, indent=4)
PYEOF
    fi
    success "Claude Code plugin system registered"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
header "Done — ${#AVAILABLE_SKILLS[@]} skills from cdilga/skills"
echo ""
echo -e "${BOLD}To update:${NC}  git -C $INSTALL_DIR pull"
echo -e "            (symlinks mean the update is instant across all agents)"
echo ""
echo -e "${BOLD}One-liner update:${NC}"
echo -e "  curl -fsSL https://raw.githubusercontent.com/$REPO_GITHUB/main/install.sh | bash"
