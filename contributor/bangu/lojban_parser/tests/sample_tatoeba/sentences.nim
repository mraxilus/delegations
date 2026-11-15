## Hold fixed sample of lojban sentences of Tatoeba, with verdict parser gave each, for suite.
##   Written by `nim r tools/build.nim tatoeba <export>` from `jbo_sentences_detailed.tsv` of
##   Tatoeba export of 2026-10-31, SHA-256 `bf91e751a78a5137ffa741b0971df3c4`
##   `e7a5444e18b47545be51d0593629bb40`; never edit by hand, run verb again.
##   Sentences of Tatoeba, under licence CC BY 2.0 FR; folder holding module is distributed
##     under that licence, as `NOTICE.md` beside module gives, never under licence of
##     repository.
##   Sample is greedy cover of features of reading, as `tools/tatoeba.nim` defines them.

{.experimental: "strictFuncs".}


type SentenceTatoeba* = object  ## Define one sentence of sample: number, text, owner, verdict.
  id* {.requiresInit.}: int  ## Number Tatoeba gives sentence, as `599308`.
  text* {.requiresInit.}: string  ## Sentence as export writes it.
  owner* {.requiresInit.}: string  ## Name of account owning sentence; empty where none owns it.
  verdict* {.requiresInit.}: string  ## Refusal and rule parser gave; empty where it reads.


const
  COUNT_FEATURES_TATOEBA* = 599  ## Features of reading sample reaches at render.
  SENTENCES_TATOEBA* = [
    SentenceTatoeba(id: 602555, text: "ko'a puze'i stali", owner: "remod", verdict: ""),
    SentenceTatoeba(id: 620861, text: "do ba'e ka'e co'e", owner: "FB", verdict: ""),
    SentenceTatoeba(
      id: 630266,
      text: "la david cu carmi selmle fi lo ka cintyxra ja maixra ja zgiselfi'i ja pemci be " &
          "sepu'a lo kanla ja kerlo ja pruxi",
      owner: "tijlan",
      verdict: "",
    ),
    SentenceTatoeba(id: 634760, text: "coi mi'e sepide", owner: "FB", verdict: "Grammar free 32"),
    SentenceTatoeba(
      id: 640244,
      text: "ei lo ctuca cu ciksi sei na torsku ro tcila gi'e roroi stidi fi lo tadni fe lo nu " &
          "tcidu lo ty moi fe'eco'i lo ty zdani",
      owner: "tijlan",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 645249,
      text: "la djon pu ba'o lo nu re nixli cu xusra lo du'u ny fi dy cinmo cu ka'enai jdice lo " &
          "du'u kansa ma kau po'u ny",
      owner: "tijlan",
      verdict: "Grammar gek-sentence 54",
    ),
    SentenceTatoeba(id: 645284, text: "vi ma jim", owner: "tijlan", verdict: "Grammar terms-1 81"),
    SentenceTatoeba(
      id: 656510,
      text: "lo rectu zo'u ka'enai citka",
      owner: "tijlan",
      verdict: "Grammar sentence 40",
    ),
    SentenceTatoeba(
      id: 657753,
      text: "lo cmaci cu tercu'e traji lo ka mi ce'u tadni djica na",
      owner: "tijlan",
      verdict: "Grammar ek 802",
    ),
    SentenceTatoeba(id: 663689, text: "ra tordu gi'e ku'i tsali", owner: "FB", verdict: ""),
    SentenceTatoeba(
      id: 668084,
      text: "le xekri ke kerfa bo melbi ninmu ke'e verba pu zvati le panka",
      owner: "arihato",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 672196,
      text: "na go nai da na zvati la.tatoebas. gi da na jufra",
      owner: "FB",
      verdict: "",
    ),
    SentenceTatoeba(id: 677886, text: "bisybo'o vi'a lo dargu", owner: "tijlan", verdict: ""),
    SentenceTatoeba(
      id: 678056,
      text: "coi susan .i ba'e pei",
      owner: "FB",
      verdict: "Grammar text-1 2",
    ),
    SentenceTatoeba(
      id: 685591,
      text: "ei ko pensi lo zi se cusku be mi bei do",
      owner: "FB",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 695193,
      text: "mi djuno lo du'u xu kau ko'a bradi",
      owner: "arihato",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 703862,
      text: "pa .i re .i ci .i vo .i mu .i xa .i ze .i bi .i so .i dau",
      owner: "FB",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 711215,
      text: "va'o lo nu mi ka'e benji lo vartitspi do kei doi trang mi co'e",
      owner: "FB",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 730455,
      text: "va'o lo nu fanva lo bangisulu jufra lo glibau kei ku joi lo nu fanva lo glibau " &
          "jufra lo bansuve'a kei na'e sirji fanva lo bangisulu jufra lo bansuve'a",
      owner: "FB",
      verdict: "",
    ),
    SentenceTatoeba(id: 741024, text: "mi ziba sipna", owner: "arihato", verdict: ""),
    SentenceTatoeba(
      id: 750318,
      text: "ra na'e nelci ge po'onai lo nunga'arboijvi gi ji'a lo nuntipyboijvi",
      owner: "tijlan",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 763605,
      text: "di'i xu se srera .ibo xu za'ure'u se gasnu",
      owner: "rpglover64",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 769254,
      text: "pa .i re .i ci .i vo .i mu .i xa .i ze .i bi .i so .i pano .i papa .i pare .i paci",
      owner: "arihato",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 769264,
      text: "jau i gai i fei i dau i so i bi i ze i xa i mu i vo i ci i re i pa i incipe",
      owner: "arihato",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 770517,
      text: "la juliet. bu'u lo balni cu tavla la noi bartu romeon",
      owner: "arihato",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 776648,
      text: "ta'i .uanai ma lo nalpo'i cpiso'a ku cnita lo farlu cpizda",
      owner: "rpglover64",
      verdict: "",
    ),
    SentenceTatoeba(id: 801190, text: "vanci coi .i pei", owner: "FB", verdict: ""),
    SentenceTatoeba(
      id: 812842,
      text: "pau je'i xu ki'a cu'e mo fi'a xo ma pei",
      owner: "FB",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 851871,
      text: "ko denpa .i pa .i re .i mu si ci .i renro",
      owner: "User4473",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 982915,
      text: "le ko flalu zo'u tu'e logji pensi .i panpi menli .i vrude zukte tu'u",
      owner: "User4473",
      verdict: "",
    ),
    SentenceTatoeba(id: 1098504, text: "vu bu'u do mi sipna", owner: "cntrational", verdict: ""),
    SentenceTatoeba(
      id: 1098525,
      text: "mi ze'epu noroi prami do",
      owner: "cntrational",
      verdict: "",
    ),
    SentenceTatoeba(id: 1117710, text: "se srana ge mi ginai ra", owner: "User4473", verdict: ""),
    SentenceTatoeba(
      id: 1122397,
      text: "mabla nu la valsi ku na zvati",
      owner: "cntrational",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 1147040,
      text: ".abu banzu .ijeku'i by. na go'i",
      owner: "User4473",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 1189853,
      text: ".e'u doi mi'o do'u ko finti lo bangu pe mi'o mu'i lo nu no da jimpe lo se cusku be " &
          "mi'o",
      owner: "cntrational",
      verdict: "",
    ),
    SentenceTatoeba(id: 1192861, text: "mi di'inai fipkalte", owner: "User4473", verdict: ""),
    SentenceTatoeba(
      id: 1387771,
      text: "ti poi jufra na xe fanva .i ba'e se fanva",
      owner: "User4473",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 1430461,
      text: "puku mi se spaji lo du'u da'i xe fanva lo'u mi xebni li'o le'u vau zo'o",
      owner: "User4473",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 1472578,
      text: "ma tcini doi .i'u lo verba",
      owner: "sadtoots",
      verdict: "",
    ),
    SentenceTatoeba(id: 1484737, text: "ra dusbarda", owner: "sadtoots", verdict: "Stream Hyphen"),
    SentenceTatoeba(
      id: 1502454,
      text: "mi se zdani la Milan",
      owner: "gleki",
      verdict: "Stream Breakup",
    ),
    SentenceTatoeba(
      id: 1508613,
      text: "na'e canja lo ka'irtrusi'o .enai lo cidja .abo lo xumrkonkreto",
      owner: "sadtoots",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 1514303,
      text: ".i mi na.e ku'i do .i'anai fuzme",
      owner: "pyrachi",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 1531610,
      text: "lo vinji co'a vofli gi'ebazibo mo'u se viska",
      owner: "filipos",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 1576931,
      text: "mi xabju ti xotli",
      owner: "",
      verdict: "Grammar tail-terms 71",
    ),
    SentenceTatoeba(id: 1606670, text: "ra pu klama fu lo tu'unre'e", owner: "", verdict: ""),
    SentenceTatoeba(
      id: 1625487,
      text: "doi .tamis. do'u xu do tirna mi",
      owner: "xekri",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 1650288,
      text: "lu zo'e do tolcelci'i ce'o ckasu ce'o damba .i ce'o bo do jamji'a li'u jai se stidi",
      owner: "dededede4",
      verdict: "",
    ),
    SentenceTatoeba(id: 1655604, text: "go'ira'o", owner: "FB", verdict: ""),
    SentenceTatoeba(
      id: 1655646,
      text: "lu pamei je'i remei farna li'u lu .e'o jenai li'u",
      owner: "FB",
      verdict: "",
    ),
    SentenceTatoeba(id: 1657009, text: ".i carvi na ja nai kelci", owner: "tomoj", verdict: ""),
    SentenceTatoeba(
      id: 1667642,
      text: "nelci le jamna fa lo po'o ba'onai viska be jy",
      owner: "tijlan",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 1667653,
      text: "mi djica lo nu ka'e prali mi .e babo ro drata",
      owner: "tijlan",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 1668750,
      text: ".i gunka fi'o pe'a simsa lo bifce",
      owner: "tsani",
      verdict: "",
    ),
    SentenceTatoeba(id: 1672606, text: "mi zo'u .aunai bartu cadzu", owner: "FB", verdict: ""),
    SentenceTatoeba(
      id: 1679526,
      text: ".i mi ta'e pinxe vei mo'e pa kabri lo ckafi ca lo cerni",
      owner: "selpahi",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 1682825,
      text: "ro na'ebo le nolraitru naku sinma le nolraitru",
      owner: "FB",
      verdict: "",
    ),
    SentenceTatoeba(id: 1713936, text: "ta na'e spaji vau je'u pei", owner: "FB", verdict: ""),
    SentenceTatoeba(id: 1714245, text: "pavyseljirna kavbu ba'o xu ku", owner: "FB", verdict: ""),
    SentenceTatoeba(
      id: 1752376,
      text: "ti lo santa me ko'a moi je'u pei",
      owner: "xorxes",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 1756929,
      text: "le certu be lo zu'o blutu'u karbixygau cei broda cu tepygau vo'a lo ka crezenzu'e " &
          "lo zu'o broda lo vartisyboi",
      owner: "mudri",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 1767808,
      text: "ko'a pu surdzu je ca bo sanga",
      owner: "tijlan",
      verdict: "",
    ),
    SentenceTatoeba(id: 1767921, text: "mo sai", owner: "tijlan", verdict: ""),
    SentenceTatoeba(id: 1769483, text: "je'asai mackai", owner: "tijlan", verdict: ""),
    SentenceTatoeba(id: 1783421, text: "pa cevni ku zasti", owner: "FB", verdict: ""),
    SentenceTatoeba(id: 1786164, text: ".ui dai do ca ze'u pu mo", owner: "FB", verdict: ""),
    SentenceTatoeba(
      id: 1796373,
      text: "so'o da re lerfu fi so'o sance bau la ninxesybau .i mu'a mypy ge'o go'i fi lo sance " &
          "pe by .ije nyty ge'o go'i fi lo sance pe dy .ije gyky ge'o go'i fi lo sance pe gy " &
          ".ije tyzy ge'o go'i fi lo sance pe dyjy",
      owner: "mudri",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 1808430,
      text: "doi cevni i doi cevni i oire'e iocai mu'i ma do fesli'a mi",
      owner: "nonong",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 1811512,
      text: "pano .i papa .i pare .i paci .i pavo .i pamu .i paxa .i paze .i pabi .i paso .i reno",
      owner: "mahir256",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 1902322,
      text: "mi do zu sai ba'o penmi .i .e'u mi'o paroi je reroi xalka pinxe gi'e simta'a lo " &
          "tolci'o je xamgu djedi",
      owner: "zalaim",
      verdict: "",
    ),
    SentenceTatoeba(id: 1918836, text: "coi. mari,as. mi'e tam.", owner: "nonong", verdict: ""),
    SentenceTatoeba(id: 1948209, text: "zdani mi'a vau fi'i", owner: "FlamingTofu", verdict: ""),
    SentenceTatoeba(id: 1966266, text: "xu do mo'ini'a cadzu", owner: "FlamingTofu", verdict: ""),
    SentenceTatoeba(
      id: 1972302,
      text: "mi djica lo nu loi mi cidja cu ba'e morsi .i bilma jebo mrobi'o naje morsi",
      owner: "FlamingTofu",
      verdict: "",
    ),
    SentenceTatoeba(id: 1987626, text: "naru'e jenca", owner: "FlamingTofu", verdict: ""),
    SentenceTatoeba(id: 1987928, text: "go'i .ijebo ku'i nandu", owner: "FlamingTofu", verdict: ""),
    SentenceTatoeba(id: 1987934, text: "go'i .i pu cai cfari", owner: "FlamingTofu", verdict: ""),
    SentenceTatoeba(id: 1989186, text: "doi .sam. .e'unai", owner: "FlamingTofu", verdict: ""),
    SentenceTatoeba(
      id: 1999981,
      text: "lo cevni na.enai la .budas. zasti",
      owner: "FlamingTofu",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 2024281,
      text: "je'a ko'a xamgu tavla",
      owner: "FB",
      verdict: "Grammar selbri-6 136",
    ),
    SentenceTatoeba(id: 2042016, text: "na'e vi brife", owner: "FlamingTofu", verdict: ""),
    SentenceTatoeba(id: 2063216, text: "mi do se xi vei pa e re prami", owner: "FB", verdict: ""),
    SentenceTatoeba(
      id: 2063807,
      text: "mi'enai la do i mi'e rikardos",
      owner: "FB",
      verdict: "Grammar sumti-tail 111",
    ),
    SentenceTatoeba(
      id: 2095735,
      text: "ta'o xu do se cmene zo robin. ji'a",
      owner: "gleki",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 2096061,
      text: "lo pavdei cu pa moi djedi .i lo reldei cu re moi djedi .i li'o",
      owner: "FB",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 2096134,
      text: "ni'o .ui ro'a cu'i mi cikre lo pe mi skami",
      owner: "FB",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 2096195,
      text: ".y. la .clsn. cu sutra zmadu .i do jinga .ui dai",
      owner: "gleki",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 2098929,
      text: "i je ko'a ma mi cusku pau nai mu'o nai",
      owner: "FB",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 2098933,
      text: ".ai sai mi cpacu se va'u do nu'e cu'i ku'i",
      owner: "FB",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 2098935,
      text: "nu'e do'u mi na za'u re'u pante ca lo cabdei .i .yy go'i nu'e nai .i .oi ti rigni",
      owner: "FB",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 2108189,
      text: "ko viska nabo la .tam. .i go'i mi",
      owner: "FlamingTofu",
      verdict: "Grammar gihek 818",
    ),
    SentenceTatoeba(
      id: 2119742,
      text: "tom cu jukpa",
      owner: "jongausib",
      verdict: "Grammar text 0",
    ),
    SentenceTatoeba(
      id: 2125151,
      text: "ko kancu fe li pa bi'o pano",
      owner: "jongausib",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 2159050,
      text: "la'oi djunko melbi nixli",
      owner: "gleki",
      verdict: "Stream Slinkuhi",
    ),
    SentenceTatoeba(
      id: 2252055,
      text: "mi djica tu'a lo za'i mi kanro kei po'o",
      owner: "User4473",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 2253980,
      text: "ko jundi jecu cilre",
      owner: "gleki",
      verdict: "Grammar selbri-4 134",
    ),
    SentenceTatoeba(id: 2298576, text: "ko denpa gi'e nai cliva", owner: "tengo", verdict: ""),
    SentenceTatoeba(
      id: 2305208,
      text: "mi pinxe lo tcati joinai sakta",
      owner: "tijlan",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 2307148,
      text: "pa mai .e'u do .io ma ko'a djuno",
      owner: "tijlan",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 2312326,
      text: "pu ja'anai crori'a",
      owner: "tijlan",
      verdict: "Grammar jek 805",
    ),
    SentenceTatoeba(
      id: 2332321,
      text: "lo gloki kuzra pu co'i cteko budla lo bokru je ca ca'o kudra lo cmalybokru",
      owner: "gleki",
      verdict: "Grammar time 1030",
    ),
    SentenceTatoeba(id: 2376850, text: "la tom cu je'u na nelci do", owner: "gleki", verdict: ""),
    SentenceTatoeba(
      id: 2376859,
      text: "mi djica fe po'o lo nu mi kakne lo ka sipna",
      owner: "gleki",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 2376863,
      text: "mi djica fe po'o da'i lo nu ko'a na tai kargu",
      owner: "gleki",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 2377403,
      text: "lo cabna cu se tcika li rere .uedai",
      owner: "mudri",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 2384203,
      text: "xu la .toki ponas. do bangu",
      owner: "sadtoots",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 2402716,
      text: "lo xabju be lo bi'u nai cmatca cu ta'e kansi'u lo nu bevri lo narge me lo vo xance " &
          "be lo re prenu be'o poi se tarmi lo julne mei li so'o",
      owner: "gleki",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 2441805,
      text: "lonu mi zenba cpacu kei selja'e lonu mi zenba djica .i lonu mi zenba djica kei " &
          "selja'e lonu mi jdika cpacu .i lonu mi jdika cpacu kei selja'e lonu mi jdika djica " &
          ".i lonu mi jdika djica kei selja'e lonu mi zenba cpacu",
      owner: "rprije",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 2513762,
      text: "da me lo se gunka noi .ei zukte",
      owner: "gleki",
      verdict: "",
    ),
    SentenceTatoeba(id: 2514131, text: "mi citka lo badna ku po'o", owner: "gleki", verdict: ""),
    SentenceTatoeba(id: 2533738, text: "viba'oku cripa", owner: "gleki", verdict: ""),
    SentenceTatoeba(
      id: 2575401,
      text: "do zutse e'o vau sei ra pu cusku",
      owner: "gleki",
      verdict: "",
    ),
    SentenceTatoeba(id: 2575434, text: "tai sai kukte", owner: "gleki", verdict: ""),
    SentenceTatoeba(
      id: 2577894,
      text: "lo tom mi tamne",
      owner: "gleki",
      verdict: "Grammar sumti-6 97",
    ),
    SentenceTatoeba(id: 2583370, text: "coi doi djan. .i pei", owner: "temlat", verdict: ""),
    SentenceTatoeba(id: 2584264, text: "mi vi nau doi tom", owner: "gleki", verdict: ""),
    SentenceTatoeba(
      id: 2590419,
      text: ".e'e sai doi .ari'anas. ko sutyze'a .i se va'o nai bo mi'o ba no roi tolcliva",
      owner: "selpahi",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 2599035,
      text: "lo ka vifne gi'e grute gi'abo stagi cu ka mutce gasnu lo nu kanro",
      owner: "gleki",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 2615921,
      text: "da tcati ije mi pinxe da ije mi gleki",
      owner: "gleki",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 2626994,
      text: "mi pu co'e je'a",
      owner: "temlat",
      verdict: "Grammar simple-tense-modal 972",
    ),
    SentenceTatoeba(
      id: 2635855,
      text: "to'e ki'u nai gi ko'a laldo mutce gi ko'a tsali",
      owner: "selpahi",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 2665695,
      text: "mi'a vi zvati co .ai se zdile",
      owner: "gleki",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 2676223,
      text: "vamji fa lo nu troci ije je'upei",
      owner: "gleki",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 2688629,
      text: "coi .i xu ti casnu be la aniMES. bei se irsi",
      owner: "quowah",
      verdict: "Grammar interval 932",
    ),
    SentenceTatoeba(id: 2725189, text: "sai nai na lakne", owner: "gleki", verdict: ""),
    SentenceTatoeba(
      id: 2793895,
      text: "mi'a borg",
      owner: "gleki",
      verdict: "Grammar paragraphs 4",
    ),
    SentenceTatoeba(id: 2798537, text: "naipei do bredi", owner: "gleki", verdict: ""),
    SentenceTatoeba(
      id: 2802254,
      text: "mi tirna lo nu sene'i stapa",
      owner: "gleki",
      verdict: "Grammar guhek 808",
    ),
    SentenceTatoeba(
      id: 2803459,
      text: ".i ma pu rinka lo nu .ue do ka'e vasxu se ri'a nai lo ka mrobi'o vau je sepi'o nai " &
          "lo vacri lumci cabra",
      owner: "gleki",
      verdict: "Grammar stag 971",
    ),
    SentenceTatoeba(
      id: 2803545,
      text: ".i ja'e nai bo mi na ka'e sipna",
      owner: "gleki",
      verdict: "",
    ),
    SentenceTatoeba(id: 2808680, text: "di'ai", owner: "gleki", verdict: "Selmaho"),
    SentenceTatoeba(
      id: 2853152,
      text: "mi djica nai",
      owner: "gleki",
      verdict: "Grammar bridi-tail 50",
    ),
    SentenceTatoeba(
      id: 2864592,
      text: "mi se slabu nai ra",
      owner: "gleki",
      verdict: "Grammar tanru-unit-2 152",
    ),
    SentenceTatoeba(
      id: 2988210,
      text: "fau lo nu da poi prenu cu nu'o se bangu de ba'o lo nu da makcu zo'u lakne nai fa lo " &
          "nu da ba certu se bangu de",
      owner: "gleki",
      verdict: "Grammar statement-1 12",
    ),
    SentenceTatoeba(id: 2993978, text: "mi prami do soi vo'a", owner: "GuSec", verdict: ""),
    SentenceTatoeba(
      id: 3000615,
      text: "va'o lo banli lisri pe fi'e la .kristian.anasn. zi'e pe me'e lu lo cnino taxfu be " &
          "lo balnoltru li'u lo re tcica cu nupre fi lo balnoltru fe tu'a lo cnino taxfu poi " &
          "na ka'e se viska da poi ke'a na mapti lo ke'a jibri gi'a nalvu'e gi'a bebna",
      owner: "filipos",
      verdict: "",
    ),
    SentenceTatoeba(id: 3005893, text: "nai mutce vajni", owner: "gleki", verdict: ""),
    SentenceTatoeba(
      id: 3028387,
      text: "lo verba ta'e ze'i co'a tatpi",
      owner: "gleki",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 3083055,
      text: "lo vi cukta cu me mi nai moi",
      owner: "gleki",
      verdict: "Grammar sumti 90",
    ),
    SentenceTatoeba(
      id: 3157248,
      text: "bu'a fa nu'i ge la lojban lo bangu gi la salvador.dalis.",
      owner: "gleki",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 3292661,
      text: "mi djica tu'a lo ckafi joi ta'o ladru",
      owner: "gleki",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 3434608,
      text: "i ku'i la'acu'i ja'o loi vi cmana fe'eco'a fe'eca'o canci",
      owner: "gleki",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 3663742,
      text: "pe'u e'o ko dunda vo lo taigrteil zei bisyladru joi ri'ornimre bo titnanba",
      owner: "nonong",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 3692857,
      text: "lo bangu zo'u sei ma'a djuno lo remna by finti",
      owner: "iifle",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 3758327,
      text: "li re su'i re du li vo ze'e ve'e",
      owner: "Wuzzy",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 3758550,
      text: "li re pi'i ze pi'i papa pi'i paci su'i vo du li renonoxa",
      owner: "Wuzzy",
      verdict: "",
    ),
    SentenceTatoeba(id: 3761243, text: "ca ca'a si'ercarvi", owner: "Wuzzy", verdict: ""),
    SentenceTatoeba(
      id: 3765367,
      text: "lu doi tom pau lo'e djacu cu ckaji ma li'u .i lu ca lo nu mi lumci fo dy. kei dy. " &
          "co'a xekri li'u",
      owner: "Wuzzy",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 3765713,
      text: "la tom se.u la meris klama lo zarci",
      owner: "Wuzzy",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 3765716,
      text: "la tom se.unai la meris klama lo zarci",
      owner: "Wuzzy",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 3766233,
      text: "do puzi je cu'e sombo lo gurni",
      owner: "Wuzzy",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 3766653,
      text: "do djica tu'a loi gu'i tcati gi ckafi",
      owner: "Wuzzy",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 3777471,
      text: "mi pu je ca je ba prami lo sidbo be la tato'ebas",
      owner: "Wuzzy",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 3807272,
      text: "li mo'e namcrgogolo du li pano te'a panono",
      owner: "Wuzzy",
      verdict: "Grammar operand-3 385",
    ),
    SentenceTatoeba(
      id: 3807297,
      text: "zoi dy.Zug.gy. jai nandytce lo cilre be fi lo dotybau",
      owner: "Wuzzy",
      verdict: "Stream Quotation",
    ),
    SentenceTatoeba(
      id: 3807467,
      text: "la tom xi pa tavla la tom xi re",
      owner: "Wuzzy",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 3813059,
      text: "go do tcidu gi'e jimpe dei gi .uidai do kakne tu'a la lojban",
      owner: "Wuzzy",
      verdict: "",
    ),
    SentenceTatoeba(id: 3843946, text: "Ha lo!", owner: "rubekolo", verdict: "Stream Letter"),
    SentenceTatoeba(
      id: 3848392,
      text: "ba'a do lo ro da jai gau daspo",
      owner: "iifle",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 3855768,
      text: "la rom pu se zbasu ze'a lo djedi be li su'e nai pa",
      owner: "gleki",
      verdict: "Grammar mex 310",
    ),
    SentenceTatoeba(
      id: 3928008,
      text: "li ni'u ci cu nu'a va'a li ma'u ci",
      owner: "gleki",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 3948318,
      text: "ro da zo'u mi bredi tu'a da lu'u ne se va'u do",
      owner: "iifle",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 3989793,
      text: "tu'a pu ku na ka'e se rivbi",
      owner: "iifle",
      verdict: "Grammar gek 807",
    ),
    SentenceTatoeba(
      id: 4167562,
      text: "roda poi ke'a panono ce'iva'e birti zo'u la'a lo ni djuno da kei na banzu",
      owner: "Wuzzy",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 4167581,
      text: "do na djuno xuku",
      owner: "Wuzzy",
      verdict: "Grammar selbri-2 132",
    ),
    SentenceTatoeba(id: 4170260, text: "mi punai klama lo zarci", owner: "Wuzzy", verdict: ""),
    SentenceTatoeba(id: 4170261, text: "mi paroinai dansu lo bisli", owner: "Wuzzy", verdict: ""),
    SentenceTatoeba(
      id: 4187766,
      text: "lu la kukis gerku gi'i mlatu li'u co'e .i lu nagi'e li'u co'e",
      owner: "Wuzzy",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 4208597,
      text: "xrisomasa di'i ca de'i li ly pare dy remu",
      owner: "Spheniscine",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 4220981,
      text: "lo bakrbisoni pe la .bufylos. ge'u poi lo bakrbisoni pe la .bufylos. cu cfipu ku'o " &
          "cu cfipu lo bakrbisoni pe la .bufylos.",
      owner: "",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 4225380,
      text: "ca lo nu co'a cikna ca lo cerni be lo cabdei kei, mi ganse lo ka milxe bilma",
      owner: "Spheniscine",
      verdict: "Stream Comma",
    ),
    SentenceTatoeba(
      id: 4225410,
      text: "puzuvukiku lo pa laldo ninmu cu xabju lo cmalu daplu",
      owner: "Spheniscine",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 4226728,
      text: "le nanmu de'a vasxu jecabo cu catlu le ninmu",
      owner: "Spheniscine",
      verdict: "Grammar selbri-5 135",
    ),
    SentenceTatoeba(
      id: 4285480,
      text: "uei'e mi'oi kelci",
      owner: "Spheniscine",
      verdict: "Stream Split",
    ),
    SentenceTatoeba(
      id: 4314037,
      text: "bazi mo'u si'ercarvi .ijebabo lo tcima za'ure'u zanmau",
      owner: "Wuzzy",
      verdict: "",
    ),
    SentenceTatoeba(id: 4412245, text: "ma du VFD", owner: "gleki", verdict: "Stream Shape"),
    SentenceTatoeba(id: 4423649, text: "ko'a ricfu nagi'enai misno", owner: "keegi", verdict: ""),
    SentenceTatoeba(
      id: 4429188,
      text: "ma stuzi lo me la .xakatas. me'u tcana",
      owner: "keegi",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 4436842,
      text: "gajanai la cevni na zasti gi sarcu fa lo nu finti ri",
      owner: "Spheniscine",
      verdict: "Grammar sumti-4 94",
    ),
    SentenceTatoeba(id: 4445171, text: "go'i a'ucu'i", owner: "", verdict: ""),
    SentenceTatoeba(
      id: 4587858,
      text: "do djica se gi'u bilga vau lo ka cikna",
      owner: "gleki",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 5180271,
      text: "mi ganse lo nu do na se spaji .i se ri'a bo mi jinvi lo du'u do pu la'a sai djuno",
      owner: "FB",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 5180319,
      text: "ki'u ma lo nu do tatpi na se jalge lo nu do sipnyzu'e .i lu ki'u lo nu ga nai ca " &
          "co'a sipna gi lo nu co'a cikna cu clirydu'e",
      owner: "FB",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 5180435,
      text: "lo mi bruna cu vajni mutce .i se ju ri jinvi lo du'u go'i",
      owner: "FB",
      verdict: "",
    ),
    SentenceTatoeba(id: 5180671, text: "do limna ka'e je'u nai pei", owner: "FB", verdict: ""),
    SentenceTatoeba(id: 5180692, text: "do to'e se .e'ande fi ku", owner: "FB", verdict: ""),
    SentenceTatoeba(
      id: 5181396,
      text: "mi djica lo nu lo ckafi",
      owner: "FB",
      verdict: "Grammar sumti-tail-1 112",
    ),
    SentenceTatoeba(id: 5181539, text: "ko stali bu'u nai lo srasu", owner: "FB", verdict: ""),
    SentenceTatoeba(id: 5181673, text: "je'e nai ke'o", owner: "FB", verdict: ""),
    SentenceTatoeba(
      id: 5181743,
      text: "mi''a na ka'e viska su'o da",
      owner: "FB",
      verdict: "Stream Apostrophe",
    ),
    SentenceTatoeba(
      id: 5183488,
      text: "la tom cu se birka pa je su'e da",
      owner: "FB",
      verdict: "Grammar sumti-5 95",
    ),
    SentenceTatoeba(
      id: 5185290,
      text: "mi se cmene lu .edgar.degas. li'u",
      owner: "FB",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 5912012,
      text: "Mi ca prami lo rirni.",
      owner: "Yuinpo",
      verdict: "Stream Stress",
    ),
    SentenceTatoeba(
      id: 6149232,
      text: ".i ku'i na ro mei lo srana .i la .tato'ebas. ge nai po'o gubni je jai se kansi'u je " &
          "so'i mei bo bangu ke jufra sorcu gi ji'a pagbu .ai su'o vanbi poi ma'a gunka lo ka " &
          "cazgau ke'a",
      owner: "FB",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 6671426,
      text: ".i ta'o to la'a ro da djuno toi mi na nelci",
      owner: "gleki",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 8613661,
      text: "mi nelci le ti pixra ki'u lo ka gu'enai misno gi mutce bo banli",
      owner: "shou",
      verdict: "",
    ),
    SentenceTatoeba(id: 8613675, text: "i'anai mi .enai do", owner: "shou", verdict: ""),
    SentenceTatoeba(
      id: 8639562,
      text: "mi ne facki da",
      owner: "shou",
      verdict: "Grammar relative-clause 122",
    ),
    SentenceTatoeba(id: 8648007, text: "mi nasai ai xrani le ninmu", owner: "shou", verdict: ""),
    SentenceTatoeba(id: 8671615, text: "la tom. na'eze'uba xrukla", owner: "shou", verdict: ""),
    SentenceTatoeba(
      id: 8721221,
      text: "mi zmadu le cnano fi lo kamjunmre be",
      owner: "shou",
      verdict: "Grammar linkargs 160",
    ),
    SentenceTatoeba(id: 8727985, text: "to'e ka'e sipna", owner: "shou", verdict: ""),
    SentenceTatoeba(id: 8732169, text: "li vu'u biboi ci du li mu", owner: "shou", verdict: ""),
    SentenceTatoeba(
      id: 8738058,
      text: "roda cu naku djuno",
      owner: "shou",
      verdict: "Grammar selbri-1 131",
    ),
    SentenceTatoeba(
      id: 8746149,
      text: "i a'u drata plini lisri i u'e ua bu'u lo darno plini ke blanu tsani la tsali e la " &
          "melbi cu remei solri i cusku fa lo verba fi le ri mamta fe lu i ga'inai io doi " &
          "dirba mamta bu'u le tsani ri'a ma ba'e remei solri li'u i le mamta cu cusku lu i " &
          "ga'i ue le preti cu mo i do zo'u ba'e xomei kanla i ju'ocai ba'e remei i do zo'u " &
          "ba'e xomei xance i ju'ocai ba'e remei li'u i le verba zo'u danfu fa lu i io e'inai " &
          "ku'i doi dirba mamta le mi nazbi cu pamei po'o li'u",
      owner: "nonong",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 8864864,
      text: "za'adai mi jai cafne sei .u'i mi lazni se'u co cusku be zo co'e",
      owner: "la_kanba",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 9144819,
      text: "lo ricfu cu je'ucu'i zmadu lo pindi lo ka gleki lifri",
      owner: "shou",
      verdict: "",
    ),
    SentenceTatoeba(id: 9147599, text: "lo ckafi ku a'unai", owner: "shou", verdict: ""),
    SentenceTatoeba(
      id: 10098327,
      text: "ba nu'i lo do nunsipna la'u lo mentu be li cino zo'u mi za'o cadzu",
      owner: "nabyspi",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 10739381,
      text: "mi'a te vecnu ta poi zdani ku'o ju'osai",
      owner: "nabyspi",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 10758564,
      text: "ma krasi lo ninmu .i ke'o",
      owner: "nabyspi3",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 10758616,
      text: "mi nelci ta noi skina ku'o ji'a",
      owner: "nabyspi3",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 10789002,
      text: "lo tuple be la .tam. cu jai fi'o ba'o klama fe'u pu cecla",
      owner: "nabyspi3",
      verdict: "Grammar tense-modal 815",
    ),
    SentenceTatoeba(id: 11998882, text: ".i je'e", owner: "Theocracy", verdict: ""),
    SentenceTatoeba(
      id: 12392246,
      text: ".i la .greg. tavla mi bu'u la .starbaks. pe la .lulus. zei daplu .i lisri le mi pu " &
          "gunka pe le la .gastaun. antike pagbu pe la .vankuvr. .i mi pu vu samru'e enge .i " &
          "la .gastaun. jibni la .tcainytaun. noi bu'u ke'a lo gusta cu so'imei .i bu'u la " &
          ".starbaks. zasti fa la .anas. .e la .djesikys. .i me la .baristas. .i flipo gi'e " &
          "vi'etnama .i mi pinxe lo bisli ke xekri ckafi .i mi citka la .apl. .tcip. .i la " &
          ".greg. dunda ra mi .i gy. citka lo badna titnanba .i gy. pinxe lo ckafi .i fa mi " &
          "tcidu fi la'o sy. Crónicas de Majipur .sy. .i mi viska la .stiv. noi mi rinsa ke'a " &
          ".i sy. speni la .xatcis. poi la .seneGAL. krasi ke'a .i mi viska lo sonci simsa " &
          "nanmu noi la .starbaks. vecnu lo ckafi ke'a .i lo vo melbi gunka cu pinxe lo ckafi " &
          ".i li ny renorevo ly ci dy rebi detri",
      owner: "nonong",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 12392641,
      text: ".i mi zvati la .vankuvr. .i .ui mi citka .i le la'o gy. Penny's .gy. gusta zo'u me " &
          "la .krim. .korn. .fic. .i la .crlis. jungo djabeipre .i le la .on. .lok. gusta zo'u " &
          "tadjrjulieni xarju cidjrlomeini .i li ny renonoci detri",
      owner: "nonong",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 12393230,
      text: ".i la .marlin. tavla mi .i ra tcidu lo cukta bu'u la .starbaks. .i la .marlin. poi " &
          "flipo ninmu cu speni lo fraso nanmu .i bu'u le ckafybarja lo glico nanmu .e lo " &
          "jungrkantoni nanmu cu tavla gi'e pinxe lo ckafi .i mi pinxe lo bisli ke xekri ckafi " &
          ".i mi citka la .sosidj. .tcedr. .eg. .sanduitc. .i la .les. poi ponjo ninmu cu te " &
          "vecnu lo ckafi .i me la .baristas. bu'u la .starbaks. .i me la .tcelsis. .e la " &
          ".anas. .e la .djesikys. .i jungrmandarina gi'e flipo gi'e vi'etnama .i le bartu " &
          "zo'u pu'o mulno xrulrmagnolia .i mi rinsa la .al. noi jbixa'u .i mi cusku lu la " &
          "cmalu crisa pu canci li'u .i lenku .i lo dilnu cu so'imei .i bu'u le mi zdani mi " &
          "tadni la .tcabakanos. poi flipo bangu .i li ny renorevo ly ci dy reso detri",
      owner: "nonong",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 12394640,
      text: ".i solgu'i cerni .i dilnu .i mi cadzu .i .a'u .ui .io ga'inai xrulrmagnolia .i me " &
          "la .starbaks. .i me la .baristas. bu'u le ckafybarja .i me la .djinas. .e la " &
          ".nabyxis. .e la .djesikys. .e la .soxairas. .e la .tcelsis. vu'o poi flipo gi'e " &
          "xindo gi'e vi'etnama gi'e xindo gi'e jungrmandarina .i mi pinxe lo bisli ke xekri " &
          "ckafi va le vimku'a .i bu'u lo drata jubme lo bunre nanmu cu remei .i fa mi tcidu " &
          "fi la'o sy. Crónicas de Majipur .sy. poi skefi'a .i bu'u le cimoi dargu pe la " &
          ".lulus. zei daplu la .rod. noi blabi prenu cu rinsa mi .i tavla fi lo ba ginka be " &
          "fi le la .alis. lalxu .i tavla fi lo sralo kutytu'a .e .la .arizonas. .i tavla fi " &
          "lo sralo liryraixa'u .i la .rod. speni la .djo'AN. poi vukro kadno .i li ny " &
          "renorevo ly ci dy cino detri",
      owner: "nonong",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 12395273,
      text: ".i ba'oki zo'o ctemidju senva .i se'o mi gasnu le du'u le grupesxu cu bofsru lo " &
          "barda kolbasa .i se'o mi cusku lu .u'i zo'o ko catlu le mi di'albo pe'a dacti poi " &
          "mi finti ke'a li'u .i li ny renorevo ly ci dy cipa detri",
      owner: "nonong",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 12396212,
      text: ".i lo xadycla ke melbi nanmu cu zvati la .starbaks. .i dasni lo blanu .i denpa lo " &
          "ckafi .i lo gugdrgoguro ke melbi ninmu cu zvati .i .o'u bu'u le ckafybarja mi pinxe " &
          "lo bisli ke xekri ckafi .i me la .baristas. .i me la .sarax. .e la .anas. .e la " &
          ".soxanas. .i glico gi'e flipo gi'e xindo .i le bartu zo'u solgu'i gi'e glare zmadu " &
          ".i vensa bu'u la .lulus. zei daplu .i li ny renorevo ly ci dy cipa detri",
      owner: "nonong",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 12396403,
      text: ".i solgu'i .i mi cadzu .i lo jbixa'u cu rinsa mi .i la .lindas. poi rindrkri ropno " &
          "mixre cu rinsa mi .i ly. gunka bu'u lo purdi .i la .djon. poi blabi prenu cu rinsa " &
          "mi .i la .sandras. poi jungo xindo mixre cu rinsa mi .i li ny renorevo ly ci dy " &
          "cipa detri",
      owner: "nonong",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 12397267,
      text: ".i va le vimku'a bu'u la .starbaks. lo xebro simsa nanmu cu sanli .i xekri xejykre " &
          ".i melbi .i bu'u le mi jubme lo jugypre poi kansa lo selbeiskami cu zutse .i ninmu " &
          ".i mi pinxe lo bisli ke xekri ckafi .i me la .baristas. .i me la .tanias. .e la " &
          ".anas. .e la .tcelsis. .e la .sarax. .i glico gi'e flipo gi'e jungrmandarina gi'e " &
          "glico .i le bartu zo'u solgu'i .i mi dasni lo zirpu je blanu creka .i li ny " &
          "renorevo ly vo dy pa detri",
      owner: "nonong",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 12401946,
      text: "ni'o me la .lojban. .i se'i .i'u le bantugulu cu verclibau mi .i .u'icai mi milxe " &
          "tadjyju'o lo runbau noi me le lojbo .e le spero .e le banginu'a .i ji'a mi milxe " &
          "tadjyju'o lo rarbau noi me le fraso .e le xispo .e le brazo .e lo latmo vrici .i " &
          "ji'a mi milxe djuno le ponjo .i ji'a mi milxe tadjyju'o lo bangu drata .i mi " &
          "nelcu'a lo runbau ne semau lo rarbau .i ju'aku'i mi nelci le du'u tadni lo " &
          "liryraixa'u bangu noi rindo gi'a bangiku'u gi'a sralo gi'a baxsyjavypolno gi'a " &
          "friko gi'a xazdo .i le xlobi zo'u mi djica le kesyske .e le zdili'u .e le mivyske " &
          ".e le cidja .e le runbau .e le .anme .e le skefi'a .i mi ba'o ze'a xabju le pongu'e " &
          ".i mi ca'o xabju le bemro .i fa mi pu jbena fo le gugdepuxe .i mi flipo",
      owner: "nonong",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 12406452,
      text: "la .ziri. cusku",
      owner: "Proxima5",
      verdict: "Grammar selbri 130",
    ),
    SentenceTatoeba(
      id: 12455452,
      text: ".i mi zvati le iptsa barja ba le nu ctemidju .i mi pinxe la .daiet. .kolys. .i la " &
          ".vinsent. pe'a tsuku .i remnrmongolo remnrkaukasu mixre .i melbi mutce .i citka lo " &
          ".iptsa .e lo cidjrlazania .i la .navdjot. poi xindrpanjabi cu nelci la .sag. poi " &
          "xindrpanjabi cidja .i vensa nicte .i li ny renorevo ly vo dy pabi detri",
      owner: "nonong",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 12455454,
      text: ".i bu'u la .starbaks. zei ckafybarja mi denpa la .greg. .i ri na tsuku .i la .ros. " &
          ".e la .djesikys. .e la .meris. cu me la .baristas. .i flipo jatna gi'e vi'etnama " &
          "gi'e flipo .i le du'u la .moris. du la .ros. cu xanri mi .i mi prami le mi xance .i " &
          "la .djesikys. casnu le ri lanzu .i casnu le lanzu tai la .sinderelias. .i le lanzu " &
          "pe la .djesikys. du le lanzu pe le se speni .i la .djesikys. speni lo jungo flipo " &
          "nanmu .i le bartu pe le ckafybarja zo'u la .marlin. poi flipo .e la .les. poi ponjo " &
          ".e lo jungo ninmu cu tavla .i pinxe lo ckafi .i le drata prenrbarista bu'u le " &
          "ckafybarja zo'u me la .djo'anas. .e la .fransis. vu'o poi glico gi'e rindrkri ropno " &
          "mixre .i solgu'i cerni .i li ny renorevo ly vo dy pabi detri",
      owner: "nonong",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 12455465,
      text: ".i solgu'i cerni .i bu'u la .starbaks. zei ckafybarja mi tavla la .greg. poi flipo " &
          ".i mi cusku lu lo grute cu nenri lo mexno cidjrlolipopo li'u .i mi cusku lu bu'u lo " &
          "mexno lo kadno je merko prenu cu xabju so'imei li'u .i mi pinxe lo bisli ke xekri " &
          "ckafi .i la .greg. pinxe lo la .xeizlnyt. bisli ckafi gi'e citka lo titnanba .i la " &
          ".greg. dasni le la .kynaks. .xakis. manfyta'u .i xekri gi'e xunre gi'e pelxu .i mi " &
          "cusku lu bu'u le la .strityvius. snanu gugdetuve mi pu viska lo blolo cange li'u .i " &
          "le cabdei zo'u li ny renorevo ly mu dy papa detri .i va le mi zdani mi cadzu bu'u " &
          "lo srasu foldi .i bu'u le berti lo blanu cmana cu zasti .i ga'u le cmana lo snime " &
          "cu zasti .i vitci tarmi spabi'u vi loi bunre zdani",
      owner: "nonong",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 12455486,
      text: ".i le mi lijda zo'u me la .sinkrytizm. .i ra'u mi budjo xanmi .i mi nelci lo budjo " &
          ".e lo dadjo .e lo xindo .e lo sralo lijda .e lo rindo lijda .e lo tolzi'o lijda .e " &
          "lo cendo .e lo vrici ke liryraixa'u lijda .i ra'unai mi krici do'e lo saske",
      owner: "nonong",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 12456290,
      text: ".i bu'u la .starbaks. zei ckafybarja mi citka la blolo dilnu titnanba to me la " &
          ".painapl. .klaud. .keik. toi .i kukte .i mi tavla la .anas. poi flipo ku'o lo clani " &
          "kerfa .i vi le drata jubme lo stuna fetsi cu zutse .i dasni lo xekri .e lo crino .i " &
          "le mi cadzu fa'a le mi zdani zo'u mi viska le gugdefuju pendo poi me la .molis. .e " &
          "la .sandras. .i li ny renorevo ly mu dy paci detri",
      owner: "nonong",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 12511016,
      text: "ni'o mi cikybi'o pu le du'u li ny renorevo ly xa dy paxa cy vo detri .i mi zvati le " &
          "mi sipku'a .i xu mi ba cmacti da",
      owner: "nonong",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 13090258,
      text: ".i coi .i mi'e la .pekas. .i ma cmene do",
      owner: "IronBeagle",
      verdict: "",
    ),
    SentenceTatoeba(
      id: 13820484,
      text: "lo prenu ca kelci la .beisbol.",
      owner: "rul",
      verdict: "Stream Cluster",
    ),
    SentenceTatoeba(
      id: 13874713,
      text: "sei jalge se'u ro lo prenu cu mrobi'o",
      owner: "rul",
      verdict: "",
    ),
  ]
    ## Sentences of sample, in order of number.
