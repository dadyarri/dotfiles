set FNM_PATH "/home/dadyarri/.local/share/fnm"
if [ -d "$FNM_PATH" ]
  set PATH "$FNM_PATH" $PATH
  fnm env --use-on-cd --shell fish | source
end
