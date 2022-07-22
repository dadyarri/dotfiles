import os
import std/strutils
import std/sequtils
import argparse

var p = newParser:
    help("{prog}: Simple utility to build a path variable from text file. Empty strings and non-existent directories are ignored.")
    arg("path", help="Path to file with paths", default=some("~/.paths"))
    flag("-v", "--verbose", help="Show more verbose output")

try:
    let opts = p.parse(commandLineParams())
    var paths: seq[string]

    if opts.path == "~/.paths":
        paths = split(readFile(getHomeDir() & "/.paths"), "\n")
    else:
        paths = split(readFile(opts.path), "\n")

    if opts.verbose:
        echo "[INFO]: Paths in given file: " & join(paths, ", ")

    echo join(deduplicate(filter(paths, proc (s: string): bool = s.len > 0 and dirExists(s))), ":")
except ShortCircuit as e:
    if e.flag == "argparse_help":
        echo p.help
        quit(0)
except UsageError:
    stderr.writeLine getCurrentExceptionMsg()
    quit(1)
