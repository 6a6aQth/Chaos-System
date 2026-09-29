# MC-DOS Template

Base repo every new MidasCreed project (and every DVFP) is cloned from.

## What's in this template

- Next.js (App Router) + TypeScript + Tailwind — a deploy-ready UI shell
- `/docs` — `DVFP_PROMPT.md` (the standing DVFP generation prompt) plus
  three reference guides: `Paychangu-Guide.md`, `Neon-Auth-Guide.md`,
  `Prisma-Database-Guide.md`. Each is written to be read and understood on
  its own by a person, not just followed by an AI IDE — they're reference
  material an AI IDE can be pointed at while working through a task list,
  not a script of commands to execute blindly.
- `.env.example` with Paychangu **test-mode** keys pre-fillable (safe —
  that account exists only for testing/demos) and everything else left
  blank/commented until a project needs it
- `scripts/nuke.sh` — wipes everything except `.git/`, `docs/`, and
  `.env.example`, and replaces it with a full standalone DVFP export

## What's deliberately NOT in this template

No Paychangu code, no Neon DB/Auth, no Resend. Every integration — Payment
included — is added later, per project, by pointing an AI IDE at the
matching guide in `/docs`, never baked into the base template or the
default DVFP prompt.

---

## Setting up a new project (DVFP / demo stage)

1. **GitHub** — "Use this template" → new repo, named for the client.
2. **Clone it locally.** Don't bother running `pnpm install`/`pnpm dev` on
   the bare template first — step 3 replaces almost everything anyway.
3. **Generate the DVFP** in chat using `docs/DVFP_PROMPT.md` as the
   standing prompt (it produces a complete, standalone Next.js project,
   not a partial diff against this template).
4. **Run the nuke script:**
   ```bash
   ./scripts/nuke.sh path/to/dvfp.zip
   pnpm install && pnpm dev
   ```
   This also turns `.env.example` into a real `.env` (then removes
   `.env.example`), and guarantees `.gitignore` excludes `.env` — so
   nothing with real values in it ever gets pushed to GitHub. If a dev
   server was already running from an earlier check, stop it first —
   `package.json` and the config files just changed underneath it, so a
   browser refresh alone won't pick that up.
5. **Deploy on Vercel.** Import the local `.env` file directly into
   Vercel's environment variables screen as you deploy — that's the one
   and only way env vars get into Vercel for this workflow. Don't also
   connect Vercel's Neon Storage integration for the same project; running
   both creates conflicting entries for the same variable names.
6. **If this specific DVFP needs a real payment button:** open the repo in
   Cursor/Claude Code and have it work through `docs/Paychangu-Guide.md`,
   using the demo-tier section (no database involved) — the Paychangu keys
   are already in `.env` from step 4.

## Promoting to production (post-sanction)

1. Client creates a Google account for the project, signs up for Neon and
   Resend with it (so they own billing). Get added as a collaborator on
   both.
2. Work through `docs/Prisma-Database-Guide.md` first, then
   `docs/Neon-Auth-Guide.md` — in that order, since Auth's own last step
   depends on Postgres already being set up.
3. If payment was demo-tier, revisit `docs/Paychangu-Guide.md`'s
   production section to add persistence and the idempotency check,
   mapping its example `Order`/`Payment` models onto whatever this
   project's SDD actually calls its payable entity.
4. Swap `PAYCHANGU_SECRET_KEY` from the test key to the client's own live
   key once they have a Paychangu account.
