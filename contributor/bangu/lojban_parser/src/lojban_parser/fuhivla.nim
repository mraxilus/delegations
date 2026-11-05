## Test brivla against rules of fu'ivla that need other words: combination, and slinku'i test.
##   4.7 says fu'ivla is no gismu or lujvo, nor any combination of cmavo, gismu and lujvo; and
##     CV cmavo joined to its front makes no lujvo, which 4.7 calls slinku'i test.
##   Combination joins words with no pause between any two, by pause rules of 4.9 that
##     `forms.nim` holds: words needing pause between them do not run together in speech.
##     It counts only where its stress falls as fu'ivla stresses, on penultimate syllable.
##   Cost: combination splits text once at each letter; slinku'i test splits 85 joined words as
##     lujvo, one for each CV cmavo, so its time is 85 times that of `splitLujvo` (expected).

{.experimental: "strictFuncs".}

import std/options

import ./[clusters, forms, lujvo]


func isBrivlaJoinable(piece: string): bool =
  ## Test piece reads as one gismu or lujvo by form, which may end combination.
  piece.isBrivla and piece.syllables >= 2 and (piece.isGismu or piece.splitLujvo.len > 0)


func combination*(text: string): Option[seq[string]] =
  ## Split text into cmavo, one or more, then gismu or lujvo, with no pause between any two
  ##   (4.9); none where letters allow no such split, as fu'ivla needs (4.7).
  ##   Combination counts where it sounds as fu'ivla does. Brivla stresses its penultimate
  ##     syllable (3.9), so only brivla closing combination stresses where fu'ivla does; cmavo
  ##     before it may take stress or none. So `spageti` is no `spage ti`, as 4.7 holds.
  ##   Cmavo run together split before each consonant, as `splitCompound` splits them; cmavo
  ##     opening with vowel inside them needs pause, so no split holds one.
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
  ## Find lujvo that CV cmavo before text makes, which 4.7 forbids fu'ivla (slinku'i test);
  ##   none where each of 85 CV cmavo leaves text apart.
  for consonant in CONSONANTS:
    for vowel in VOWELS:
      let joined = consonant & vowel & text
      if joined.splitLujvo.len > 0: return some(joined)
  none(string)
