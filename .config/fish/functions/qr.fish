function qr --description "Generates a QR code and shows it"
  if [ "$argv" = "" ]; then
    qrencode --size 5 --background=FFFFFF --foreground=000000 -o - | display
  else
    printf "$argv" | qrencode --size 5 --background=FFFFFF --foreground=000000 -o - | display
  end
end
