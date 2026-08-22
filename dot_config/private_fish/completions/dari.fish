# Print an optspec for argparse to handle cmd's options that are independent of any subcommand.
function __fish_dari_global_optspecs
	string join \n h/help V/version
end

function __fish_dari_needs_command
	# Figure out if the current invocation already has a command.
	set -l cmd (commandline -opc)
	set -e cmd[1]
	argparse -s (__fish_dari_global_optspecs) -- $cmd 2>/dev/null
	or return
	if set -q argv[1]
		# Also print the command, so this can be used to figure out what it is.
		echo $argv[1]
		return 1
	end
	return 0
end

function __fish_dari_using_subcommand
	set -l cmd (__fish_dari_needs_command)
	test -z "$cmd"
	and return 1
	contains -- $cmd[1] $argv
end

complete -c dari -n "__fish_dari_needs_command" -s h -l help -d 'Shows help of the command'
complete -c dari -n "__fish_dari_needs_command" -s V -l version -d 'Shows version information'
complete -c dari -n "__fish_dari_needs_command" -f -a "create" -d 'Creates new archive'
complete -c dari -n "__fish_dari_needs_command" -f -a "append" -d 'Appends data to existing archive'
complete -c dari -n "__fish_dari_needs_command" -f -a "inspect" -d 'Interactively inspect the contents of an archive'
complete -c dari -n "__fish_dari_needs_command" -f -a "extract" -d 'Extracts files from an archive'
complete -c dari -n "__fish_dari_needs_command" -f -a "list" -d 'Lists the contents of an archive'
complete -c dari -n "__fish_dari_needs_command" -f -a "encrypt" -d 'Encrypts an existing unencrypted archive'
complete -c dari -n "__fish_dari_needs_command" -f -a "completions" -d 'Generates shell completion script and writes it to stdout'
complete -c dari -n "__fish_dari_using_subcommand create" -s f -l file -d 'The path to the resulting archive file' -r
complete -c dari -n "__fish_dari_using_subcommand create" -l encrypt-passphrase -d 'Encrypt file data using the provided passphrase argument' -r
complete -c dari -n "__fish_dari_using_subcommand create" -s o -l overwrite -d 'Overwrite existing archive file'
complete -c dari -n "__fish_dari_using_subcommand create" -l compress-images -d 'Losslessly optimize PNG/JPEG using image-specific codecs'
complete -c dari -n "__fish_dari_using_subcommand create" -l encrypt -d 'Prompt for passphrase interactively to encrypt file data'
complete -c dari -n "__fish_dari_using_subcommand create" -s v -l verbose -d 'Enables verbose output'
complete -c dari -n "__fish_dari_using_subcommand create" -l dry-run -d 'Preview which files would be added without writing the archive'
complete -c dari -n "__fish_dari_using_subcommand create" -s h -l help -d 'Shows help of the command'
complete -c dari -n "__fish_dari_using_subcommand append" -s f -l file -d 'The path to the existing archive file' -r
complete -c dari -n "__fish_dari_using_subcommand append" -l encrypt-passphrase -d 'Encrypt appended file data using the provided passphrase argument' -r
complete -c dari -n "__fish_dari_using_subcommand append" -l on-conflict -d 'How to handle archive-relative path conflicts with existing entries: error (default), rename, overwrite' -r -f -a "error\t''
rename\t''
overwrite\t''"
complete -c dari -n "__fish_dari_using_subcommand append" -l compress-images -d 'Losslessly optimize PNG/JPEG using image-specific codecs'
complete -c dari -n "__fish_dari_using_subcommand append" -l encrypt -d 'Prompt for passphrase interactively to encrypt appended file data'
complete -c dari -n "__fish_dari_using_subcommand append" -s v -l verbose -d 'Enables verbose output'
complete -c dari -n "__fish_dari_using_subcommand append" -l dry-run -d 'Preview which files would be added without modifying the archive'
complete -c dari -n "__fish_dari_using_subcommand append" -s h -l help -d 'Shows help of the command'
complete -c dari -n "__fish_dari_using_subcommand inspect" -s f -l file -d 'The path to the archive file to inspect' -r
complete -c dari -n "__fish_dari_using_subcommand inspect" -l encrypt-passphrase -d 'Passphrase for decrypting entries in an encrypted archive' -r
complete -c dari -n "__fish_dari_using_subcommand inspect" -s h -l help -d 'Shows help of the command'
complete -c dari -n "__fish_dari_using_subcommand extract" -s f -l file -d 'The path to the archive file to extract from' -r
complete -c dari -n "__fish_dari_using_subcommand extract" -s d -l output-dir -d 'Directory to extract files into (defaults to current directory)' -r
complete -c dari -n "__fish_dari_using_subcommand extract" -l encrypt-passphrase -d 'Passphrase for decrypting entries in an encrypted archive' -r
complete -c dari -n "__fish_dari_using_subcommand extract" -s h -l help -d 'Shows help of the command'
complete -c dari -n "__fish_dari_using_subcommand list" -s f -l file -d 'The path to the archive file' -r
complete -c dari -n "__fish_dari_using_subcommand list" -l json -d 'Output in JSON format'
complete -c dari -n "__fish_dari_using_subcommand list" -s h -l help -d 'Shows help of the command'
complete -c dari -n "__fish_dari_using_subcommand encrypt" -s f -l file -d 'The path to the archive file to encrypt' -r
complete -c dari -n "__fish_dari_using_subcommand encrypt" -l encrypt-passphrase -d 'Encrypt using the provided passphrase argument' -r
complete -c dari -n "__fish_dari_using_subcommand encrypt" -l encrypt -d 'Prompt for passphrase interactively'
complete -c dari -n "__fish_dari_using_subcommand encrypt" -s h -l help -d 'Shows help of the command'
complete -c dari -n "__fish_dari_using_subcommand completions" -s h -l help -d 'Shows help of the command'
