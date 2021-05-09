set FISH_CONFIG ~/.config/fish
set EDITOR nvim
set XDG_DATA_DIRS /home/dadyarri/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share 


for file in (ls $FISH_CONFIG/aliases)
    source $FISH_CONFIG/aliases/$file
end
