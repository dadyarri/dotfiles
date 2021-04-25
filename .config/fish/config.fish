set FISH_CONFIG ~/.config/fish

for file in (ls $FISH_CONFIG/aliases)
    source $FISH_CONFIG/aliases/$file
end
