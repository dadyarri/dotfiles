function bak --description "Move files to .bak"
  mv "$argv" "(basename $argv).bak"
end
