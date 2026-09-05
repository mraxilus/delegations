# Working in this repository

Every line here is model-written under the owner's direction. Before any change:

1. Read `CONSTITUTION.md`, then `STYLE.md`.
2. Find your role. On a `curator/<name>` branch, or when your opening prompt was
   `CURATOR.md`, follow `CURATOR.md`. On a `<domain>/<project>/<name>` branch, or when your
   opening prompt was `CONTRIBUTOR.md`, follow `CONTRIBUTOR.md` and write only under
   `<domain>/<project>/`.
3. Run `make check` at the repository root before every push. It must pass.
4. Never commit to `main`. Never write outside your scope. Never weaken a test to pass.
