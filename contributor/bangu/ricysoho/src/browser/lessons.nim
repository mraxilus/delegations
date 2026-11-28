## lo jboselci'a poi le ctuca pe le papri pe lo linji cu jarco ke'a
##   .i ro selci'a cu skicu pa klesi be lo linji .a pa pagbu be le ctuca
##   .i `suites/test_layers.nim` jarco lo du'u le genturfa'i cu tcidu ro selci'a

{.experimental: "strictFuncs".}

import ../ricysoho/layers


const  # ro jboselci'a pe le ctuca
  LESSON_CATEGORY*: array[Category, string] = [
    "le linji cu sinxa pa bridi .i pa bridi cu vasru pa selbri .e lo sumti poi le selbri cu " &
        "casnu ke'a",
    "le linji cu sinxa le fanmo be pa bridi",
    "le linji cu sinxa pa sumti .i pa sumti cu sinxa pa da poi le selbri cu casnu ke'a",
    "le linji cu sinxa pa selbri .i pa selbri cu sinxa le srana poi le bridi cu cusku ke'a",
    "le linji cu sinxa pa tanru .i pa tanru cu vasru su'o re pagbu .i le romoi pagbu cu jicmu " &
        ".i lo drata pagbu cu galfi le smuni be ri",
    "le linji cu sinxa pa tanru pagbu .i pa tanru pagbu cu pagbu pa tanru",
    "le linji cu sinxa pa jufra pe zo poi .a zo noi .i le jufra cu skicu pa sumti",
    "le linji cu sinxa pa jufra pe zo nu .a zo du'u .a zo ka .i le jufra cu sinxa pa fasnu .a " &
        "pa ckaji .a pa sidbo",
    "le linji cu sinxa pa jufra pe zo be .i le jufra cu jorne pa sumti pa selbri",
    "le linji cu sinxa pa tcita sumti .i pa tcita sumti cu vasru pa tcita .e pa sumti",
    "le linji cu sinxa pa tcita .i pa tcita cu cusku lo stuzi .a lo temci .a lo krinu be le bridi",
    "le linji cu sinxa pa namcu .i pa namcu cu klani",
    "le linji cu sinxa pa zifre valsi .i pa zifre valsi cu na pagbu le bridi .i ri cusku lo " &
        "se cinmo .a lo se cmene",
  ]
    ## lo selci'a poi skicu ro klesi be lo linji
  LESSON_START* = "ko pencu pa valsi .a pa linji .i ko samcu'a ri mu'i lo nu le ctuca cu stali"
    ## le selci'a poi le ctuca cu jarco ke'a pu lo nu le prenu cu cuxna da
  LESSON_BARS* = "ro linji poi vasru le valsi"
    ## le cmene be le liste be ro linji poi vasru pa valsi
  LESSON_HELD* = "ro linji poi vasru le linji"
    ## le cmene be le liste be ro linji poi vasru pa linji
  LESSON_NONE* = "le liste cu vasru no smuni be le valsi"
    ## le selci'a poi le ctuca cu jarco ke'a va'o lo nu le liste cu vasru no smuni be pa valsi
  LESSONS* = @LESSON_CATEGORY & @[LESSON_START, LESSON_BARS, LESSON_HELD, LESSON_NONE]
    ## ro jboselci'a pe le ctuca
