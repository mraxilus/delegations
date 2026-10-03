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

import std/strutils

import ./inspector
import ./reference/[conformal2, conformal3, rigid2, rigid3]


type Movement* = object  ## Define bytes one call moves, by cause.
  bytes_read*: int  ## Operands read, i.e. sum of parameter sizes.
  bytes_written*: int  ## Result written once.
  bytes_zeroed*: int  ## Whole-object zero fills, i.e. `nimZeroMem` calls times result size.
  bytes_copied*: int  ## Whole-object copies times result size.
  bytes_intermediates*: int  ## Local multivector intermediates times multivector size.
  bytes_moved*: int  ## Sum of every cause.


func sizeOfStem*(stem: string, size_multivector: int, module = ""): int =
  ## Read bytes of type named by C stem; zero for stems model does not know.
  ##   Typed stems repeat across algebras at other sizes, so module of function reading them
  ##   names reference whose types they are; 3D Euclidean reference where module names none.
  case stem
  of "Multivector": size_multivector
  of "float", "int", "Antiscalar": 8
  else:
    if module.endsWith("rigid2"):
      case stem
      of "Point": sizeof(rigid2.Point)
      of "Line": sizeof(rigid2.Line)
      of "Motor": sizeof(rigid2.Motor)
      else: 0
    elif module.endsWith("conformal2"):
      case stem
      of "PointRound": sizeof(conformal2.PointRound)
      of "Dipole": sizeof(conformal2.Dipole)
      of "Circle": sizeof(conformal2.Circle)
      of "PointFlat": sizeof(conformal2.PointFlat)
      of "LineFlat": sizeof(conformal2.LineFlat)
      of "LineCarrier": sizeof(conformal2.LineCarrier)
      else: 0
    else:
      case stem
      of "Point": sizeof(rigid3.Point)
      of "Line": sizeof(rigid3.Line)
      of "Plane": sizeof(rigid3.Plane)
      of "Motor": sizeof(rigid3.Motor)
      of "PointRound": sizeof(conformal3.PointRound)
      of "Dipole": sizeof(conformal3.Dipole)
      of "Circle": sizeof(conformal3.Circle)
      of "Sphere": sizeof(conformal3.Sphere)
      of "PointFlat": sizeof(conformal3.PointFlat)
      of "LineFlat": sizeof(conformal3.LineFlat)
      of "PlaneFlat": sizeof(conformal3.PlaneFlat)
      of "PlaneCarrier": sizeof(conformal3.PlaneCarrier)
      of "Vector3": sizeof(rigid3.Vector3)
      else: 0


func movement*(function: FunctionC, counts: Counts, size_multivector: int): Movement =
  ## Model bytes one call of function moves, given its counts.
  var read = 0
  for stem in function.parameters: read += sizeOfStem(stem, size_multivector, function.module)
  let written = sizeOfStem(function.stem_result, size_multivector, function.module)
  result = Movement(
    bytes_read: read,
    bytes_written: written,
    bytes_zeroed: counts.fills_zero * written,
    bytes_copied: counts.copies * written,
    bytes_intermediates: counts.intermediates * size_multivector,
  )
  result.bytes_moved = result.bytes_read + result.bytes_written + result.bytes_zeroed +
    result.bytes_copied + result.bytes_intermediates
