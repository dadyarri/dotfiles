_mkcd_help() {
    echo "Little wrapper to create a directory and change into it."
    echo
    echo "Syntax: mkcd [options] dir"
    echo
    echo "Options:"
    echo "-h, --help Prints this help and exits."
    echo "Arguments:"
    echo "dir        Directory to create and change to it."
    echo
}

mkcd() {
    for i in "$@"; do
        case $i in
            -h|--help)
                _mkcd_help
                shift
                ;;
            *)
                mkdir $1
                cd $1
            ;;
        esac
    done
}

