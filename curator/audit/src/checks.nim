## Name each check of koch, so finding carries id of its rule rather than wording (D4 of #1002).
##   Name is enum's string, as knoller names its rules; id is `koch.` and its slug, i.e. letters
##     and digits in lowercase, each other run one `-` (`koch.commit-subject-width`), stable for
##     tool reading output. Prefix keeps each id apart from every id of knoller.
##   One check names one rule, whatever messages it gives: three messages of commit body are one
##     check, as each rule of knoller holds one id across its messages.
##   Report of knoller keeps id of its own rule (`toFinding`), and fault of tool names none.
##   List runs by module that holds check, in order of its path, and checks of hooks last.

{.experimental: "strictFuncs".}

import ../../knoller/src/knoller


type Check* {.pure.} = enum  ## Define one check of koch, by rule it holds.
  AssetUnknown = "unknown asset"  ## Asset named is declared in store.
  FetchAsset = "asset fetch"  ## Asset store declares fetches, and its digest checks.
  RowPruned = "pruned row"  ## `Pruned` row names commit that touched record, as hex digits.
  ConfigTypescript = "typescript config"  ## Project holding TypeScript sets its `tsconfig.json`.
  Drift = "drift"  ## Branch reads each section and code of stamp that base changed.
  ExportDead = "dead export"  ## Routine exported is named by other module or suite.
  SuiteCheck = "check suite"  ## Module of check has its suite.
  OptionsUsage = "usage options"  ## Usage text prints each option parser takes, and no other.
  VerbsUsage = "usage verbs"  ## Usage text prints each verb dispatch names.
  TableVerbs = "verbs table"  ## Checks table rows each verb koch dispatches, and no other.
  MentionVerb = "verb mention"  ## Mention of verb names one koch dispatches.
  SectionCited = "cited section"  ## Section cited stands in file cited.
  LengthLog = "log length"  ## Log of claims holds at most `ROWS_LOG` rows.
  FormLog = "log form"  ## Log of claims reads as reader of figures reads it.
  FixTested = "test before fix"  ## Fix follows commit of test that fails before it.
  SubjectCommit = "commit subject"  ## Commit subject reads `type(scope): lowercase summary`.
  ScopeCommit = "commit scope"  ## Commit scope names scope of branch.
  WidthSubject = "commit subject width"  ## Commit subject holds at most `SUBJECT_MAX` runes.
  BodyCommit = "commit body"  ## Commit body holds one sentence to line, in sentence case.
  CommitRecord = "record commit"  ## Record travels in `docs` commit of its own.
  CompilerMissing = "missing compiler"  ## Compiler serves pin of project.
  CoverageFont = "font coverage"  ## Font face project ships covers each character it draws.
  LockUnreadable = "unreadable lock"  ## Lock reads as JSON.
  NimbleLock = "lock nimble"  ## Copy of nimble file lock stores matches that file.
  NameLock = "lock name"  ## Lock names copy of nimble file after nimble file of project.
  CommitCheckout = "checkout commit"  ## Checkout stands at commit lock holds, after restore.
  CheckoutMissing = "missing checkout"  ## Checkout lock names stands after restore.
  RestoreDependency = "dependency restore"  ## Restore of dependencies matches lock.
  RestoreNode = "node restore"  ## Node restore runs, with npm on `PATH`.
  ParagraphDuplicate = "duplicate paragraph"  ## Paragraph appears once (duty 10).
  LengthParagraph = "paragraph length"  ## Paragraph holds at most `SENTENCES_PARAGRAPH` sentences.
  LengthSentence = "sentence length"  ## Sentence holds at most `WORDS_SENTENCE` words.
  WordApproved = "approved word"  ## Word stands in approved dictionary.
  NameUnknown = "unknown name"  ## Name given to `fix` matches file git lists.
  NimbleLocked = "locked nimble"  ## Nimble file whose copy lock holds stays as written.
  BackendCompile = "compile backend"  ## File compiles on backend of its pin, for semantic pass.
  HostFont = "font host"  ## Page ships its font face rather than linking font host.
  StackFont = "font stack"  ## Stack leads with family X.8 names.
  FamilyHeading = "heading family"  ## Heading takes serif family of X.8.
  LigaturesFont = "font ligatures"  ## Source setting mono family enables its ligatures.
  LoadFace = "font face load"  ## Font face page ships loads.
  FaceSystem = "system font face"  ## No character falls to font face of system.
  SynthesisBold = "bold synthesis"  ## Page ships font face of each weight it draws.
  CollectorFont = "font collector"  ## Collector reads each place of control page, whole.
  FacesWritten = "written font faces"  ## Drive writes what collector read, and file resolves.
  FormGlossary = "glossary form"  ## Glossary holds its headings, standards and terms in form.
  StandardRoot = "root standard"  ## Standard two projects list stands in root glossary alone.
  WordPeople = "word for people"  ## Glossary writes agreed term for people.
  PathMachine = "machine path"  ## Source names no path of one machine.
  ImportProject = "project import"  ## Import of other project goes through package lock pins.
  ImportDriver = "driver import"  ## Driver imports no package.
  JustificationLanguage = "language justification"  ## Gated language carries justification.
  IndexEntry = "entry index"  ## Index folder holds README and its member folders alone.
  NameProject = "project name"  ## Project folder reads `[a-z][a-z0-9_]*`.
  PlacePage = "page place"  ## Page stands under folder of pages.
  BuildTracked = "tracked build"  ## Build output and vendored source stay untracked.
  PlaceShell = "shell place"  ## Shell lives in folder of hook glue alone.
  KindFile = "file kind"  ## Kind of each file is one checker reads.
  LayoutRoot = "root layout"  ## Root holds files and folders of layout alone.
  RegistryDomain = "domain registry"  ## Domain folder stands in registry.
  FilesProject = "project files"  ## Project holds its file, tests and nimble file.
  LockMissing = "missing lock"  ## Project requiring packages holds lock.
  ViewsRoot = "root views"  ## Root holds its glossary and README of each root folder.
  FileEntry = "entry file"  ## Entry file stands, and `CLAUDE.md` imports it.
  ViewsDomain = "domain views"  ## Domain holds its row, README and theme line.
  ConflictMerge = "merge conflict"  ## Branch merges with base, so merge can be judged.
  TreeSecond = "second tree"  ## Second tree is worktree of its own.
  BuildMerge = "merge build"  ## Koch of merge with base builds.
  Acronym = "acronym"  ## Acronym stands only where glossary lists it.
  VerbProject = "project verb"  ## Verb of project runs green.
  PackagesSystem = "system packages"  ## Driver names system packages of project.
  Testament = "testament"  ## Testament runs each test of project green.
  IncidentPrompt = "prompt incident"  ## Prompt states rule and cost, and names no incident.
  SizePrompt = "prompt size"  ## Prompt holds at most `BYTES_PROMPT` bytes.
  HeadingRead = "reading heading"  ## Reading order of role that `start` prints stands.
  ProseOwn = "own prose"  ## Project keeping its own prose stands, with its suite.
  SectionProcess = "process section"  ## Section of process that stamp leaves out stands.
  TestCited = "cited test"  ## Test claim cites stands.
  HeaderProvenance = "provenance header"  ## Header of record holds its table and fields.
  StampStale = "stale stamp"  ## Rules row of record holds current stamp.
  HeadingsRecord = "record headings"  ## Record heads sections by subject, each once, as ATX.
  LengthRecord = "record length"  ## Record holds at most `LINES_RECORD` lines.
  LengthSection = "section length"  ## Section of record holds at most `LINES_SECTION` lines.
  CountProse = "count in prose"  ## Record names command that counts, never number.
  LineRole = "role line"  ## Pull request opens with role its branch names.
  LabelRole = "role label"  ## Pull request carries label of its role.
  TitlePull = "pull request title"  ## Pull request title reads `type(scope): lowercase summary`.
  ScopeTitle = "title scope"  ## Pull request title names scope of branch.
  WidthTitle = "title width"  ## Pull request title holds at most `SUBJECT_MAX` runes.
  SummarySection = "section summary"  ## Section of body opens with summary of one to three.
  HeadingsBody = "body headings"  ## Body of pull request holds its headings, once, in order.
  LengthBody = "body length"  ## Body of pull request shows at most `CHARACTERS_BODY` runes.
  ToolSchema = "schema tool"  ## Tool of schemas fetches at its pin, and compares them alone.
  CompileSchema = "schema compile"  ## Schema compiles.
  SchemaBreaking = "breaking schema"  ## Schema change keeps each version base shipped.
  PackageSchema = "schema package"  ## Schema folder keeps its package.
  FilesContributor = "contributor files"  ## Curator writes in contributor project alone records.
  NameBranch = "branch name"  ## Branch name follows grammar.
  ScopeBranch = "branch scope"  ## Each path changed stands inside scope of branch.
  PinCompiler = "compiler pin"  ## Nimble file pins compiler exactly.
  PinDriver = "driver pin"  ## Driver project pins version, never commit.
  VersionDriver = "driver version"  ## Workflow states driver version pin holds.
  PinKnoller = "knoller pin"  ## Project driver importing by path pins driver version.
  ScopesWorkflow = "workflow scopes"  ## Permissions of workflow grant scope its steps use.
  WindowRecent = "recent window"  ## Schedule and `DAYS_RECENT` name one window.
  MainCommit = "commit to main"  ## No commit lands on `main`.
  RewriteHistory = "history rewrite"  ## No push rewrites history remote holds.
  VerifyPush = "push verify"  ## No push skips pre-push hook.
  KeywordClosing = "closing keyword"  ## Closing keyword stands before issue on line of its own.
  RolePost = "post role"  ## Post opens with its role line.
  TitleIssue = "issue title"  ## Issue title is claim, never subject of commit.
  LabelIssue = "issue label"  ## Issue carries role label of its work.
  BodyPost = "post body"  ## Body of `gh api` post is file hook reads before command runs.
  Decision = "decision"  ## Decision of sign-off holds its parts, in form.
  RowsSignoff = "sign-off rows"  ## Rows of sign-off hold their cells, states and order.
  RulesCarried = "carried rules"  ## Sign-off names each carried rule once.
  GroupsSignoff = "sign-off groups"  ## Groups of sign-off open with bold line, one per request.
  Signoff = "sign-off"  ## Sign-off holds its parts, in order and form.
  GroupsKept = "kept groups"  ## Sign-off keeps each group and item sign-off before it held.
  NumberBare = "bare number"  ## First mention of number is link with description.
  LinkReference = "reference link"  ## Link stands inline, never by reference.
  ReferenceBare = "bare reference"  ## First citation of article gives its description.
  EndTurn = "turn end"  ## Turn that pushed or posted ends with sign-off or working line.
  ReadIssues = "issue read"  ## Sign-off follows read of open issues of role.
  Prediction = "prediction"  ## Call of subagent follows block of prediction.
  TablesPrediction = "prediction tables"
    ## Tables of prediction give each claim number, text, confidence or rising percentiles, and
    ##   criterion.
  TableReflection = "reflection table"  ## Reflection holds table of each claim predicted.
  LineReflection = "reflection line"  ## Line `**Subagent:**` of reflection gives tokens and cost.
  Reflection = "reflection"  ## Report of critic takes reflection of its own.
  CheckPush = "push check"  ## Commit pushed is one `koch check` passed.


func id*(check: Check): string =
  ## Read stable id of check: `koch.` and slug of its name, as id of rule of knoller reads.
  "koch." & slug($check)
