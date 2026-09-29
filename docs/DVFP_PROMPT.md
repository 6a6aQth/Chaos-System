We are building a frontend-only Design-Validated Functional Prototype (DVFP) — Version 1,
for client demo purposes only. This is not the production build.

CREATIVE DIRECTION
Premium, high-end aesthetic — think [reference 1] × [reference 2] in feel.
Use TypeScript React (TSX), Tailwind CSS, Next.js App Router.
Push the typography, spacing, and motion further than a typical SaaS template —
oversized type, generous whitespace, deliberate micro-interactions on hover/scroll.
Tailwind is the styling engine but should not read as a template — treat it as raw
material, not a constraint. Extend Tailwind's theme freely (custom colors, fonts,
spacing) — this is a full standalone project, not something merged into an
existing config, so there's nothing to conflict with.

WHAT NOT TO BUILD YET
No real backend logic, live database connections, third-party SDK calls, or
payment integrations. Everything is simulated.

SIMULATION RULES
Use hardcoded dummy data, mock JSON, and localStorage to simulate app state,
user profiles, and business logic.
Isolate all mock responses inside clean Next.js Route Handlers, at the same
route paths the production API will eventually use (e.g. app/api/orders/route.ts),
so the mock logic can be swapped for real logic later without touching the UI layer.

PROJECT SETUP
Generate this as a complete, standalone Next.js project (App Router) — its own
package.json, tsconfig.json, tailwind.config, next.config, and .gitignore. This
replaces an existing project wholesale, so it should be fully self-contained and
runnable on its own with just pnpm install && pnpm dev.
Do not include ESLint — no eslint / eslint-config-next dependencies, no
.eslintrc file. This stack doesn't use lint tooling.

TECH STACK (for consistency, so real integration work drops in cleanly later)
Vercel Blob, Resend, Vercel Deployment, Neon DB & Auth, SWR polling, Image
Optimization, REST API via Next.js Route Handlers, ORM: Prisma, pnpm package
manager. Payment (Paychangu) and all of the above are added separately, later,
once a project is real — don't build any of them now, just keep route/naming
conventions consistent with them.
