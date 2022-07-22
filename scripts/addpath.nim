import os
import argparse

var p = newParser:
    help("{prog}: Simple utility to add directories to file, which later is used for constructing $PATH.")
    arg("path", help="Path to directory to add to file. Ignored, if doesn't exist. Could be relative, then will be converted to absolute")
    option("-o", "--output", help="File to write path to.", default=some("~/.paths"))
    flag("-v", "--verbose", help="Show more verbose output")

try:
    let opts = p.parse(commandLineParams())
    var paths: File = nil

    if opts.output == "~/.paths":
        paths = open(getHomeDir() & "/.paths", FileMode.fmAppend)
    else:
        if not fileExists(opts.output):
            discard execShellCmd("touch " & opts.output)
        paths = open(opts.output, FileMode.fmAppend)

    var path = absolutePath(opts.path)
    if dirExists(path):
        write(paths, path & "\n")
        if opts.verbose:
            echo "[INFO] Path " & path & " was added to file."
    else:
        if opts.verbose:
            echo "[INFO] Path " & path & " was not found."

    paths.close()
except ShortCircuit as e:
    if e.flag == "argparse_help":
        echo p.help
        quit(0)
except UsageError:
    stderr.writeLine getCurrentExceptionMsg()
    quit(1)

