{
  lib,
  ...
}: {
  # APM (~/.apm/apm.yml) が skill を配布する先のディレクトリを事前に用意する。
  # 旧構成の dirlink (symlink) が残っていると APM や home.file の展開と衝突する
  # ため、activation で実ディレクトリへ移行する。
  home.activation.prepareSkillDirs = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
    for skills_dir in "$HOME/.claude/skills" "$HOME/.agents/skills"; do
      mkdir -p "$(dirname "$skills_dir")"
      if [ -L "$skills_dir" ]; then
        rm "$skills_dir"
      fi
      mkdir -p "$skills_dir"
    done
    rm -f "$HOME/.claude/skills.dirlink.backup"
  '';
}
