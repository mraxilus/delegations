## Hold long articles of lojban Wikipedia, with verdict parser gave each paragraph, for suite.
##   Written by `nim r tools/build.nim wikipedia <directory>` from answers of API of
##   Wikipedia, SHA-256 `6bbe766025354f3dd9e7335ccd779cc8`
##   `68dbaddd9d8f2071eeb9680a0a3d0c21`; never edit by hand, run verb again.
##   Text of lojban Wikipedia, under licence CC BY-SA 4.0; folder holding module is
##     distributed under that licence, as `NOTICE.md` beside module gives, never under
##     licence of repository.

{.experimental: "strictFuncs".}


type
  ArticleWikipedia* = object  ## Define one article: title, and revision text comes from.
    title* {.requiresInit.}: string  ## Title of page.
    revision* {.requiresInit.}: int  ## Revision plain text comes from.

  ParagraphWikipedia* = object  ## Define one paragraph: article, place, text and verdict.
    article* {.requiresInit.}: string  ## Title of article holding paragraph.
    index* {.requiresInit.}: int  ## Place of paragraph in its article, from one.
    text* {.requiresInit.}: string  ## Line of plain text, as answer gives it.
    verdict* {.requiresInit.}: string  ## Refusal and rule parser gave; empty where read.


const
  ARTICLES_WIKIPEDIA* = [
    ArticleWikipedia(title: "cmaci", revision: 114271),
    ArticleWikipedia(title: "eliogabalus", revision: 107948),
    ArticleWikipedia(title: "lo jbobau", revision: 115608),
  ]
    ## Articles, in order of number of page as text.
  PARAGRAPHS_WIKIPEDIA* = [
    ParagraphWikipedia(
      article: "cmaci",
      index: 1,
      text: "ni'o loi cmaci goi ko'a cu saske le ka klani pe loi namcu ku",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "cmaci",
      index: 2,
      text: ".e le ka stura",
      verdict: "Grammar paragraphs 4",
    ),
    ParagraphWikipedia(
      article: "cmaci",
      index: 3,
      text: ".e le ka canlu .e le ka binxo",
      verdict: "Grammar paragraphs 4",
    ),
    ParagraphWikipedia(
      article: "cmaci",
      index: 4,
      text: ".i lo cmaci prenu .e lo pijyske prenu cu so'i mei jinvi fi le selkuspe be lo cmaci " &
          ".e le vlavelcki be lo cmaci",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "cmaci",
      index: 5,
      text: "ni'o gu lo cmacypre goi ko'e cu sisku lo morna .e lo ka namcu vu'o pe lo ko'e se " &
          "tadni gi ri me lo namcu .a lo canlu .a lo rarske .a lo skami .a lo sucta sidbo .i " &
          "ko'e finti lo cnino da'i zei jufra gi'e facki lo jetnu sepi'o lonu lojycpa .i la'a " &
          "le traji vajni terpli pe ko'a du le termu'eske goi ko'i noi pilno ko'a lonu tadni " &
          "lo te munje",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "cmaci",
      index: 6,
      text: "ni'o zo'e casnu lodu'u gonai lo cmaci datni goi ko'i cu je'a zasti ri'a le rarsi'o " &
          "pe le ko'i logji gi ko'i rutni gi'e drata be lo zasti .i la benjamin. pers. fi'o te " &
          "tavla ko'a cu cusku lu le saske noi lojycpa lo se nitcu jetnu li'u .ijeku'i la " &
          "albert. ainctain. cusku lu  ganai lo cmaci cu ckini lo zasti gi na se birti .ije " &
          "ganai se birti gi na ckini lo zasti  li'u",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "cmaci",
      index: 7,
      text: "ni'o sepi'o lonu sucta .e lonu logji pensi kei ko'a se krasi lonu kancu .e lonu " &
          "kanji .e lonu merli .e le ciste tadni be le tarmi .e le nunmu'u vu'o pe lo zasti " &
          "dacti .i lo sizyju'o .e lonu pilno vu'o pe le sampu cmaci puca roroi me lo vajni be " &
          "lo prenu je girzu nunji'e .i lo sampu cmaci sidbo pu se krasi vi le tcepru " &
          "misrygu'e je raksygu'e je xingu'e je jugygu'e je xesygu'e je muslo kulnu .i lo " &
          "pluja cmaci seltcidu cu pamoi se krasi je se finti lo xelso cmacypre rai lai jicmu " &
          "pe la .euklides.",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "cmaci",
      index: 8,
      text: "ni'o zo cmaci se krasi lo lojbo krasi bangu valsi po'u la'o jy cuciue — 數學 " &
          "(数学) [shù xué] jy bau le jugbau ku .e la'o gy matamatiks — mathematics gy " &
          "bau le glibau ku .e la'o xy ganit — गणित [gaṇita] xy bau le xinbau ku " &
          ".e la'o sy matematik — matemáticas sy bau le sanbau ku .e la'o ry matimatik — " &
          "математика [matematika] ry bau le rukybau .i ri se krasi bau le xesybau " &
          "la'o xy μάθημα (máthēma) xy noi se smuni lonu tadni .a lonu cilre .a lo " &
          "saske",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "cmaci",
      index: 9,
      text: "ralju ci'arvelski fa lu cmaci citri li'u",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "cmaci",
      index: 10,
      text: "ni'o le citri be lo cmaci cu ka'e te jimpe fe lo porsi be loi nu sucta .i la'a le " &
          "pamoi sucta noi ji'a lo danlu cu ponse cu namcu .iva'i du'u fi da fa re plise fe re " &
          "najnimre cu ckini .i",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "cmaci",
      index: 11,
      text: "ni'o fi'o jmina lonu kancu lo dacti to mu'a plise ja najnimre toi kei lo tcepru " &
          "prenu cu kancu lo sucta ni namcu to mu'a djedi ja nanca toi .i lo jicmu nu kanji " &
          "kei pu zasti bazi la'e di'u",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "cmaci",
      index: 12,
      text: "ni'o lo balvi citri ve pruce pe lo cmaci nu farvi kei pu nitcu lo kancu ciste to " &
          "mu'a lo skori jgena noi lai .inkas. pilno ke'a lonu vreji lo namcu toi .i lo kancu " &
          "cilste zupu so'imei je mutce drata .i le pamoi selci'a nacle'u pu se finti lo " &
          "tcepru misro",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "cmaci",
      index: 13,
      text: "ni'o lo tcepru traji te pilno pe lo cmaci du lonu vecnu .e lonu tumla nu merli .e " &
          "lo cintypejgau je jivbu vreji .e lonu vreji lo temsi'o .e noda poi mutce zmadu " &
          "certu pu ji'i le ni'u3000moi noi ca lo tcepru rakso .e lo misro cu pilno lo zmadu " &
          "certu cmaci .iku'i lo drani nu tadni be lo cmaci pu cfari zu'e lo tcepru xelso ca " &
          "le ni'u 600moi ku bi'o le ni'u 300moi",
      verdict: "Stream Letter",
    ),
    ParagraphWikipedia(
      article: "cmaci",
      index: 14,
      text: "ni'o ba la'e di'u lo cmaci cu mutce farvi .ije lonu mutce se pilno sizyki'i be fa " &
          "lo cmaci bei lo saske kei pu fasnu .i lo cmaci nu facki kei pu fasnu ca le mulno " &
          "citri .e dazi",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "cmaci",
      index: 15,
      text: "ralju ci'arvelski fa lu cmaci ciska ciste li'u",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "cmaci",
      index: 16,
      text: "ni'o piso'a lo cmaci ciska ciste poi se pilno cazi cu pu se finti ba le 16moi " &
          "ctona'a  .i pu la'e di'u lo cmaci pu se cusku ci'e lo valsi .i lo nu go'i cu pu " &
          "nandu se gunka gi'e zunti lo cmaci nu facki .i ca le 18moi na'acto la .oiler. pu " &
          "finti so'i lo ciska ciste noi se pilno cazi .i lo cabna ciska ciste cu gasnu le " &
          "du'u lo cmaci cu mutce zmadu frili pi'o lo certu .ijeku'i lo to'e certu cu lifri " &
          "loza'i nandu .i so'u sinxa cu se smuni so'a datni",
      verdict: "Stream Letter",
    ),
    ParagraphWikipedia(
      article: "cmaci",
      index: 17,
      text: "le cmaci bangu cu la'a nandu lo to'e certu .i lo valsi befa mu'i zo .a .e zo .o cu " &
          "se smuni lo satci zmadu be lo rarbau valsi .i le cmaci bangu cu runbau .i ji'a so'i " &
          "valsi cu steci se smuni lo na'e rarbau smuni .iku'i lo mukti be lo steci smuni cu " &
          "zasti .i ko'e te cmene le ti ka satci lu ka lojdra li'u",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "cmaci",
      index: 18,
      text: ".i lo cmaci cipra cu ra'u ckini lo ka lojdra .i lo cmacypre cu djica ledu'u le ri " &
          "cmacrteorema cu se lojycpa fi lo .aksioma .i la'edi'u co'e mu'i loza'i rivbi lo " &
          "jitfa se djuno to so'e mupli be ri cu zasti ca le cmaci citri toi .i loni lojdra " &
          "noi se la'erji'i cu pu vrici .i lo tcepru xelso pu la'erji'i lo clani nuncasnu " &
          ".iku'i ca la .aisak.niuton. le cmaci tadji pu mleca fi lo ka lojdra .i lo se srera " &
          "be la .niuton. pu mukti lenu lo ka lojdra cu pu se xrupli ca le 19xyxy ctona'a .i " &
          "loi cmacypre cazi casnu lo skami se sidju cipra .i ki'u ledu'u lonu lo clani nu " &
          "kanji cu cipra birti cu nandu keikei ri cu la'acu'i na banzu lojdra",
      verdict: "Stream Letter",
    ),
    ParagraphWikipedia(
      article: "cmaci",
      index: 19,
      text: "ni'o loi .aksioma cu so'aroi terji'i lo sapselja'a jetnu .iku'i le di'u sidbo cu te " &
          "nabmi .i ci'e lo lojdra lo .aksioma cu porsi be lo sinxa noi se smuni ci'e lo ri te " &
          "lojycpa pe le aksioma ciste .i le selpla be la .xilbert. zu'edji lonu gasnu loza'i " &
          "lo cmaci cu se jicmu lo jdari ke .aksioma jicmu .iku'isai cu'u le kamnarmu'o " &
          "cmacrteorema pe la .godel. piro .aksioma ciste cu se cmima lo jufra poi na kakne " &
          "jdice lo ka jetnu pe ke'a .iseni'ibo le nu mulno .aksioma binxo pe lei cmaci cu na " &
          "cumki .iku'i loi cmaci cu so'aroi se xanri ci'e lo klesi termonsi'o .iva'i da'i " &
          "piro cmaci jufra cu se cuskyka'e bau le klesi termonsi'o",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "cmaci",
      index: 20,
      text: "ni'o la .karl.fridrix.gaus. pu skicu lo cmaci fo lo se fanva be fu lu noltrini'u lo " &
          "saske li'u .i zo saske bau la lojban cu se smuni loi fatci .i ci'e le purci smuni " &
          "lo cmaci cu je'a saske .i le si'o rarna saske cu balvi le di'e smuni .i ganai lo " &
          "saske cu saske lo rarna po'o gi lo cmaci cu na saske",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "cmaci",
      index: 21,
      text: "ni'o so'i pijyskepre cu jinvi ledu'u lo cmaci cu na jifcipra selka'e .iseki'u bo na " &
          "saske du'o le smuni pe la karl.poper .iku'isai de'i le 193xymoi ku so'i cipyple pe " &
          "la kurt.gydel pu cipra ledu'u lo cmaci na ka'e se smuni lo logji .iseki'ubo la " &
          "karl.poper pu lojycpa ledu'u so'a lo cmaci jufra cu simsa lo rarna jufra loka lifri " &
          "bo nibli",
      verdict: "Stream Letter",
    ),
    ParagraphWikipedia(
      article: "cmaci",
      index: 22,
      text: "ni'o lo cmaci pu cfari ca lo namcu .i loi kacna'u pu pamoi .i loi mulna'u .e loi se " &
          "kanji befi ri pu remoi .i lo traji pluja ke namcu selkai cu se saske lo nacycmaci " &
          ".i ri cu se krasi lo banli cmacrteorema no'umu'a le fermat.zei romoi cmacrteorema " &
          ".i le nacycmaci cu ji'a se krasi re mutce vajni nabmi poi na se dansu zi'e po'u le " &
          "remei nalfendi kacna'u selti'i .e le .goldbax.zei selti'i",
      verdict: "Grammar sumti-tail-1 112",
    ),
    ParagraphWikipedia(
      article: "cmaci",
      index: 23,
      text: "ni'o lonu farvi pe le nacycmaci pu nibli ledu'u loi mulna'u cu cmima loi dilcyna'u " &
          ".iji'a ri cmima loi pavycimdyna'u .iji'a ri cmima loi relcimdyna'u .i ri go'i loi " &
          "voncimdyna'u .i ri go'i loi bivycimdyna'u .i lo nu tadni pe loi kacna'u cu nibli " &
          "loi zmacimnyna'u .i me lo drata namcu ku fa loi memna'u .e loi .alef.zei namcu",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "cmaci",
      index: 24,
      text: ".i vrici ke namcu klesi fa",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "cmaci",
      index: 25,
      text: "gud.uil.xyntin",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "cmaci",
      index: 26,
      text: ".i vrici cmaci fa",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "cmaci",
      index: 27,
      text: "lo sizykanji .i",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "cmaci",
      index: 28,
      text: "lo .algebra .i",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "cmaci",
      index: 29,
      text: "lo gricmaci noi srana loi sujgri .e loi piljygri .e loi dilcygri ku'o .i",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "cmaci",
      index: 30,
      text: "lo jgacmaci .i",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "cmaci",
      index: 31,
      text: "lo cibjgataicmaci .i",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "cmaci",
      index: 32,
      text: "lo veldilcycmaci",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "eliogabalus",
      index: 1,
      text: "ni'o ni'o no mo'o la eliogabalus goi ko'a jbena fi li ji'i no re no ci gi'e mrobi'o " &
          "de'i li no re re re pi'e no ci pi'e pa pa gi'e nolraitru lo latmo sosygugje'a de'i " &
          "li no re pa bi bi'o no re re re gi'e se trulanzu zo'e pe la sE,uerus .i ko'a prurai " &
          "se cmene zoi zoi Varius Avitus Bassianus zoi gi'e turni se cmene zoi zoi Marcus " &
          "Aurelius Antoninus zoi .i ko'a se rorci la iulias so,aimias la sekstus uarius " &
          "markelus .i ko'a ca lo nu citno cu jdaca'i selfu la noi cevni el gabal bu'u la " &
          "emesas noi vo'a xabju ke'a .i ja'e bo ko'a se cmene zoi zoi Heliogabalus zoi a zoi " &
          "zoi Elagabalus zoi lo circre",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "eliogabalus",
      index: 2,
      text: "ni'o la noi nolraitru karakaluas de'i li no re pa ze cu se zercatra gi'e te basygau " &
          "la markus opelius makrinus noi catnrpraifektupraitoriu se va'u ky .i la iulias " &
          "maisas goi fo'a noi fetfamti ky cu snada lo nu vo'a xlura lo nu le ci moi " &
          "jenmrlegione ne la galias cu flapro te zu'e lo nu lo du'u la eliogabalus noi " &
          "tolcitrai lo'i pazbersa be fo'a cu ba basti nolraitru cu se xusra .i la makrinus cu " &
          "te jinga de'i li no re pa bi fo lo nunda'a be bu'u la antioxei,as .i ja'e bo la " &
          "eliogabalus noi ke'a pu zi co'a nanca li pa vo cu binxo lo nolraitru .i je bo cfari " &
          "fa lo nu ko'a turni poi xlali ckaji lo ka ce'u se darlu se casnu",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "eliogabalus",
      index: 3,
      text: "ni'o la eliogabalus ca lo nu ko'a turni cu na'e sinma lo latmo ke lijda ja cinse " &
          "tcaci .i mu'a ko'a mu roi spebi'o .i je bo lo du'u ko'a nungle vecnu da'i ne'i lo " &
          "nolraitru zdani cu te jungau .i la eliogabalus cu basygau fi la iupiter noi ralju " &
          "lo'i latmo cevni ku'o fe la sol inuiktus noi cnino cevni ku'o .i mu'a nai je bo " &
          "ko'a bapli gasnu lo nu lo vajni se trugunma cu se gidva ko'a lo nu jdasi'a lo se " &
          "go'i",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "eliogabalus",
      index: 4,
      text: "ni'o la eliogabalus zenba lo ka ce'u se fapro .i va'o bo ko'a se catra gi'e se " &
          "basti la aleksandr seuerus noi ke'a tamne ko'a ku'o de'i li no re re re pi'e no ci " &
          "pi'e pa pa .i bo la'e di'u se platu la iulias maisas noi ke'a mamymamta ko'a ku'o e " &
          "su'o re bandu se bendrpraitoriu .i la eliogabalus binxo lo misno be lo cabna ri'a " &
          "lo nu ko'a tarti be lo cizra be'o je tolvrude je jdacai cei broda .i bo la'a lo ni " &
          "lo du'u ko'a broda cu se xusra lo selyli'e be ko'a cu zmadu lo ni je'u ko'a broda " &
          ".i ja'e bo ko'a zmadu da'a so'u lo latmo nolraitru lo ni ce'u se xebni lo purci ke " &
          "xriso circre",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "eliogabalus",
      index: 5,
      text: "ni'o la eliogabalus jbena fi li no re no ci fi'o cmene zoi zoi Varius Avitus " &
          "Bassianus zoi .i ko'a se rorci la iulias soaimias basianas la sekstus uarius " &
          "markelus .i lo patfu be ko'a pu noblrxekuite ce'o catnrsenatore .i la iulias maisas " &
          "noi mamymamta ko'a ku'o pu speni la iulius auitus noi ke'a ca morsi zi'e noi ke'a " &
          "catnrkonsule ku'o gi'e mensi la iulias domnas noi ke'a speni la noi ke'a nolraitru " &
          "septimius seuerus .i la iulias soaimias tamne la noi ke'a nolraitru karakaluas .i " &
          "je la noi ke'a famti ko'a iulias auitas mamaias fi la noi ke'a speni be ri markus " &
          "iulius gesius markianus rorci fe la aleksandr seuerus .i lo lanzu be la eliogabalus " &
          "cu cedra jdaca'i se va'u la el gabal noi ke'a solri cevni .i ko'a ralju jdaca'i se " &
          "va'u ra bu'u la emesas to noi ke'a nau se cmene zo ximys toi ne tu'i la sirxygug",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "eliogabalus",
      index: 6,
      text: "ni'o lu el gabal li'u cmene lo cevni po'e la emesas noi ko'a jbena fo ke'a .i zo el " &
          "cmene lo ralju ke semto cevni .i zo gabal noi se fanva fu zo cmana zi'e noi ko " &
          "karbi ke'a zoi zoi גבול gyvul zoi noi xebro ku'o e zoi zoi جبل djebel zoi " &
          "noi xrabo cu cmene lo se go'i bu'u la emesas .i la el gabal e le latmo ke solri " &
          "cevni noi la sol indiges cmene ke'a ca lo nu ka'irje'a zi'e noi la sol inuiktus " &
          "cmene ke'a ca lo pa moi je re moi ctona'a cu ba za se gunma .i se ki'u bo zoi zoi " &
          "Heliogabalus zoi cmene ko'a lo circre",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "eliogabalus",
      index: 7,
      text: "ni'o ca lo nu la makrinus binxo lo nolraitru kei my troci lo nu fanta lo nu lo nu " &
          "my turni cu se ckape lo nu lo no'a cu se fapro lo lanzu be la karakaluas noi ke'a " &
          "lamli'e my gi'e pu se catra be'o no'u la goi fo'a iulias maisas e lo re tixnu be " &
          "fo'a be'o e la eliogabalus noi tolcitrai lo'i pazbersa be fo'a .i ta'i bo my minde " &
          "lo nu lo bi'u nai lanzu cu klama lo zdani tutra po'e lo nei ge'u pe bu'u la " &
          "sirxygug .i fo'a e la ganius noi ke'a gantycau gi'e sidju fo'a gi'e ctuca la " &
          "eliogabalus ku'o ba zi lo mu'e fo'a ba'o klama la sirxygug cu co'a platu lo nu " &
          "bapli basygau la makrinus .i bo fo'a jdice lo nu fo'a gasnu lo nu la eliogabalus " &
          "noi ke'a nanca li pa vo cu nolraitru .i la eliogabalus e lo mamta be ko'a cu djica " &
          "zanru lo se go'i .i je lo go'i cu gubjungau lo jitfa du'u ko'a bersa la karakaluas " &
          ".i se ki'u bo lo sonci e lo catnrsenatore vu'o poi ke'a pu junri nupre lo nu ke'a " &
          "selfu la karakaluas cu bilga lo nu selfu ko'a .i ba lo nu la iulias maisas jarco lo " &
          "ka lo nei cu ricfu kei le ci moi soncrlegione bu'u la rapanas kei lo go'i cu junri " &
          "nupre lo nu selfu la eliogabalus .i de'i li no re pa bi pi'e no mu pi'e pa xa ca lo " &
          "cermurse la publius ualerius komazdon eutiuxianus noi jatna lo bi'u nai " &
          "soncrlegione cu xusra lo du'u ko'a nolraitru .i bo ko'a xlura fi lo nu lo du'u ko'a " &
          "flalu turni cu se krici kei lo nu ko'a ko'a te cmene lo cmene be la karakaluas be'o " &
          "no'u lu markus aurelius antoninus li'u .i la makrinus spuda la'e di'u lo nu klacpe " &
          "fi la sirxygug fe la ulpius iulianus noi soncrpraifektupraitoriu ku'o e lo pa sonci " &
          "bende poi u bu .i bu krici lo du'u ke'a tsali banzu lo nu vlile sisti lo bi'u nai " &
          "nu fapro .i je ku'i lo bi'u nai bende cu ba zi cmibi'o lo bende po la eliogabalus " &
          ".i bo sa'e lo go'i ca'o lo nu damba cu co'a fapro lo jatna be vo'a .i lo se go'i cu " &
          "se catra .i je lo stedu be u bu .i bu cu xruti se bevri lo nolraitru .i ba zi bo ri " &
          "te xatra loi catnrsenatore lo du'u la eliogabalus cu jitfa me la antoninus kei e lo " &
          "du'u ko'a menli bilma .i lo re catnrkonsule e lo drata ke vlipa latmo catni cu " &
          "xusra co fapro ko'a .i ba bo loi catnrsenatore cu xusra lo du'u lo latmo jecta cu " &
          "jamna la eliogabalus joi la iulias maisas",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "eliogabalus",
      index: 8,
      text: "ni'o la makrinus e la diadumenianus noi bersa my vu'o noi ke'a ba'o se bleri'a lo " &
          "nu le re moi soncrlegione cu cliva lo no'a ri'a lo nu la iulias maisas nupre gi'e " &
          "pleji fi ly cu damba te jinga de'i li no re pa bi pi'e no xa pi'e no bi bu'u la " &
          "antioxeias fi lo jenmi be fi'o jatna la ganius .i la makrinus cliva fa'a la italias " &
          "fi'o tcica selmlu lo ka ce'u xelmri .i je ba za bo lo sevzi be my cu se tolmipri vi " &
          "la xalkedont .i je my se catra bu'u la kapadokias .i la diadumenianus poi troci lo " &
          "nu ke'a ti'i klama lo nolraitru zdani pe la ackanian cu se kavbu bu'u la zdeugmat " &
          "gi'e ji'a se catra",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "eliogabalus",
      index: 9,
      text: "ni'o la eliogabalus xusra lo du'u ko'a co'a turni se de'i lo nu jinga fo lo bi'u " &
          "nai nu damba be bu'u la antioxeias .i je ko'a co'a se cmene lo nolraitru je selsi'a " &
          "pu lo nu loi catnrsenatore cu zanru lo nu no'a kei kei noi tcaci .i je ku'i so'i " &
          "nolraitru be ca lo ci moi ctona'a cu go'i .i se mrilu fi la romas fa lo faxsi'u " &
          "notci be lo nu friti lo nu fraxu loi catnrsenatore kei kei e lo nu xusra lo du'u ei " &
          "loi flalu cu se tinbe kei e lo du'u lo nu my e lo bersa be ri cu turni cu xlali .i " &
          "loi catnrsenatore cu spuda la'e di'u lo nu tugni xusra lo du'u la eliogabalus ja'a " &
          "nolraitru gi'e bersa la karakaluas .i je lo go'i cu junri xusra lo du'u la " &
          "karakaluas e la iulias domnas cu cevni .i je la iulias maisas e la iulias soaimias " &
          "cu co'a selsi'a je jmina selme'e zoi zoi Augusta zoi .i loi catnrsenatore cu xusra " &
          "co fapro la makrinus e la diadumenianus .i la komazdon noi jatna le ci moi " &
          "soncrlegione cu gau binxo lo jatna be lo bandu bendrpraitoriu",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "eliogabalus",
      index: 10,
      text: "ni'o la eliogabalus e lo bende be fi ri ca lo dunra be li no re pa bi cu zvati la " &
          "nikomedeias pe se di'o la bitiunias .i ca bo lo terjda be ko'a cu co'a nabmi .i la " &
          "kasius dion noi cabna circre cu xusra lo du'u la ganius cu se catra ko'a ki'u lo nu " &
          "gy gasnu lo nu ko'a bai tarti lo ka ko'a vrude .i la iulias maisas te zu'e lo nu " &
          "sidju loi latmo lo nu ri kufra lo nu lo semto jdaca'i cu nolraitru lo se no'a cu " &
          "gasnu lo nu lo pa pixra be fo lo cinta bei fe la eliogabalus pe fi'o taxfu lo " &
          "jdaca'i cu se mrilu fi la romas gi'e se dadgau ga'u lo rokyxra be la noi cevni " &
          "viktorias bei ne'i lo catnrsenatore dinju .i ja'e bo loi catnrsenatore cu tolkufra " &
          "se tcini lo nu lo no'a cu bilga lo nu lijda dunda fi ga nai la viktorias gi la " &
          "eliogabalus",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "eliogabalus",
      index: 11,
      text: "ni'o lo nu lo jenmi cu co'a xanka cu jalge lo se tarti be ko'a .i je jy co'a xenru " &
          "lo nu jy sragau fi lo nu ko'a nolraitru .i ca'o lo nu ko'a klama la romas kei le vo " &
          "moi soncrlegione gau la gelius maksimus ze'i fapro .i je ji'a go'i fa le ci moi " &
          "soncrlegione be fi'o jatna la noi catnrsenatore uerus be'o poi ke'a sa'e fuzme lo " &
          "nu ko'a nolraitru .i lo bi'u nai fapro cu sutra te jinga .i je le ci moi " &
          "soncrlegione gau ku co'u zasti",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "eliogabalus",
      index: 12,
      text: "ni'o ca lo nu lo bende be fi ko'a cu mo'u klama la romas ca lo critu be li no re pa " &
          "so kei la komazdon e lo drata pendo be la iulias maisas e la eliogabalus cu gau " &
          "vlipa je ricfu catni .i bo la'e di'u fegri'a so'i catnrsenatore poi ke'a jinvi lo " &
          "du'u lo go'i cu na'e vrude .i la komazdon ba lo nu ri mo'u soncrpraifektupraitoriu " &
          "cu ci roi catnrpraifektu la romas gi'e re roi catnrkonsule .i la eliogabalus troci " &
          "lo nu gasnu lo nu la ierokles noi lo du'u ke'a gletu ko'a cu se sruma cu " &
          "catnrkaisare cei va'i bavla'i nolraitru .i je la zotikus noi lo du'u ke'a ji'a " &
          "gletu ko'a cu se sruma cu gau vlipycau je ku'i xlura catnrkubikulariu .i sa'e nai " &
          "lo nu ko'a friti lo nu fraxu su'o re catni cu se sinma .i je ku'i lo nu la ulpianus " &
          "noi ke'a flacre cu cliva la romas cu te minde",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "eliogabalus",
      index: 13,
      text: "ni'o la iulias maisas ce la iulias soaimias ce la eliogabalus ca zi lo nuncfa be lo " &
          "nu ko'a turni cu simxu lo nu lo no'a cu carmi xendo .i lo mamta be ko'a be'o e lo " &
          "mamymamta be ko'a cu pa moi ja re moi lo'i fetsi catnrsenatore .i je to'u lo go'i " &
          "cu co'a se cmene zo'e pe lo catnrsenatore .i to'u nai la soaimias go'i zoi zoi " &
          "Clarissima zoi noi fadni .i je bo la maisas go'i zoi zoi Mater Castrorum et Senatus " &
          "zoi noi nalfadni .i la iulias maisas troci lo nu binxo lo jetnu jatna no'u va'i lo " &
          "traji be lo ka vlipa bei fo lo'i ro ninmu .i ca bo la eliogabalus mutce zifre gi'e " &
          "tolcenba lo ka ce'u tarti kei gi'e nai ka'e se jitro",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "eliogabalus",
      index: 14,
      text: "ni'o ba lo nu la septimius seuerus co'a turni kei loi seljda co cevni be lo solri " &
          "cu zenba bu'u lo latmo jecta .i se mu'i bo la eliogabalus gasnu lo nu la el gabal " &
          "goi ko'e ralju cevni ma'i lo latmo ke cevni girzu .i ko'e co'a se cmene zoi zoi " &
          "Deus Sol Invictus zoi no'u va'i lu narterjinga solri cevni li'u .i je lo du'u ko'e " &
          "balmau la iupiter cu se xusra .i la eliogabalus gasnu lo nu ko'e speni la astartet " &
          "a la mineruas a la uranias a lo gunma be lo bi'u nai ci cevni .i je la'e di'u sinxa " &
          "lo nu lo latmo lijda ce lo lijda pe ko'e cu se gunma .i ja'e lo nu lo du'u ko'a " &
          "tolvrude cu za'u re'u se jinvi kei ko'a spebi'o la akuilias seueras noi nu'ogle ke " &
          "lijda selfu la uestas ku'o mu'i lo du'u ko'a e lo se no'a cu ba rorci lo cevysmi " &
          "fi'o krici ko'a .i go'i fi lo carmi toltcaci ni'i la'e di'e .i da poi ke'a selfu la " &
          "uestas zo'u lo nu lo du'u da cu ba'o gletu cu se facki cu se jalge lo nu da jmive " &
          "se derse'a",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "eliogabalus",
      index: 15,
      text: "ni'o la eliogabalium noi ke'a malsi cu kargu se zbasu bu'u lo stuna sefta be la noi " &
          "cmama'a paluatinas te zu'e lo nu lo no'a cu zdani la el gabal noi ke'a se krati lo " &
          "pa xekri je konju ke kensa rokci be ra'i la emesas .i la erodianus finti cusku lu " &
          "lo bi'u nai rokci cu lijda se sinma fi'o se krici lo du'u ry gau farlu fi lo cevzda " &
          ".i so'o cmalu punli jo'u barna cu zvati lo sefta be ry .i lei prenu cu jarco la'e " &
          "di'u gi'e djica lo nu krici lo du'u lo go'i cu mlimapti pixra lo solri kei kei ki'u " &
          "lo nu ra simlu lo ka jetnu kei lo no'a li'u .i te zu'e lo nu binxo lo ralju jdaca'i " &
          "be lo cnino lijda pe ko'a kei lo crane gacri be lo pinji be ko'a ca'i ko'a cu se " &
          "katna se vimcu .i ko'a bapli gasnu lo nu loi catnrsenatore cu catlu lo nu ko'a " &
          "dansu mo'i ru'u lo malsi jubme pe la sol inuiktus lo skapi damri ku jo'u lo jinme " &
          "damri .i je ko'a minde fi lo nu lo bi'u nai cevni ca ro lo co'a crisa cu se salci " &
          "fi zo'e noi so'a nalno'i cu nelci ke'a ki'u lo nu pi so'i cidja cu fatri .i ca lo " &
          "bi'u nai nunsla ko'a punji lo bi'u nai rokci be ra'i la emesas lo pa carce co se " &
          "jadni be lo solji ku jo'u lo jemna gi'e junri litru pi so'a le tcadu .i finti se " &
          "cusku fa",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "eliogabalus",
      index: 16,
      text: "lu lo bi'u nai cevni cu se carce fi lo xa xirma noi ke'a tcebra gi'e cficau blabi " &
          "gi'e se jadni lo solji ku jo'u lo kargu .i no prenu cu jgari lo selri'u skori gi'a " &
          "se carce lo se go'i noi ke'a se kansa fi'o selmlu lo ka lo bi'u nai je'a cevni cu " &
          "sazri lo se go'i .i la eliogabalus ca'u lo bi'u nai carce cu mo'i ti'a bajra gi'e " &
          "ca crane lo bi'u nai cevni vo'a gi'e ca jgari lo selri'u skori .i lo go'i cu mo'i " &
          "ti'a bi'u nai mulno litru gi'e ca catlu lo flira be lo cevni pe vo'a li'u",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "eliogabalus",
      index: 17,
      text: "i la eliagabalium cu te bevri fo lo malsi pe vo'e fe lo tcecensa ke latmo lijda " &
          "dacti no'u la'e zoi zoi Magna Mater zoi ce lo fagri pe la uestas ge'u ce loi badgai " &
          "pe la'e zoi zoi Salii zoi ge'u ce la'e zoi zoi Palladium zoi ce lo drata te zu'e lo " &
          "nu la el gabal po'o se lijda se sinma",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "eliogabalus",
      index: 18,
      text: "ni'o so'i da simxu toltu'i fo lo te cinse be fi la eliogabalus .i ko'a cu spebi'o " &
          "ce'o spesti mu lo ninmu .i je ci lo bi'u nai ninmu cu te djuno .i la iulias " &
          "kornelias paulas pa moi lo'i bi'u nai speni .i la noi nu'ogle ke lijda selfu la " &
          "uestas ku'o akuilias seueras re moi lo'i speni be ko'a .i je ku'i ko'a ba zi lo " &
          "nanca be li me'i pa cu cliva lo go'i gi'e spebi'o la anias faustinas noi se dzena " &
          "la markus aurelius gi'e pu speni lo pa pu zi se catra be la eliogabalus .i pu lo nu " &
          "le nanca cu se fanmo kei ko'a za'u re'u spebi'o la seueras .i cu'u la kasios dion " &
          "traji lo ka lo nu ko'a ce'u prami cu stodi kei fa la ierokles noi ke'a sazri lo " &
          "carce po ko'a zi'e noi lo kerfa be ke'a cu pelxu zi'e noi la karias krasi ke'a zi'e " &
          "noi zo speni cmene ke'a ko'a .i la kasios dion jungau fi lo du'u la eliogabalus " &
          "ta'e jadgau lo cinta lo kanla gacri gi'e ta'e vimcu lo kerfa gi'e ta'e dasni lo " &
          "rutni kerfa gi'e ta'e vecnu lo nu ko'a se gletu ne'i lo barja e lo nungle zarci e " &
          "ji'a lo nolraitru zdani .i finti se cusku fa",
      verdict: "Stream Breakup",
    ),
    ParagraphWikipedia(
      article: "eliogabalus",
      index: 19,
      text: "lu ro mai ko'a cuxna lo pa kumfa be lo nolraitru zdani .i je ko'a bu'u ri cu ta'e " &
          "tolvrude zukte .i ko'a ta'e lunbe sanli vi lo vorme be lo bi'u nai kumfa se pa'a " &
          "lo'e nungle vecnu gi'e ta'e desygau lo murta noi dandu lo djine be lo solji ku'o " &
          "gi'e ta'e friti fi lo mo'i zo'a cadzu se pi'o lo voksa co jai toljursa li'u",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "eliogabalus",
      index: 20,
      text: "i la erodian te pinka fi lo se du'u lo ka ko'a jadgau lo cinta lo flira be ko'a cu " &
          "cfila fi lo nu lo rarna melbi flira cu jdika lo ka ce'u simlu lo ka ce'u melbi .i " &
          "ko'a se skicu fo lo ka ce'u tcenei lo nu ko'a se cmene lu lo selgle be la ierokles " &
          "li'u a lu lo fetspe be .i bu li'u a lu lo nolraifetspe be .i bu li'u .i je go'i fo " &
          "lo ka ce'u friti lo nu ko'a pleji lo rupnu be li so'i lo mikce lo nu ri snada gasnu " &
          "lo nu ko'a se vibna",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "eliogabalus",
      index: 21,
      text: "ni'o de'i li no re re pa lo cizra se tarti be la eliogabalus be'o e mu'a su'a nai " &
          "lo nu ko'a la ierokles prami cu pu ca'o rinka lo nu lo bandu bendrpraitoriu cu " &
          "zenba lo ka ce'u fengu .i la iulias maisas sanji lo nu lo nolraitru cu sutra jdika " &
          "lo ni ko'a ce'u se nelci .i se mu'i bo lo go'i cu jdice lo du'u lo nu te basygau fa " &
          "ko'a e lo mamta be ko'a be'o noi ke'a zanru lo se lijda be fi ko'a kei cu se bilga " &
          ".i je lo go'i cu cuxna la iulias auitas mamaias noi ke'a drata tixnu e la seuerus " &
          "aleksandr noi ke'a bersa ri gi'e nanca li pa ci .i lo go'i cu snada xlura la " &
          "eliogabalus lo nu ri cedgau lo bi'u nai tamne goi fo'e .i je bo fo'e ca'i " &
          "catnrkaisare .i je bo de'i lo nanca detri be la'e di'u ko'a jo'u lo go'i cu " &
          "catnrkonsule .i ku'i la eliogabalus di'a pensi lo bi'u nai tcini mu'i lo nu ko'a " &
          "co'a krici lo du'u ko'a mleca fo'e lo ka lo bandu bendrpraitoriu cu zanru lo nu " &
          "ce'u turni .i so'o roi se fliba fa lo nu lo nu la aleksandr se catra cu se troci .i " &
          "ba bo la eliogabalus minde fi lo nu fo'e co'u se sinma se cmene gi'e co'u " &
          "catnrkonsule kei gi'e te nuzba lo du'u la aleksandr ba zi mrobi'o kei lo jitfa te " &
          "zu'e lo nu lo no'a cu ba sanji lo se frati be lo bandu bendrpraitoriu .i ja'e bo ri " &
          "badri jo'u fengu .i je le bedypau poi ke'a bilga lo nu ke'a selfu ko'a cu na'e " &
          "klama ko'a .i je lo go'a cu mi'ecpe lo nu ri viska la eliogabalus e la aleksandr " &
          "bu'u lo ginka be vo'a .i ko'a zanru lo se go'i gi'e se kansa fo'e e ji'a la noi " &
          "mamta be vo'a iulias soaimias de'i li no re re re pi'e no ci pi'e pa pa .i loi " &
          "sonci co'a zanru krixa sinma la aleksandr gi'e na'e frati fi lo nu la eliogabalus " &
          "zvati .i ko'a minde fi lo nu ro da poi ke'a pu fapro cu co'a pinfu gi'e se catra .i " &
          "frati fa loi soncrpraitoriu fi la'e di'u fe lo nu lo no'a cu gunta la eliogabalus e " &
          "lo mamta be ko'a .i finti se cusku fa",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "eliogabalus",
      index: 22,
      text: "lu ko'a troci lo nu ko'a rivbi cliva .i ko'a pu'o lo nu ko'a snada da'i la'e di'u " &
          "lo nu ko'a se setca fi lo tanxe cu se tolmipri gi'e se catra ca lo nu ko'a nanca li " &
          "pa bi .i lo mamta be ko'a be'o noi ke'a ko'a birjai gi'e tagji jgari cu mrobi'o " &
          "fi'o kansa ko'a .i lo stedu be lo bi'u nai re mei cu katna se vimcu .i lo ve go'i " &
          "xadni cu se lubgau ce'o se lacpu fi'o se litru pi ro le tcadu .i ba bo lo xadni be " &
          "lo bi'u nai mamta cu se cliva bu'u zo'e .i je lo xadni be ko'a cu se renro mo'i " &
          "ne'i le rirxe li'u",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "eliogabalus",
      index: 23,
      text: "i ba lo nu ko'a mrobi'o kei la ierokles e la komazdon e lo drata poi ke'a pendo la " &
          "eliogabalus se catra .i ja lo go'i gau ku co'u catni .i lo lijda flalu be ca'i ko'a " &
          "ca'i ku co'u flalu .i la el gabal se xruti fi la emesas .i lo nu lo ninmu cu zvati " &
          "lo nu loi catnrsenatore cu jmaji cu se fanta .i ko'a se frigau fi la'e zoi zoi " &
          "damnatio memoriae zoi lu'u noi ke'a va'i nu lo cmene be ko'a be'o jo'u pixra be " &
          "ko'a cu se vimcu fi ro lo jecta vreji",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "eliogabalus",
      index: 24,
      text: "ni'o ni'o krasi fa lo pe la uikipedias ge'u glico velfarvi be de'i li re no no ze " &
          "pi'e pa re pi'e re bi",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "lo jbobau",
      index: 1,
      text: "la .lojban. no'u lo jbobau cu runbau .i ly. se finti la .lojbangirz. lo za'i zasti " &
          "fa su'o bangu poi se jicmu lo logji gi'e zifre selcpa gi'e se pilno ku'o de'i li " &
          "1987 .i lo na'e ralju te finti cu nu cipra lo ka lo nu pilno ce'u cu galfi lo tadji " &
          "be lo nu pensi",
      verdict: "Stream Letter",
    ),
    ParagraphWikipedia(
      article: "lo jbobau",
      index: 2,
      text: "la .lojban. se lidne la .loglan. noi no'e mulno se finti fo lo sidbo be fi la " &
          ".djeims.kuk.braun. fi lo nu cipra fi lo se skesmadi be la .sapir. jo'u la .uorf.",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "lo jbobau",
      index: 3,
      text: "ni'o de'i li 1987 so'o goi gy gunka be tu'a la .loglan. cu fendi lo girzu fo la " &
          ".loglan. ki'u lo za'i dy ky by finca'i lo bangu gi'e djica lo nu dukse be fi ku " &
          "jitro lo selci'a be bau .i gy. ganzu fi la .lojbangirz. mu'i lo nu finti lo cnino " &
          "lojbau .i ba za bo la .lojban. co'a vajmau la .loglan .i la .lojban. ca ti noi " &
          "nanca 2016 moi cu bangu ji'i 200 prenu",
      verdict: "Stream Letter",
    ),
    ParagraphWikipedia(
      article: "lo jbobau",
      index: 4,
      text: "lo lojbo gerna cu se krasi lo bridi logji .i lo valsi cu se krasi lo xa bangu po'u " &
          "lo jugbau jo'u lo glibau jo'u lo sanbau jo'u lo xinbau jo'u lo rabybau jo'u lo " &
          "rukybau .i zmiku lo ka finti lo valsi poi traji lo ka simsa lo valsi be ro by.",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "lo jbobau",
      index: 5,
      text: "la .lojban. se pagbu 27 ba'usle .e pa ba'urtadji jai galfi .i lo karsna cu se 6 mei " &
          "fi me'o .a'y .e me'o .e'y .e me'o .i'y .e me'o .o'y .e me'o .u'y .e me'o iy'y .i 19 " &
          "mei fa lo zunsna ku ne lo'u by cy dy fy gy jy ky ly my ny py ry sy ty vy xy zy .y'y " &
          "denpa bu le'u .i me'o denpa bu sruri lo cmevla gi'e lamji lo karsna poi tolfa'o lo " &
          "valsi ku'o .e me'o iy'y pe lo valsi fanmo .i me'o .y'y .e me'o slaka bu bi'ai se " &
          "sepsi'u lo slaka .i me'o .u'y .e me'o .i'y vu'o poi lidne lo karsna cu xabykarsna",
      verdict: "Stream Letter",
    ),
    ParagraphWikipedia(
      article: "lo jbobau",
      index: 6,
      text: "ni'o 26 da lojbo lerfu .i lo nu pilno lo na lojbo lerfu tu'a lo cmavo pe lo mekso " &
          ".a lo namcu .a lo lerfu cu jai cafne .i ca'irselzau fa lo nu basti lo namcu cmavo",
      verdict: "Stream Letter",
    ),
    ParagraphWikipedia(
      article: "lo jbobau",
      index: 7,
      text: "ni'o lo karsna cu midju lo slaka gi'e kakne lo nu bacru se basna .i lo slaka midju " &
          "cu ka'e re mei karsna .i lo relkarsna cu re mei lo karsna poi se gunma lo pa mei " &
          "slaka",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "lo jbobau",
      index: 8,
      text: "ni'o ro slaka cu karsna slaka gi'a zunsna slaka gi'a cmevlafa'o slaka",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "lo jbobau",
      index: 9,
      text: "ni'o lo karsna slaka cu se pagbu ci da .i lo slakykra noi pa moi pagbu cu pa mei " &
          "zunsna (to lo galxe spoja zunsna cu jai cumki toi) gi'a me pa lo selcurmi ke " &
          "slakykra zunsnapoi .i lo slakymidju noi re moi pagbu cu pa mei karsna gi'a pa mei " &
          "relkarsna .i lo slakyfa'o noi ci moi pagbu cu pa mei zunsna gi'a kunti",
      verdict: "Stream Letter",
    ),
    ParagraphWikipedia(
      article: "lo jbobau",
      index: 10,
      text: "ni'o lo zunsna slaka cu na vasru lo karsna gi'e se pagbu re da .i lo pa moi pagbu " &
          "cu pa mei zunsna .i lo re moi pagbu cu pa mei karsnasmi zunsna",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "lo jbobau",
      index: 11,
      text: "ni'o lo cmevlafa'o slaka cu se steci lo ka lo slakyfa'o cu porsi lo zunsna jo'u lo " &
          "galxe spoja zunsna",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "lo jbobau",
      index: 12,
      text: "ni'o ro lojbo valsi cu cmima pa lo mu tarmi klesi no'u lo cmavo jo'u lo gismu jo'u " &
          "lo lujvo jo'u lo zi'evla jo'u lo cmevla",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "lo jbobau",
      index: 13,
      text: "ni'o lo cmavo cu tordu valsi to zo cmavo cu se krasi lu cmalu valsi li'u toi gi'e " &
          "se krasi pa zunsna .i ro su'o re moi slaka pe lo relslaka cmavo cu ro roi se krasi " &
          ".y'y .i cmavo mupli fa zo .a .e zo ue .e zo bi .e zo coi .e zo dy .e zo fa'a .i " &
          "zasti fa lo ji'i 630 cmavo .i ku'i lo zasti cumki cmavo cu ci'i mei .i ji'a cmavo " &
          "tarmi mupli fa zo mu'ei .e zo poi'i vu'o noi nu'o catni se zanru cmavo .i lo cmavo " &
          "cu se pilno fi lo nu stura lo jufra",
      verdict: "Stream Letter",
    ),
    ParagraphWikipedia(
      article: "lo jbobau",
      index: 14,
      text: "ni'o lo gismu cu lerfu mu mei je slaka bo re mei valsi .i ro gismu cu se tarmi la'e " &
          "zoi .tam. ZZKZK .tam. lu'u .a la'e zoi .tam. ZKZZK .tam .i gismu mupli fa zo mlatu " &
          ".e zo gerku .i ca zasti fa lo ji'i 1400 ca'irselzau gismu",
      verdict: "Stream Letter",
    ),
    ParagraphWikipedia(
      article: "lo jbobau",
      index: 15,
      text: "ni'o lo lujvo cu gunma lo su'o re rafsi to zo lujvo cu se krasi lu pluja valsi li'u " &
          "toi .i lujvo mupli fa zo zi'evla noi lujvo fo lu zifre valsi li'u .i lo tersu'i " &
          "stura pe lo lujvo cu te javni .i ka'e ku se pi'o lo lujvo cu zbasu ci'i valsi .i lo " &
          "nu zbasu gi'e jmina vau lo cnino lujvo cu frili gi'e di'i fasnu",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "lo jbobau",
      index: 16,
      text: "ni'o so'i lo zi'evla ku goi lo fu'ivla pe'a fukpi lo valsi be fi lo drata bangu .i " &
          "ku'i lo lojbo valsi ku ji'a se galfi fi lo zi'evla .i lo javni be lo du'u ta'i ma " &
          "kau zbasu lo zi'evla cu na sampu .i lo valsi tarmi poi se fanmo lo karsna gi'e na " &
          "ka'e porpi lo cmavo jo'u lo gismu jo'u lo lujvo cu zi'evla tarmi .i cafne fa lo nu " &
          "lo zi'evla cu valsi lo danlu .a lo spati .a lo cidja .i zi'evla mupli fa zo djirafa",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "lo jbobau",
      index: 17,
      text: "ni'o lo cmevla cu se pilno fi lo ka te cmene .i ro cmevla cu se sruri lo depybu'i " &
          "gi'e se fanmo lo zunsna .i cmevla mupli fa zo .lojban .i lo cmevla cu jai se vlipa " &
          "fai lo ka sutra se finti fi lo nu tercme fi vo'a",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "lo jbobau",
      index: 18,
      text: "ni'o ji'a cumki fa lo nu sitna ja pilno lo fange bangu valsi bau la .lojban. .i zo " &
          "zoi fa'u zo la'o se pilno fi lo nu sitna fa'u pilno .i mu'a zoi gy. quark .gy cu " &
          "fange bangu valsi",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "lo jbobau",
      index: 19,
      text: "lo gerna be la .lojban. cu se jicmu lo bridi logji .i ro lojbo valsi cu cmima pa lo " &
          "za'u panono gerna klesi be lo lojbo valsi .i gerna klesi fa lo brivla .e lo cmevla " &
          ".e ro selma'o .i lo cmevla cu tarmi je gerna klesi .i ro gismu .e ro lujvo .e ro " &
          "zi'evla cu brivla to ro cmavo be zo go'i cu simsa lo brivla lo ka ka'e selbri kei " &
          "gi'e ku'i na brivla toi .i ro cmavo cu cmima pa selma'o",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "lo jbobau",
      index: 20,
      text: "ni'o lo selsku cu ta'e gunma lo jufra .i ku'i me'i ro selsku cu jufra .i mu'a lu " &
          "coi pendo li'u .e lu .ui sai li'u .e lu gi'e li'u cu gendra selsku gi'e nai mulno " &
          "jufra .i lo jufra cu se jicmu lo bridi .i lo bridi cu se jicmu lo selbri .i lo " &
          "selbri cu se sumti .i va'o lo mulno bridi lo selbri cu ro roi se cusku .i na gerna " &
          "bilga lo nu cusku ro sumti be lo selbri .i ji'a cumki fa lo nu jmina no sumti .i lo " &
          "jufra ka'e vasru lo li'erpau noi lidne lo bridi gi'e vasru lo sumti .e nai lo " &
          "selbri .i zo zo'u cu te sepli lo li'erpau lo bridi",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "lo jbobau",
      index: 21,
      text: "ni'o lo saprai selbri cu valsi pamei gi'e ga brivla gi cmavo be zo go'i .i ji'a lo " &
          "brivla porsi noi tanru cu selbri .i lo smuni be lo tanru cu se jicmu lo te tanru " &
          "noi ro moi pagbu be lo tanru .i lo se tanru noi lidne lo te tanru cu jai galfi lo " &
          "smuni be lo te tanru .i ji'a lo mulno jufra .e lo sumti .e lo namcu ka'e binxo lo " &
          "selbri .i lo cmavo be zo nu ku fa'u zo me fa'u zo moi cu jai galfi lo selyli'e ke " &
          "bridi fa'u sumti fa'u namcu lo selbri .i lo cmavo be zo moi ka'e ji'a se lidne lo " &
          "zo me selbri",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "lo jbobau",
      index: 22,
      text: "ni'o lo saprai sumti cu valsi pamei gi'e cmavo be zo ko'a .a zo by .i ji'a lo lerfu " &
          "porsi cu sampu sumti .i lo selbri poi se lidne lo gadri .a lo namcu cu sumti .i lo " &
          "cmevla poi se lidne lo cmavo be zo la cu sumti .i lo cmavo be zo li cu jai galfi lo " &
          "namcu lo sumti .i ji'a lo vrici ke sitna valsi cu se pilno fi lo nu zbasu lo sumti",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "lo jbobau",
      index: 23,
      text: "so'o da te finti la .lojban .i di'e mupli .i tu'e",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "lo jbobau",
      index: 24,
      text: ".i cipra lo se skesmadi be la .sapir. jo'u la .uorf.",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "lo jbobau",
      index: 25,
      text: ".i zmadu jimpe fi lo bangu",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "lo jbobau",
      index: 26,
      text: ".i xagzengau lo nu lo prenu cu tavla lo skami",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "lo jbobau",
      index: 27,
      text: ".i tutci lo nunctu",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "lo jbobau",
      index: 28,
      text: ".i larcu ve finti",
      verdict: "",
    ),
    ParagraphWikipedia(
      article: "lo jbobau",
      index: 29,
      text: "tu'u",
      verdict: "Grammar text 0",
    ),
    ParagraphWikipedia(
      article: "lo jbobau",
      index: 30,
      text: "Lojban",
      verdict: "Stream Stress",
    ),
  ]
    ## Paragraphs of each article, in order.
