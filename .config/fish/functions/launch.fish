function launch --description "Launch application out of focus"
    eval "$argv >/dev/null 2>&1 &" & disown
end
