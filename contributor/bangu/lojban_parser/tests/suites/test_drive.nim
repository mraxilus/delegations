## cipra lo du'u le samtci po'u `tools/drive.nim` noi jitro lo cipra cu sisti ro pruce poi
##     `Chromium` rinka lo nu ke'a cfari ku'o pu lo nu le nu cipra cu vimcu le vreji pe vo'a gi'e
##     jarco lo selsku be le papri
##   .i ki'u bo lo pruce pe `Chromium` ciska fi le vreji ba lo nu le pamoi pruce cu sisti
##   .i se ki'u bo lo nu vimcu le vreji ca lo nu su'o pruce cu jmive cu fliba
##   .i ja le vreji cu rapselzba
##   .i lo mupli cu terfa'i de'i `2026-11-11` bu'u lo jimca be `git` be'o pe le samtci pe lo
##       mivyselci'a
##   .i `LOJBAN_CHROMIUM` cmene `Chrome for Testing 153.0.8010.12` noi mulno
##   .i `Chrome` cu pu ciska `Default/TransportSecurity` ba lo nu le pamoi pruce cu sisti
##   .i `removeDir` pe le vreji cu pu fliba gi'e jarco `Directory not empty`
##   .i le cipra cu cipra ro pruce pe `Chromium` ge'u zi'e poi jmive ba lo nu le pamoi pruce cu
##       sisti
##   .i lo ni le pruce cu condi cu na vajni
##   .i le fukpi cu zbasu pa pruce poi ciska fi le vreji ca ro lo nu ke'a zasti ku'o ta'i `Chrome`
##   .i le fukpi cu zbasu ji'a pa pruce poi lo rirni be lo rirni be ke'a du le fukpi ku'o zi'e poi
##       no roi sisti
##   .i le fukpi be `Chromium` selci'a fi `shell`
##   .i se ki'u bo le cipra cu pilno no tcidu be lo papri
##   .i le fukpi cu cusku lo fanmo be le nu cipra sepi'o `curl` ta'i lo papri

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[os, strutils, unittest]
from std/posix import Pid, SIGKILL, kill

import ../../tools/drive


const
  DIRECTORY_FAKE = "build" / "drive" / "fake"
    ## lo vasru poi le fukpi be `Chromium` gunka ne'i ke'a
    ##   .i `runPage` sabji le vasru
  PATH_RECORD = DIRECTORY_FAKE / "descendant"
    ## lo namcu poi cmene lo pruce poi lo rirni be lo rirni be ke'a du le fukpi
    ##   .i le fukpi cu ciska le namcu
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
    ## le fukpi be `Chromium`
    ##   .i `runPage` benji lo judri be le papri le fukpi ta'i le romoi sumti



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
    finally:  # no pruce cu stali ba lo nu cipra poi fliba gi'a renro lo nafmupli
      let descendant = Pid(PATH_RECORD.readFile.strip.parseInt)
      # `kill` jdice lo du'u lo pruce poi morsi zi'e poi no da cpacu lo fanmo be ke'a jmive
      #   .i ki'u bo le nu cipra cu cpacu lo fanmo be ro pruce poi le nu cipra cu sisti ke'a
      is_alive = kill(descendant, 0) == 0
      if is_alive: discard kill(descendant, SIGKILL)  # le ciska be fi le vreji cu sisti ji'a
    check run.code == 0
    check not is_alive
    check not dirExists(DIRECTORY_FAKE / "profile")
