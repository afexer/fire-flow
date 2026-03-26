#!/usr/bin/env bash
# Smoke tests for Dominion Flow plugin structure
# Run: bash tests/smoke.test.sh

PASS=0
FAIL=0
PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

pass() { PASS=$((PASS + 1)); echo "  PASS: $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL: $1"; }

echo "=== Dominion Flow Smoke Tests ==="
echo ""

# 1. Plugin manifest exists and is valid JSON
echo "[Structure]"
test -f "$PLUGIN_ROOT/plugin.json" && pass "plugin.json exists" || fail "plugin.json missing"
node -e "JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'))" "$PLUGIN_ROOT/plugin.json" 2>/dev/null && pass "plugin.json is valid JSON" || fail "plugin.json invalid JSON"

# 2. Commands directory exists and has .md files
CMD_COUNT=$(ls "$PLUGIN_ROOT/commands/"*.md 2>/dev/null | wc -l)
test "$CMD_COUNT" -gt 0 && pass "commands/ has $CMD_COUNT commands" || fail "commands/ empty"

# 3. Agents directory exists and has .md files
AGENT_COUNT=$(ls "$PLUGIN_ROOT/agents/"*.md 2>/dev/null | wc -l)
test "$AGENT_COUNT" -gt 0 && pass "agents/ has $AGENT_COUNT agents" || fail "agents/ empty"

# 4. Skills library exists
test -d "$PLUGIN_ROOT/skills-library" && pass "skills-library/ exists" || fail "skills-library/ missing"

# 5. Hooks directory exists
test -d "$PLUGIN_ROOT/hooks" && pass "hooks/ exists" || fail "hooks/ missing"

# 6. All commands have frontmatter
echo ""
echo "[Command Frontmatter]"
for cmd in "$PLUGIN_ROOT/commands/"*.md; do
  name=$(basename "$cmd")
  head -1 "$cmd" | grep -q "^---" && pass "$name has frontmatter" || fail "$name missing frontmatter"
done

# 7. All agents have frontmatter
echo ""
echo "[Agent Frontmatter]"
for agent in "$PLUGIN_ROOT/agents/"*.md; do
  name=$(basename "$agent")
  head -1 "$agent" | grep -q "^---" && pass "$name has frontmatter" || fail "$name missing frontmatter"
done

# 8. No private paths leaked
echo ""
echo "[Security]"
LEAK_FILES=$(grep -rli \
  "schooloftheprophets\|School of the Prophets\|schooloftheholyspirit\|School of the Holy Spirit\|thierrynakoa\|65\.75\.211\|C:\\\\Users\\\\Thierry\|C:/Users/Thierry\|C:\\\\Users\\\\Thier\|c:\\\\Users\\\\Thier\|ovigezezdnacnhxhtsbx\|jpfrnunodkjplslfouqw\|51KFrTBB\|AVPCNK2OFrV3Wx46\|binamupower\|melchizedekpriests\|mern-community-lms\|student-beautification\|~/mern-app\|mern-app/server\|LMS-SERVER\|lms-server\|Columbia, SC" \
  "$PLUGIN_ROOT" \
  --include="*.md" --include="*.cmd" --include="*.json" --include="*.yml" \
  --include="*.sh" --include="*.ts" --include="*.js" --include="*.py" \
  2>/dev/null | grep -v node_modules | grep -v "\.git" | grep -v smoke.test | grep -v private-data-patterns)
if [ -z "$LEAK_FILES" ]; then
  LEAKS=0
else
  LEAKS=$(printf '%s\n' "$LEAK_FILES" | grep -c .)
fi
test "$LEAKS" -eq 0 && pass "No private paths found" || fail "$LEAKS files with private paths"

# 9. Version consistency
echo ""
echo "[Versions]"
V1=$(node -e "console.log(JSON.parse(require('fs').readFileSync('$PLUGIN_ROOT/plugin.json','utf8')).version)" 2>/dev/null)
V2=$(node -e "console.log(JSON.parse(require('fs').readFileSync('$PLUGIN_ROOT/.claude-plugin/plugin.json','utf8')).version)" 2>/dev/null)
V3=$(node -e "console.log(JSON.parse(require('fs').readFileSync('$PLUGIN_ROOT/version.json','utf8')).version)" 2>/dev/null)
test "$V1" = "$V2" -a "$V2" = "$V3" && pass "All versions match ($V1)" || fail "Version mismatch: plugin=$V1 .claude-plugin=$V2 version=$V3"

# 10. README exists and is non-empty
echo ""
echo "[Docs]"
test -s "$PLUGIN_ROOT/README.md" && pass "README.md exists and non-empty" || fail "README.md missing or empty"
test -s "$PLUGIN_ROOT/COMMAND-REFERENCE.md" && pass "COMMAND-REFERENCE.md exists" || fail "COMMAND-REFERENCE.md missing"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
exit $FAIL
