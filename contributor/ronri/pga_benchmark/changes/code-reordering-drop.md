# Drop `codeReordering` from `multivectors.nim`

The pragma makes the compiler warn on every build. `multivectors.nim` declares each symbol
before its first use, so it needs no reordering. Other files at pin read a table that is below
its reader, so they keep the pragma.

## Edit `pga/multivectors.nim`

```nim
{.experimental: "codeReordering".}
```

```nim

```
