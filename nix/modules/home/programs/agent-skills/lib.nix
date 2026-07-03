# Recursive skill discovery used by external/superpowers.nix.
#
# A "leaf skill" is any directory that directly contains a SKILL.md.
# Categories (lang/, meta/, tooling/) and collections (superpowers/) are just
# intermediate directories we recurse through, so the same logic flattens any
# nesting depth without per-layer special-casing.
{lib}: let
  # Recurse under `dir`, accumulating leaf skills.
  # `dir` is a path value (e.g. ../../../../../.agents/skills) used for
  # builtins.readDir / builtins.pathExists.
  # `rel` is the slash-joined path from the original base ("" at the root).
  # Returns a list of { name; relPath; } where:
  #   name    = leaf directory's own name (used for flat Claude links)
  #   relPath = path from the base to the leaf (used for structured Codex links)
  go = dir: rel:
    lib.concatMap
    (
      entryName: let
        entryPath = dir + "/${entryName}";
        entryRel =
          if rel == ""
          then entryName
          else "${rel}/${entryName}";
        isDir = (builtins.readDir dir).${entryName} == "directory";
        isLeaf = builtins.pathExists (entryPath + "/SKILL.md");
      in
        if !isDir
        then []
        else if isLeaf
        then [
          {
            name = entryName;
            relPath = entryRel;
          }
        ]
        else go entryPath entryRel
    )
    (builtins.attrNames (builtins.readDir dir));
in {
  # Public: collect all leaf skills under `baseDir`.
  leaves = baseDir: go baseDir "";
}
