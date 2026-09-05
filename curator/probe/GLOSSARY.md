# probe

Domain-neutral test project: it exists so the audit, the branch grammar and the merge
process can be exercised without touching a real project.

## Language

**Step**:
A position on a ring of `MODULUS` places, 0 through MODULUS − 1.
_Avoid_: element, index, number

**Ring**:
The closed set of steps with advance as its operation and 𝟎 as identity.
_Avoid_: group, cycle, clock

**Advance**:
Moving a step forward by another step, wrapping at MODULUS; written ⊕.
_Avoid_: add, sum, plus

**Modulus**:
The ring size, chosen at build time and validated statically.
_Avoid_: size, length, period

**Probe pull request**:
A throwaway pull request from `curator/probe/probe-<name>` that changes only this project's
README.md, driven through every CI job, then closed unmerged.
_Avoid_: smoke test, dry run, canary
