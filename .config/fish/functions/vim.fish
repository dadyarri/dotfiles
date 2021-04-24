function vim --description "Runs vim with or without sudo rights"
  if test -w $argv
    /usr/bin/vim $argv
  else
    sudo /usr/bin/vim $argv
  end
end
