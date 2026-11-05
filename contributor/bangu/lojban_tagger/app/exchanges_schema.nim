## Declare messages of `exchanges.proto` as Nim types, which `import_proto3` generates at compile
##   time: `Exchange` and `Reply` of exchange file, which `exchanges.nim` alone builds and reads.
##   Own module, since generator names each type by its message and ignores package, so types
##     here would clash with `Exchange` of `exchanges.nim` and `Reply` of `suggestions.nim`;
##     `exchanges.nim` imports module by `from ./exchanges_schema import nil`, naming each type
##     whole.
##   `protobuf_serialization` of Status generates types, and reads and writes their bytes:
##     protocol buffers are external concern, standard library reads none (Article II.8), and
##     data rule names package (CONTRIBUTOR.md, Data); `atlas.lock` pins it.
##   Cost: generated types carry no doc of their own; schema documents each message and field.

{.experimental: "strictFuncs".}

import protobuf_serialization, protobuf_serialization/files/type_generator


import_proto3 "exchanges.proto"
