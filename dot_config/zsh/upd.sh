_upd_help() {
    echo "Little wrapper to update entire system."
    echo
    echo "Syntax: upd"
}

upd() {
    for i in "$@"; do
        case $i in
            -h|--help)
              _upd_help
              shift
              ;;
            *)
                echo "Updating system started..."
                echo "Password required"
                echo
                echo -n "Enter sudo password: "
                read -r -s password
                echo
                echo "Updating packages..."
                echo $password | sudo -S dnf update -y
                echo "Packages updated."
                echo
                echo "Removing orphans..."
                echo $password | sudo -S dnf autoremove -y
                echo "Orphans removed."
                echo
                echo "Updating flatpak apps..."
                flatpak update
                echo "Flatpak apps updated."
                echo
                echo "System updated."
                ;;
        esac
    done
}