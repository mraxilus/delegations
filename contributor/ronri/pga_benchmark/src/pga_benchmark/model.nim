## Model bytes one call moves, from counts read out of C and sizes of what it reads and writes.
##   Movement is what memory sees: operands read, result written, whole-object zero fills,
##   whole-object copies and intermediates materialised. Sizes come from type stems C names:
##   library's dense multivector is 8 × 2^dimensions, typed reference objects are their
##   Nim sizes, scalars eight bytes.
##
##   Cost: model counts bytes named by code, not cache lines touched; it ranks data
##     movement between forms, and is not measurement of traffic (Article VIII.1: modelled,
##     never promoted to measured).

{.experimental: "strictFuncs".}

import ./inspector
import ./reference/[conformal3, rigid3]


type Movement* = object
  ## Define bytes one call moves, by cause.
  bytes_read*: int
    ## Operands read, i.e. sum of parameter sizes.
  bytes_written*: int
    ## Result written once.
  bytes_zeroed*: int
    ## Whole-object zero fills, i.e. `nimZeroMem` calls times result size.
  bytes_copied*: int
    ## Whole-object copies times result size.
  bytes_intermediates*: int
    ## Local multivector intermediates times multivector size.
  bytes_moved*: int
    ## Sum of every cause.


func sizeOfStem*(stem: string; size_multivector: int): int =
  ## Read bytes of type named by C stem; zero for stems model does not know.
  case stem
  of "Multivector": size_multivector
  of "float", "int", "Antiscalar": 8
  of "Point": sizeof(rigid3.Point)
  of "Line": sizeof(rigid3.Line)
  of "Plane": sizeof(rigid3.Plane)
  of "Motor": sizeof(rigid3.Motor)
  of "RoundPoint": sizeof(conformal3.RoundPoint)
  of "Dipole": sizeof(conformal3.Dipole)
  of "Circle": sizeof(conformal3.Circle)
  of "Sphere": sizeof(conformal3.Sphere)
  of "FlatPoint": sizeof(conformal3.FlatPoint)
  of "FlatLine": sizeof(conformal3.FlatLine)
  of "FlatPlane": sizeof(conformal3.FlatPlane)
  of "CarrierPlane": sizeof(conformal3.CarrierPlane)
  of "Vec3": sizeof(rigid3.Vec3)
  else: 0


func movement*(f: CFunction; c: Counts; size_multivector: int): Movement =
  ## Model bytes one call of function moves, given its counts.
  var read = 0
  for stem in f.params: read += sizeOfStem(stem, size_multivector)
  let written = sizeOfStem(f.result_stem, size_multivector)
  result = Movement(
    bytes_read: read,
    bytes_written: written,
    bytes_zeroed: c.zero_fills * written,
    bytes_copied: c.copies * written,
    bytes_intermediates: c.intermediates * size_multivector,
  )
  result.bytes_moved = result.bytes_read + result.bytes_written + result.bytes_zeroed +
    result.bytes_copied + result.bytes_intermediates
