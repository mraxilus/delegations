## Name body of work carries where its pages are published, in one place.
##
##   Every page published from this project puts name of work in front of its own name, so
##     gallery holding work from several places sorts them together and one of these can be
##     told from somebody else's at one glance.
##   Two forms, because two kinds of page are published and reader deserves to know which is
##     which before opening either:
##     `WORK` titles page project stands behind -- reference and body sim.
##     `MOCKUP` titles one-off exploration kept for reference, which is every other page
##       (`CONTRIBUTOR.md` draws same line between `pages/` and `mockups/`).
##   Mockup form is derived from `WORK`, never written out again, so name of work is spelt
##     once in whole project (Article II.1).
##   Every title reads in title case, so published set is one consistent form.

{.experimental: "strictFuncs".}


const
  WORK* = "Dance Ontology"
    ## Name of body of work, titling page project stands behind.
  MOCKUP* = WORK & " Mockup"
    ## Same name marked as exploration, titling page project does not stand behind.
