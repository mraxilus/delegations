# Working in this repository

Every line here is model-written under the owner's direction. Before any change:

1. Read `CONSTITUTION.md`, then `STYLE.md`.
2. Find your role from your branch or opening prompt. `curator/<name>` and
   `curator/<project>/<name>` follow `CURATOR.md`; `contributor/<domain>/<project>/<name>`
   follows `CONTRIBUTOR.md` and writes only under `contributor/<domain>/<project>/`.
3. Run `nim r koch ci` at the repository root before every push. It must pass.
4. Never commit to `main`. Never write outside your scope. Never weaken a test to pass.
