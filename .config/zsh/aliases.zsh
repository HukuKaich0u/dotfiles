alias gotest='oj t -c "go run main.go" -d tests'
alias gobuild='go build -o main.out main.go'
alias gobintest='ojt -c "main/a.out"'
alias pytest='oj t -c "python3 main.py" -d tests'
alias rstest='oj t -c "rustc main.rs && ./main" -d tests'
alias rsbuild='rustc main.rs'
alias rsbintest='oj t -c "./main" -d tests'

alias nv='nvim'
alias tm='tmux'

# Keep Codex output in normal terminal scrollback so wheel scrolling works in tmux.
alias codex='codex --no-alt-screen'
alias cdx='codex --no-alt-screen'
alias codex-alt='command codex'

alias tmls='tmux list-sessions'
alias tma='tmux a -t'
alias tmnew='tmux new -s'
