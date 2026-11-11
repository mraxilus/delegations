## Hold backend of driven checks, `tools/drive.nim`, to end each process Chromium starts before
##   run removes its profile and gives what page reported: processes of Chromium write profile
##   after first one exits, so profile removed while one lives fails, or comes back.
##   Case as found, 2026-11-11, on branch of live script: full Chrome for Testing 153.0.8010.12,
##     as `LOJBAN_CHROMIUM` named it, wrote `Default/TransportSecurity` after its first process
##     exited, and `removeDir` of profile failed with `Directory not empty`.
##   Domain is each process of Chromium, at any depth, that lives once first one exits: fake
##     leaves one that writes profile till it ends, as Chrome did, and one two levels down that
##     never ends.
##   Fake of Chromium is script of shell, so no browser runs here: it reports end of run, as page
##     does, through `curl`.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[os, strutils, unittest]
from std/posix import Pid, SIGKILL, kill

import ../../tools/drive


const
  DIRECTORY_FAKE = "build" / "drive" / "fake"  ## Folder fake of Chromium runs in, and serves.
  PATH_RECORD = DIRECTORY_FAKE / "descendant"
    ## Id of process fake leaves two levels down, as fake records it.
  FAKE_CHROMIUM = """#!/bin/sh
# Fake of Chromium: leave process two levels down that never ends, and record its id, under
# process that waits on it; leave process that writes profile till it ends; report end of run.
for argument; do
  case $argument in --user-data-dir=*) profile=${argument#--user-data-dir=} ;; esac
  address=$argument
done
record=$(dirname "$profile")/descendant
sh -c 'sh -c "echo \$\$ > \"\$0.part\" && mv \"\$0.part\" \"\$0\" && exec sleep infinity" "$0" &
  wait' "$record" &
until [ -s "$record" ]; do :; done
sh -c 'while kill -0 "$(cat "$1")" 2> /dev/null; do : > "$0/late"; done' "$profile" "$record" &
until [ -e "$profile/late" ]; do :; done
curl -s -X POST --data 0 "${address}done" > /dev/null
exec sleep infinity
"""
    ## Fake of Chromium; last argument is address of page, as `runPage` passes it.



suite "Internal: Backend of driven checks":
  test "Run ends each process Chromium starts, and removes profile, before it gives report":
    removeDir(DIRECTORY_FAKE)
    createDir(DIRECTORY_FAKE)
    let fake = DIRECTORY_FAKE / "chromium"
    writeFile(fake, FAKE_CHROMIUM)
    setFilePermissions(fake, {fpUserRead, fpUserWrite, fpUserExec})
    var
      run: RunPage
      is_alive = false
    try:
      run = runPage(fake, "", DIRECTORY_FAKE)
    finally:  # run that fails, or raises, leaves no process behind
      let descendant = Pid(PATH_RECORD.readFile.strip.parseInt)
      is_alive = kill(descendant, 0) == 0  # zombie counts: run reaps each process it ends
      if is_alive: discard kill(descendant, SIGKILL)  # writer ends with it
    check run.code == 0
    check not is_alive
    check not dirExists(DIRECTORY_FAKE / "profile")
