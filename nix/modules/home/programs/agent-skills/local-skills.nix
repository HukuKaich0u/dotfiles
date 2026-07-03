{
  lib,
  ...
}: {
  # NOTE: agent-kit's own skills AND AGENTS.md are NOT distributed from here
  # anymore — they are managed and distributed via APM (~/.apm/apm.yml), which
  # deploys to both ~/.claude/skills/ and ~/.agents/skills/. This module only
  # prepares the ~/.agents/skills/ directory so APM can populate it.
  home.activation.migrateAgentsSkillsDir = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
    mkdir -p "$HOME/.agents"
    if [ -L "$HOME/.agents/skills" ]; then
      rm "$HOME/.agents/skills"
    fi
    mkdir -p "$HOME/.agents/skills"
  '';
}
