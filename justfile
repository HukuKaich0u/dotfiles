# dotfiles task runner
#
# Recipe list: `just` (= `just --list`)

export APM_COPILOT_COWORK_SKILLS_DIR := env_var_or_default("APM_COPILOT_COWORK_SKILLS_DIR", env_var("HOME") + "/.local/share/copilot-cowork/skills")

# Prefix shared by every agent-kit skill package, so apm-add / apm-rm can take
# a short path like `tooling/justfile` instead of the full package name.
AGENT_KIT_SKILLS := "HukuKaich0u/agent-kit/skills"

_default:
    @just --list

# Install global APM dependencies from ~/.apm/apm.yml and compile root contexts
apm-install:
    apm install -g
    apm compile -g

# Update global APM dependencies to their latest refs and compile root contexts
apm-update:
    apm update -g --yes
    apm compile -g

# Add a global agent-kit skill, e.g. `just apm-add tooling/justfile`
apm-add skill:
    # apm edits ~/.apm/apm.yml itself. Never hand-edit that manifest: editing
    # it alone leaves the skill undeployed.
    apm install -g {{ AGENT_KIT_SKILLS }}/{{ skill }}
    apm compile -g

# Remove a global agent-kit skill, e.g. `just apm-rm tooling/justfile`
apm-rm skill:
    # `apm uninstall` is the only thing that removes a dependency: it drops the
    # apm.yml entry, the apm_modules/ copy, and the deployed skill together.
    # `apm update` removes nothing, and `apm prune` mis-detects the instructions
    # package as orphaned — do not reach for either one here.
    apm uninstall -g {{ AGENT_KIT_SKILLS }}/{{ skill }}
    apm compile -g
