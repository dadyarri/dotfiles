set FISH_CONFIG ~/.config/fish
set PATH "(/home/dadyarri/scripts/get-path 2>&1):$PATH"

for file in (ls $FISH_CONFIG/aliases)
    source $FISH_CONFIG/aliases/$file
end
