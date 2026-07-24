# dotfiles task runner
#
# Recipe list: `just` (= `just --list`)

export APM_COPILOT_COWORK_SKILLS_DIR := env_var_or_default("APM_COPILOT_COWORK_SKILLS_DIR", env_var("HOME") + "/.local/share/copilot-cowork/skills")

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
