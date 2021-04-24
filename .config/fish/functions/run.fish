function run --description "Makes a script executable and run it"
  chmod +x "$argv"
  exec "./$argv" &
end
