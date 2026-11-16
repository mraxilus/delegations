# Compiler patches

The port builds under Nimony at commit `941d128a2e7d6564e4585ec27f5da234a507a613`, with the
patches below. Without any one of them, the build of the rga3d suite fails. `deviations.md`,
section Compiler patches, gives each one as C1 to C9: the defect it mends, the error without it,
and which commit of Nimony mends it upstream.

The patches change 5 files of Nimony: they add 169 lines and remove 24. To build the patched
compiler, apply them in a checkout at that commit, and run the build command of the Nimony README
with Nim 2.4.0 on `PATH`:

```sh
git clone https://github.com/nim-lang/nimony.git
cd nimony
git checkout 941d128a2e7d6564e4585ec27f5da234a507a613
git apply compiler.diff
nim c -r src/hastur/hastur build all
```

`compiler.diff` is the fence below, saved as a file.

```diff
diff --git a/src/hexer/iterinliner.nim b/src/hexer/iterinliner.nim
index cf0a971f..91b12d24 100644
--- a/src/hexer/iterinliner.nim
+++ b/src/hexer/iterinliner.nim
@@ -561,6 +561,12 @@ proc expandInlineIterator(e: var EContext; dest: var TokenBuf; forStmt:
     let param = asLocal(params)
     var typ = param.typ
     let name = param.name
+    if typ.typeKind in {TypedescT, StaticT}:
+      # A compile-time parameter has no runtime value, so no local: C has no
+      # type for it. `lengcgen.maybeByConstRef` skips it for routines likewise.
+      skip iter
+      skip params
+      continue
     let newName = pool.symId("`lf." & $e.instId)
     inc e.instId
     createDecl(e, w, newName, typ, iter, name.info,
diff --git a/src/nimony/expreval.nim b/src/nimony/expreval.nim
index bb82fdb5..94d7bf92 100644
--- a/src/nimony/expreval.nim
+++ b/src/nimony/expreval.nim
@@ -1141,6 +1141,29 @@ proc evalImpl(c: var EvalContext; n: var Cursor): Cursor =
             let elem = propagateError eval(c, n)
             buf.addSubtree elem
       result = cursorAt(buf, 0)
+    of DotX:
+      # Field of a constant object, `CONST.field`: fold the object, then pick
+      # the field's value out of its `(oconstr T (kv field value)*)` literal.
+      let orig = n
+      n.peekInto:
+        let obj = propagateError eval(c, n)
+        if n.isSymbol and obj.exprKind == OconstrX:
+          let field = n.symId
+          var o = obj
+          o.peekInto:
+            skip o # type slot
+            while o.hasMore:
+              if o.substructureKind == KvU:
+                var kv = o
+                inc kv # past `kv` tag, at field symbol
+                if kv.isSymbol and kv.symId == field:
+                  inc kv # at field value
+                  result = kv
+                  break
+              skip o
+      if cursorIsNil(result):
+        cannotEval orig
+      return result
     of OconstrX:
       # an already-evaluated object literal: re-emit verbatim, evaluating
       # each field's value. This path is taken on second sem passes that
@@ -1418,6 +1441,8 @@ proc annotateConstantType*(buf: var TokenBuf; typ, n: Cursor) =
     buf.addSubtree n
     return
   let orig = typ
+  let annotateStart = buf.len
+  var n = n
   var typ = skipModifier(typ)
   var symType = default(Cursor)
   var opened = 0
@@ -1427,6 +1452,11 @@ proc annotateConstantType*(buf: var TokenBuf; typ, n: Cursor) =
     if res.status == LacksNothing:
       let decl = asTypeDecl(res.decl)
       if decl.body.typeKind == DistinctT:
+        # a distinct value computed by compile-time execution arrives as a
+        # `conv` to the distinct type: annotate the value it wraps
+        if n.isTagLit and n.exprKind in {ConvX, HconvX}:
+          inc n
+          skip n # type
         buf.addParLe(DconvX, n.info)
         buf.addSymUse(sym, n.info)
         inc opened
@@ -1675,8 +1705,8 @@ proc annotateConstantType*(buf: var TokenBuf; typ, n: Cursor) =

   if err:
     if opened > 0:
-      # could also replace with a general shrink to start
-      buf.shrink buf.len - opened
+      # each wrapper is two tokens, `(dconv` and its type, so drop them all
+      buf.shrink annotateStart
     buf.addParLe nifpools.ErrT, n.info
     buf.addDotToken()
     let msg = "cannot annotate constant " & asNimCode(n) & " with type " & typeToString(orig)
diff --git a/src/nimony/exprexec.nim b/src/nimony/exprexec.nim
index 9ecdfa4d..b0877eff 100644
--- a/src/nimony/exprexec.nim
+++ b/src/nimony/exprexec.nim
@@ -12,6 +12,7 @@ import ".." / lib / nifchecksums
 from std / os import `/`
 import std / [assertions, sets, tables, hashes, syncio]
 import ".." / models / tags
+import symtabs
 import nimony_model, decls, programs, xints, semdata, renderer, builtintypes, typeprops,
   typenav, typekeys, expreval, semos, derefs
 import ".." / lib / symparser
@@ -50,6 +51,7 @@ type
     hookNames: Table[string, int]
     thisModuleSuffix, newModuleSuffix: string
     bits: int
+    loopVars: int  # each serializer loop gets its own index variable
     structuralTypeToProc: Table[string, SymId]
     requests: seq[GenProcRequest]
     usedModules: HashSet[string]
@@ -168,6 +170,27 @@ proc rewriteTreeToIdents(newDest: var TokenBuf; n: var Cursor; thisMod: string)
           emitSymAsIdent(newDest, n.symId, n.info, thisMod)
         else:
           rewriteTreeToIdents(newDest, n, thisMod)
+    elif n.exprKind == OconstrX:
+      # A copied constant value may set private fields (`len` and `data` of
+      # a `seq`). Keep each field name a Symbol: sem reads a Symbol as
+      # "visibility already checked", as it does for `AlreadyChecked` below.
+      newDest.addParLe(n.cursorTagId, n.info)
+      n.into:
+        if n.hasMore:
+          rewriteTreeToIdents(newDest, n, thisMod) # type
+        while n.hasMore:
+          if n.substructureKind == KvU:
+            newDest.addParLe(n.cursorTagId, n.info)
+            n.into:
+              if n.isSymbol:
+                newDest.addSymUse(n.symId, n.info)
+                inc n
+              while n.hasMore:
+                rewriteTreeToIdents(newDest, n, thisMod)
+            newDest.addParRi()
+          else:
+            rewriteTreeToIdents(newDest, n, thisMod)
+      newDest.addParRi()
     elif n.exprKind in {DotX, DdotX}:
       # The sub-compile runs under a synthesized module suffix, so a private
       # field's access token can no longer name a module the check would
@@ -423,6 +446,12 @@ proc incIndexVar(c: var SynthesizeSerializerCtx; indexVar: SymId) =
       copyIntoSymUse c.dest, indexVar, c.info
       c.dest.addIntLit(+1, c.info)

+proc newIndexVar(c: var SynthesizeSerializerCtx): SymId =
+  ## Fresh loop index: nested loops (array of seq, array of array) must not
+  ## share one variable, or the inner loop resets the outer one.
+  result = pool.symId("idx" & $c.loopVars & ".0")
+  inc c.loopVars
+
 proc declareIndexVar(c: var SynthesizeSerializerCtx; indexVar: SymId) =
   copyIntoKind c.dest, VarY, c.info:
     addSymDef c.dest, indexVar, c.info
@@ -438,7 +467,7 @@ proc unravelArray(c: var SynthesizeSerializerCtx;
   inc n
   let baseType = n

-  let indexVar = pool.symId("idx.0")
+  let indexVar = newIndexVar(c)
   declareIndexVar c, indexVar

   genStringCall(c, "writeNifParLe", "aconstr")
@@ -471,7 +500,7 @@ proc unravelPtrUarrayField(c: var SynthesizeSerializerCtx;
   inc ft # past uarray tag
   let baseType = ft

-  let indexVar = pool.symId("idx.0")
+  let indexVar = newIndexVar(c)
   declareIndexVar c, indexVar

   genStringCall(c, "writeNifParLe", "addr")
@@ -509,7 +538,7 @@ proc unravelSet(c: var SynthesizeSerializerCtx; orig: TypeCursor; param: TokenBu
   genStringCall(c, "writeNifParLe", "setconstr")
   genStringCall(c, "writeNifRaw", toString(orig, false))

-  let indexVar = pool.symId("idx.0")
+  let indexVar = newIndexVar(c)
   declareIndexVar c, indexVar
   # the element is our int indexVar, converted back to the set's base type
   var indexVarAsBuf = createTokenBuf(4)
@@ -570,9 +599,16 @@ proc entryPoint(c: var SynthesizeSerializerCtx; orig: TypeCursor; arg: Cursor)
   of DistinctT, RangetypeT:
     # do not lose the type:
     genStringCall(c, "writeNifParLe", "conv")
-    # we simply generate the type as a raw string:
-    genStringCall(c, "writeNifRaw", toString(orig, false))
-    entryPoint(c, typ.childCursor, arg)
+    # we simply generate the type as a raw string, after a space: a nominal
+    # type is a bare symbol, which must not run into the `conv` tag.
+    genStringCall(c, "writeNifRaw", " " & toString(orig, false))
+    # Write the value as its base type: `writeNifInt` and friends take the
+    # base, not the distinct type (`Grade` is no `int64`).
+    var asBase = createTokenBuf(8)
+    copyIntoKind asBase, ConvX, c.info:
+      asBase.addSubtree typ.childCursor
+      asBase.addSubtree arg
+    entryPoint(c, typ.childCursor, readonlyCursorAt(asBase, 0))
     genParRiCall c
   of IT:
     primitiveCall(c, "writeNifInt", arg)
@@ -686,6 +722,37 @@ proc collectSymDefs(n: Cursor; defs: var HashSet[SymId]) =
   var n = n
   collectSymDefsAux(n, defs)

+proc collectIdents(n: var Cursor; idents: var seq[StrId]) =
+  ## Collects every `Ident` in the subtree at `n`, advancing `n` past it.
+  if not n.isTagLit:
+    if n.kind == Ident: idents.add n.strId
+    inc n
+  else:
+    n.loopInto:
+      collectIdents(n, idents)
+
+proc collectModuleSymsByName(s: var SemContext; decl: Cursor; thisModule: string;
+                             stack: var seq[SymId]) =
+  ## A toplevel `const` is evaluated in the signature phase, before routine
+  ## bodies of its module are semchecked. A copied routine of this module may
+  ## therefore still name its callees and types by `Ident`: resolve those
+  ## names in the module scope, so their declarations are copied too.
+  var top = s.currentScope
+  while top != nil and top.kind != ToplevelScope: top = top.up
+  if top == nil: return
+  var idents: seq[StrId] = @[]
+  var d = decl
+  collectIdents(d, idents)
+  # `for x in T` calls `items` (or `pairs`) without naming it.
+  idents.add pool.strings.getOrIncl("items")
+  idents.add pool.strings.getOrIncl("pairs")
+  for name in idents:
+    for sym in top.tab.getOrDefault(name):
+      if pool.symModule(sym.name) == thisModule and
+          sym.kind in {TypeY, ProcY, FuncY, IteratorY, ConverterY, MethodY,
+                       TemplateY, MacroY, ConstY, LetY, VarY, GletY, GvarY}:
+        stack.add sym.name
+
 proc collectUsedSymsFromExpr(c: var SynthesizeSerializerCtx; s: var SemContext; expr: Cursor) =
   ## Like `collectUsedSyms` but seeded from the symbols referenced *in the
   ## expression itself* rather than a routine. Used by `executeExpr` to set
@@ -721,6 +788,7 @@ proc collectUsedSymsFromExpr(c: var SynthesizeSerializerCtx; s: var SemContext;
           c.dest.addSubtree res.decl
           var d = cursorAt(c.dest, before)
           collectSyms(d, stack)
+          collectModuleSymsByName(s, res.decl, c.thisModuleSuffix, stack)
       elif owner.len > 0:
         c.usedModules.incl(s.g.config.nifcachePath / owner)

diff --git a/src/nimony/sem.nim b/src/nimony/sem.nim
index 51ee53f2..5941317c 100644
--- a/src/nimony/sem.nim
+++ b/src/nimony/sem.nim
@@ -1279,7 +1279,9 @@ proc tryBuiltinDot(c: var SemContext; dest: var TokenBuf; it: var Item; lhs:
               # exprexec serialization) happen in a different module, so they
               # judge the access against this suffix rather than against
               # whichever module they are running in.
-              dest.addStrLit(visibilityModule(c, info), info)
+              # Keep an incoming token: it already names the writing module.
+              dest.addStrLit(if accessToken.len > 0: accessToken
+                             else: visibilityModule(c, info), info)
             it.typ = field.typ # will be fit later with commonType
             it.kind = FldY
           else:
@@ -1681,9 +1683,10 @@ proc semTypeExpr(c: var SemContext; dest: var TokenBuf; n: var Cursor;
   n = it.n
   if context == AllowValues:
     let emitted = cursorAt(dest, start)
-    if emitted.exprKind == ExprX and isPureTypeValueExpr(emitted):
+    if hasPureValueExprs(emitted):
       var buf = createTokenBuf(4)
-      buf.addSubtree typeValueExpr(emitted)
+      var e = emitted
+      copyPeelingValueExprs(buf, e)
       dest.replace cursorAt(buf, 0), start
   exprToType c, dest, it.typ, start, context, info
   swap c.phase, phase
diff --git a/src/nimony/typeprops.nim b/src/nimony/typeprops.nim
index 1783293e..3ca439f8 100644
--- a/src/nimony/typeprops.nim
+++ b/src/nimony/typeprops.nim
@@ -232,14 +232,19 @@ proc containsGenericParamsAux(n: var TypeCursor): bool =
 proc typeValueExpr*(n: Cursor): Cursor =
   ## In a static type slot, a template expansion is emitted as `(expr … value)`.
   ## Peel to `value` when present; otherwise return `n` unchanged.
+  ## Walks a bounded scope: `isLastSon` misjudges a child that is not last
+  ## of an unbounded cursor, e.g. one element of a set constructor.
   result = n
   if n.exprKind != ExprX: return
   var e = n
-  inc e
-  while e.hasMore and not isLastSon(e):
-    skip e
-  if e.hasMore:
-    result = e
+  e.peekInto:
+    while e.hasMore:
+      var next = e
+      skip next
+      if not next.hasMore:
+        result = e
+        break
+      skip e

 proc isPureTypeValueExpr*(n: Cursor): bool =
   ## True when `n` is an `(expr …)` whose prefix statements are only empty
@@ -247,16 +252,49 @@ proc isPureTypeValueExpr*(n: Cursor): bool =
   ## template in a type context.
   if n.exprKind != ExprX: return true
   var e = n
-  inc e
-  while e.hasMore and not isLastSon(e):
-    if e.stmtKind == StmtsS:
+  result = false
+  e.peekInto:
+    while e.hasMore:
+      var next = e
+      skip next
+      if not next.hasMore:
+        result = true
+        break
+      if e.stmtKind != StmtsS: break
       var probe = e
+      var isEmpty = true
       probe.peekInto:
-        if probe.hasMore: return false
-    else:
-      return false
-    skip e
-  result = e.hasMore
+        if probe.hasMore: isEmpty = false
+      if not isEmpty: break
+      skip e
+
+proc hasPureValueExprs*(n: Cursor): bool =
+  ## True when `n` is or holds a pure `(expr … value)`; see `isPureTypeValueExpr`.
+  if n.kind != TagLit: return false
+  if n.exprKind == ExprX and isPureTypeValueExpr(n): return true
+  var e = n
+  result = false
+  e.peekInto:
+    while e.hasMore:
+      if hasPureValueExprs(e): return true
+      skip e
+
+proc copyPeelingValueExprs*(dest: var TokenBuf; n: var Cursor) =
+  ## Copy `n`, peeling each pure `(expr … value)` to its value, also inside an
+  ## aggregate such as `{Basis.scalar..Basis.scalarAnti}`: a static value is
+  ## one canonical tree only when no element keeps its template wrapper.
+  if n.kind == TagLit and n.exprKind == ExprX and isPureTypeValueExpr(n):
+    var v = typeValueExpr(n)
+    copyPeelingValueExprs(dest, v)
+    skip n
+  elif n.kind == TagLit:
+    dest.addParLe(n.cursorTagId, n.info)
+    n.into:
+      while n.hasMore:
+        copyPeelingValueExprs(dest, n)
+    dest.addParRi()
+  else:
+    dest.takeTree n

 proc containsGenericParams*(n: TypeCursor): bool =
   var n = n
```
