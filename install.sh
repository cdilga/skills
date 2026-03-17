#!/usr/bin/env bash
# cdilga/skills installer
# Usage:
#   Install:  curl -fsSL https://raw.githubusercontent.com/cdilga/skills/main/install.sh | bash
#   Update:   curl -fsSL https://raw.githubusercontent.com/cdilga/skills/main/install.sh | bash -s -- --update
#   Or just:  ~/.local/share/cdilga-skills/install.sh --update

set -euo pipefail

REPO_URL="https://github.com/cdilga/skills.git"
REPO_GITHUB="cdilga/skills"
INSTALL_DIR="$HOME/.local/share/cdilga-skills"
MARKETPLACE_ID="cdilga-skills"
PLUGIN_NAME="all-skills"

# ── colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
info()    { echo -e "${CYAN}▸${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warn()    { echo -e "${YELLOW}⚠${NC}  $*"; }
header()  { echo -e "\n${BOLD}$*${NC}"; }

UPDATE_MODE=false
[[ "${1:-}" == "--update" ]] && UPDATE_MODE=true

header "cdilga/skills installer"

# ── Step 1: Clone or update the canonical repo ───────────────────────────────
if [[ -d "$INSTALL_DIR/.git" ]]; then
    info "Pulling latest from $REPO_GITHUB..."
    git -C "$INSTALL_DIR" pull --ff-only --quiet
    success "Updated to $(git -C "$INSTALL_DIR" log --oneline -1)"
else
    info "Cloning $REPO_GITHUB → $INSTALL_DIR"
    git clone --quiet "$REPO_URL" "$INSTALL_DIR"
    success "Cloned"
fi

# Discover available skills (bash 3 compatible — no mapfile)
SKILLS_DIR="$INSTALL_DIR/skills"
AVAILABLE_SKILLS=()
while IFS= read -r skill_md; do
    AVAILABLE_SKILLS+=("$(basename "$(dirname "$skill_md")")")
done < <(find "$SKILLS_DIR" -maxdepth 2 -name "SKILL.md" | sort)

header "Available skills (${#AVAILABLE_SKILLS[@]})"
for s in "${AVAILABLE_SKILLS[@]}"; do
    desc=$(awk '/^description:/{sub(/^description: /,""); print; exit}' "$SKILLS_DIR/$s/SKILL.md" 2>/dev/null || echo "")
    echo -e "  ${BOLD}$s${NC}  ${desc}"
done

# ── Step 2: Claude Code ───────────────────────────────────────────────────────
CLAUDE_PLUGINS="$HOME/.claude/plugins"
if [[ -d "$CLAUDE_PLUGINS" ]]; then
    header "Setting up for Claude Code"

    # 2a. Register marketplace (known_marketplaces.json)
    KM="$CLAUDE_PLUGINS/known_marketplaces.json"
    if [[ -f "$KM" ]]; then
        # Inject entry if not already present
        python3 - "$KM" "$MARKETPLACE_ID" "$REPO_GITHUB" <<'PYEOF'
import json, sys
path, mid, repo = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path) as f:
    d = json.load(f)
if mid not in d:
    import datetime
    d[mid] = {
        "source": {"source": "github", "repo": repo},
        "installLocation": f"{__import__('os').path.expanduser('~')}/.claude/plugins/marketplaces/{mid}",
        "lastUpdated": datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.000Z")
    }
    with open(path, 'w') as f:
        json.dump(d, f, indent=4)
    print("registered")
else:
    print("already registered")
PYEOF
        success "Marketplace registered in known_marketplaces.json"
    fi

    # 2b. Marketplace dir — symlink to our canonical clone (so git pull = instant update)
    MP_DIR="$CLAUDE_PLUGINS/marketplaces/$MARKETPLACE_ID"
    if [[ -L "$MP_DIR" ]]; then
        info "Marketplace symlink already points to: $(readlink "$MP_DIR")"
    elif [[ -d "$MP_DIR" && ! -L "$MP_DIR" ]]; then
        warn "Replacing existing marketplace clone with symlink (backup at ${MP_DIR}.bak)"
        mv "$MP_DIR" "${MP_DIR}.bak"
        ln -s "$INSTALL_DIR" "$MP_DIR"
        success "Symlinked marketplaces/$MARKETPLACE_ID → $INSTALL_DIR"
    else
        ln -s "$INSTALL_DIR" "$MP_DIR"
        success "Symlinked marketplaces/$MARKETPLACE_ID → $INSTALL_DIR"
    fi

    # 2c. Cache entry — symlink so updates are zero-cost
    # Claude Code reads skills from cache/<marketplace>/<plugin>/<version>/
    # We create a "current" version that is a symlink to the live clone.
    VERSION=$(python3 -c "
import json
try:
    d = json.load(open('$INSTALL_DIR/.claude-plugin/marketplace.json'))
    print(d.get('version','current'))
except:
    print('current')
")
    CACHE_DIR="$CLAUDE_PLUGINS/cache/$MARKETPLACE_ID/$PLUGIN_NAME/$VERSION"
    mkdir -p "$(dirname "$CACHE_DIR")"
    if [[ -L "$CACHE_DIR" ]]; then
        # Update symlink target if needed
        ln -sfn "$INSTALL_DIR" "$CACHE_DIR"
        info "Cache symlink updated"
    elif [[ -d "$CACHE_DIR" && ! -L "$CACHE_DIR" ]]; then
        warn "Replacing cache snapshot with symlink (backup at ${CACHE_DIR}.bak)"
        mv "$CACHE_DIR" "${CACHE_DIR}.bak"
        ln -s "$INSTALL_DIR" "$CACHE_DIR"
        success "Cache symlinked → $INSTALL_DIR"
    else
        ln -s "$INSTALL_DIR" "$CACHE_DIR"
        success "Cache entry created: cache/$MARKETPLACE_ID/$PLUGIN_NAME/$VERSION → $INSTALL_DIR"
    fi

    # 2d. installed_plugins.json — register the plugin
    IP="$CLAUDE_PLUGINS/installed_plugins.json"
    if [[ -f "$IP" ]]; then
        python3 - "$IP" "$PLUGIN_NAME" "$MARKETPLACE_ID" "$CACHE_DIR" "$VERSION" <<'PYEOF'
import json, sys, datetime, os
path, plugin, marketplace, install_path, version = sys.argv[1:6]
key = f"{plugin}@{marketplace}"
with open(path) as f:
    d = json.load(f)
d.setdefault("plugins", {})
now = datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.000Z")
if key not in d["plugins"]:
    d["plugins"][key] = [{"scope": "user", "installPath": install_path,
                           "version": version, "installedAt": now, "lastUpdated": now}]
else:
    # Update version/path on existing entry
    for entry in d["plugins"][key]:
        if entry.get("scope") == "user":
            entry["installPath"] = install_path
            entry["version"] = version
            entry["lastUpdated"] = now
with open(path, 'w') as f:
    json.dump(d, f, indent=4)
print("ok")
PYEOF
        success "Registered in installed_plugins.json"
    fi

    # 2e. settings.json — enable all skills
    SETTINGS="$HOME/.claude/settings.json"
    if [[ -f "$SETTINGS" ]]; then
        python3 - "$SETTINGS" "$PLUGIN_NAME" "$MARKETPLACE_ID" <<'PYEOF'
import json, sys
path = sys.argv[1]
plugin_name = sys.argv[2]
marketplace = sys.argv[3]
skills = sys.argv[4:]
with open(path) as f:
    d = json.load(f)
d.setdefault("enabledPlugins", {})
key = f"{plugin_name}@{marketplace}"
d["enabledPlugins"][key] = True
with open(path, 'w') as f:
    json.dump(d, f, indent=4)
print("ok")
PYEOF
        success "Enabled in Claude Code settings"
    fi

    success "Claude Code: done. Skills are live — no restart needed."
    echo -e "   ${CYAN}Update anytime:${NC}  git -C $INSTALL_DIR pull"
    echo -e "   ${CYAN}Or re-run:${NC}       curl -fsSL https://raw.githubusercontent.com/$REPO_GITHUB/main/install.sh | bash -s -- --update"
else
    warn "Claude Code not found (no ~/.claude/plugins). Skipping."
fi

# ── Step 3: OpenCode ──────────────────────────────────────────────────────────
# OpenCode reads agent instructions from AGENTS.md / .opencode/instructions
OPENCODE_DB="$HOME/.local/share/opencode"
if [[ -d "$OPENCODE_DB" ]]; then
    header "OpenCode detected"
    info "OpenCode doesn't have a formal skill system — skills work via AGENTS.md."
    info "Add this to your workspace AGENTS.md to make skills discoverable:"
    echo -e "   ${CYAN}Skills available at: $INSTALL_DIR/skills${NC}"
fi

# ── Step 4: Cursor ────────────────────────────────────────────────────────────
if [[ -d "$HOME/.cursor" || -d "$HOME/Library/Application Support/Cursor" ]]; then
    header "Cursor detected"
    info "Cursor uses .cursor/rules — no native skill system."
    info "Skills are available at: $INSTALL_DIR/skills"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
header "Done"
echo -e "${GREEN}${BOLD}${#AVAILABLE_SKILLS[@]} skills installed from cdilga/skills${NC}"
echo ""
echo -e "${BOLD}To update:${NC}"
echo -e "  git -C $INSTALL_DIR pull"
echo -e "  # That's it — symlinks mean the update is instant."
echo ""
echo -e "${BOLD}Or one-liner update:${NC}"
echo -e "  curl -fsSL https://raw.githubusercontent.com/$REPO_GITHUB/main/install.sh | bash -s -- --update"
