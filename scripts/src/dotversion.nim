import os
import std/xmlparser
import std/xmltree

import argparse
import semver

var p = newParser:
  help("{prog}: Utility to increase versions of dotnet's projects according to SemVer (https://semver.org).")
  arg("dir", help="Path to dotnet project")
  arg("version_part", help="Part of version (one of major, minor, patch)", default=some("patch"))
  flag("-s", "--silent", help="Do not write new version to *.csproj file, only calculate and print.")
  flag("-v", "--verbose", help="Show more verbose output")

try:
    let opts = p.parse(commandLineParams())
    let absPath = absolutePath(opts.dir)
    let projectFile = absPath & "/" & splitPath(absPath).tail & ".csproj"

    if opts.verbose:
      echo "Searching for project file: " & projectFile & "..."

    if fileExists(projectFile):
      var project = loadXml(projectFile)
      var version_node = project.child("PropertyGroup").child("Version")
      echo "Current version: " & version_node.innerText()

      var version = parseVersion(version_node.innerText())

      case opts.version_part:
        of "patch":
          version.patch += 1
        of "minor":
          version.patch = 0
          version.minor += 1
        of "major":
          version.patch = 0
          version.minor = 0
          version.major += 1
        else:
          stderr.writeLine "Wrong part's name: " & opts.version_part
          quit(1)

      echo "New version: " & $version

      if not opts.silent:

        var version_text = newText($version)
        version_node.delete(0)
        version_node.add(version_text)

        let file = open(projectFile, fmWrite)
        file.write(project)
        file.close()

    else:
      stderr.writeLine "Seems like " & absPath & " is not a .NET project..."
      quit(1)

except ShortCircuit as e:
    if e.flag == "argparse_help":
        echo p.help
        quit(0)
except UsageError:
    stderr.writeLine getCurrentExceptionMsg()
    quit(1)
