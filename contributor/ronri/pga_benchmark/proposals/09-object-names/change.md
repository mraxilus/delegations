# Names of geometric objects

`pga.nim` names the geometric objects of rga4d and cga5d, the algebras of 3D space that the book
uses. Each name is an alias of a basis-set type of the library. P04, `exact-kinds`, gives the
products that return these types, so this change builds on it.

## Edit `pga.nim`

```nim
#[ Extraction Operators ]#
```

```nim
#[ Geometric Objects ]#

when DIMENSIONS == 4 and IS_RIGID:
  type
    Point* = Multivector1  ## Define point of 3D space, grade 1.
    Line* = Multivector2  ## Define line, grade 2.
    Plane* = Multivector3  ## Define plane, grade 3.
    Motor* = MultivectorEven  ## Define motor, even grades.
    Flector* = MultivectorOdd  ## Define flector, odd grades.

when DIMENSIONS == 5 and IS_CONFORMAL:
  type
    PointRound* = Multivector1  ## Define round point of 3D space, grade 1.
    Dipole* = Multivector2  ## Define dipole, grade 2.
    Circle* = Multivector3  ## Define circle, grade 3.
    Sphere* = Multivector4  ## Define sphere, grade 4.



#[ Extraction Operators ]#
```
