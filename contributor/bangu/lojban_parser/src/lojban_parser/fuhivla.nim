## jdice lo du'u lo brivla cu mapti lo fu'ivla javni poi nitcu lo datyvla
##   .i le re javni cu du lo cipra be lo vlagunma be'o .e lo cipra po'u `slinku'i test`
##   .i `CLL 4.7` cusku lo du'u lo fu'ivla cu na gismu gi'e na lujvo gi'e na gunma lo valsi poi
##       cmavo ja gismu ja lujvo
##   .i ji'a lo cmavo poi seltai `CV` gi'e jorne lo crane be lo fu'ivla cu zbasu no lujvo
##   .i le cipra be di'u cu selcme zoi gy. slinku'i test .gy. bu'u `CLL 4.7`
##
## ni'o lo vlagunma cu jorne lo valsi poi no denpa cu zvati lo jbini be ke'a ja'i lo de'ajva pe
##     `CLL 4.9`
##   .i `forms.nim` ralte le javni
##   .i lo re valsi poi nitcu lo denpa ne'i lo jbini be ke'a na jorne ne'i lo selba'u
##   .i le vlagunma cu vajni va'o po'o lo nu ri basna lo slaka poi lidne le romoi slaka
##   .i lo fu'ivla cu basna le slaka
##
## ni'o jdima fa lo nu le vlagunma cu fendi le selci'a pa roi bu'u ro lerfu
##   .i le cipra po'u `slinku'i test` fendi lo bimu valsi poi seljo'e ku'o ta'i lo lujvo
##   .i ro cmavo poi seltai `CV` krasi pa le valsi
##   .i se ki'u bo lo temci be le cipra cu du lo temci be lo bimu nu pilno `splitLujvo`
##   .i di'u se kanpe

{.experimental: "strictFuncs".}

import std/options

import ./[clusters, forms, lujvo]


func isBrivlaJoinable(piece: string): bool =
  ## jdice lo du'u le pagbu cu gismu ja lujvo ja'i lo tarmi
  ##   .i lo gismu ja lujvo cu ka'e fanmo lo vlagunma
  piece.isBrivla and piece.syllables(Kind.Lujvo) >= 2 and
      (piece.isGismu or piece.splitLujvo.len > 0)


func combination*(text: string): Option[seq[string]] =
  ## fendi le selci'a fi su'o pa cmavo .e pa gismu ja lujvo poi romoi
  ##   .i no denpa cu zvati lo jbini be lo valsi to `CLL 4.9` toi
  ##   .i jarco no da va'o lo nu le lerfu cu curmi no le ve fendi
  ##   .i lo fu'ivla cu nitcu lo nu no le ve fendi cu se curmi to `CLL 4.7` toi
  ##
  ## ni'o lo vlagunma cu vajni va'o lo nu lo sance be ri cu simsa lo sance be lo fu'ivla
  ##   .i lo brivla cu basna le slaka poi lidne le romoi slaka to `CLL 3.9` toi
  ##   .i se ki'u bo le brivla cu basna lo slaka poi lo fu'ivla cu basna ke'a va'o po'o lo nu le
  ##       brivla cu fanmo le vlagunma
  ##   .i lo cmavo poi lidne le brivla cu ka'e basna su'o slaka .a no slaka
  ##   .i se ki'u bo `spageti` na du lo vlagunma po'u `spage ti`
  ##   .i `CLL 4.7` xusra lo du'u `spageti` fu'ivla
  ##
  ## ni'o lo ma'orgunma cu se fendi pu ro zunsna ta'i lo nu `splitCompound` fendi
  ##   .i lo cmavo poi selkra lo karsna gi'e zvati lo ma'orgunma cu nitcu lo denpa
  ##   .i se ki'u bo no ve fendi cu vasru lo cmavo poi selkra lo karsna
  for j in 1 ..< text.len:
    let (head, rest) = (text[0 ..< j], text[j .. ^1])
    if not rest.isBrivlaJoinable: continue
    let words = head.splitCompound
    if words.len == 0: continue
    var is_joined = not isPauseNeeded(words[^1], rest)
    for k in 1 ..< words.len:
      if isPauseNeeded(words[k - 1], words[k]): is_joined = false
    if is_joined: return some(words & rest)
  none(seq[string])


func slinkuhi*(text: string): Option[string] =
  ## facki lo lujvo poi selzba lo nu lo cmavo poi seltai `CV` lidne le selci'a
  ##   .i `CLL 4.7` na curmi lo nu lo cmavo poi seltai `CV` gi'e lidne lo fu'ivla cu zbasu lo lujvo
  ##       to lo cipra po'u `slinku'i test` toi
  ##   .i jarco no da va'o lo nu ro lo bimu cmavo poi seltai `CV` zbasu no lujvo fi le selci'a
  for consonant in CONSONANTS:
    for vowel in VOWELS:
      let joined = consonant & vowel & text
      if joined.splitLujvo.len > 0: return some(joined)
  none(string)
