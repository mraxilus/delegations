# Stop building left-chirality transwedge tables

Nothing in the library reads the left family of `CAYLEYS_WEDGES_TRANS`. At five algebras,
the left family gives the same dot, geometric and dual products as the right family.

This change keeps the right family, and puts empty tables in the left slots. The compiler then
builds two families of tables, not four.

## Edit `pga/cayleys.nim`

```nim
      left: constructProductsTransitional(
        CAYLEYS_COMPLEMENT.right,
        CAYLEYS_DUAL.base.left,
        CAYLEYS_WEDGE,
        Chirality.Left,
        Spatiality.Base,
      ),
```

```nim
      left: default(array[Order, Cayley2D]),
```

## Edit `pga/cayleys.nim`

```nim
      left: constructProductsTransitional(
        CAYLEYS_COMPLEMENT.right,
        CAYLEYS_DUAL.anti.left,
        CAYLEYS_WEDGE,
        Chirality.Left,
        Spatiality.Anti,
      ),
```

```nim
      left: default(array[Order, Cayley2D]),
```
