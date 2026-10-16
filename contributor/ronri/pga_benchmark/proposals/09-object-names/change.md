# Names of geometric objects

`pga.nim` names the geometric objects of rga4d and cga5d, the algebras of 3D space that the book
uses. Each name is an alias of a basis-set type that P04 adds.

## Edit `pga.nim`

```nim
#[ Extraction Operators ]#
```

```nim
#[ Geometric Objects ]#

when DIMENSIONS == 4 and IS_RIGID:
  type
    Point* = Kvector1  ## Define point of 3D space, grade 1.
    Line* = Kvector2  ## Define line, grade 2.
    Plane* = Kvector3  ## Define plane, grade 3.
    Motor* = MultivectorEven  ## Define motor, even grades.
    Flector* = MultivectorOdd  ## Define flector, odd grades.

when DIMENSIONS == 5 and IS_CONFORMAL:
  type
    PointRound* = Kvector1  ## Define round point of 3D space, grade 1.
    Dipole* = Kvector2  ## Define dipole, grade 2.
    Circle* = Kvector3  ## Define circle, grade 3.
    Sphere* = Kvector4  ## Define sphere, grade 4.



#[ Extraction Operators ]#
```
