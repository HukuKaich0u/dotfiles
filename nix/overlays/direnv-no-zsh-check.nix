final: prev: {
  direnv = prev.direnv.overrideAttrs (_old: {
    # direnv's upstream zsh integration test hangs in this darwin build path.
    checkPhase = ''
      runHook preCheck

      make test-go test-bash test-fish
      echo "Skipping direnv test-zsh during nix build on darwin"

      runHook postCheck
    '';
  });
}
