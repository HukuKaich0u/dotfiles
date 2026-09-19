{lib, pkgs, ...}: let
  source = ../../../../agents/instructions;
  names = builtins.attrNames (lib.filterAttrs
    (name: kind: kind == "regular" && lib.hasSuffix ".md" name)
    (builtins.readDir source));
  rendered = pkgs.runCommand "agent-instructions" {
    nativeBuildInputs = [pkgs.python3];
  } ''
    python3 ${../../../../scripts/common/render-agent-instructions.py} ${source} "$out"
  '';
in {
  home.file = {
    ".codex/AGENTS.md".source = "${rendered}/.codex/AGENTS.md";
  } // builtins.listToAttrs (map (name: {
    name = ".claude/rules/${name}";
    value.source = "${rendered}/.claude/rules/${name}";
  }) names);
}
