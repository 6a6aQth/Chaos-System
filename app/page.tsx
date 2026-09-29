import Image from "next/image";

export default function Home() {
  const stack = [
    {
      label: "Full-stack Framework",
      name: "Next.js",
      desc: "App Router, TypeScript, deploy-ready out of the box.",
    },
    {
      label: "Database",
      name: "Postgres",
      desc: "Provisioned via Neon once a project is real.",
    },
    {
      label: "Authentication",
      name: "Neon Auth",
      desc: "Managed identity, wired in per project via the docs guide.",
    },
    {
      label: "ORM",
      name: "Prisma",
      desc: "Type-safe queries and migrations, covered in the docs guide.",
    },
    {
      label: "UI Components",
      name: "Handled by DVFP",
      desc: "Whatever the prototype brings — nothing fixed here.",
    },
    {
      label: "CSS Framework",
      name: "Tailwind",
      desc: "Raw material, not a constraint — extend it freely.",
    },
  ];

  return (
    <main className="min-h-screen bg-[#05070d] text-white">
      <div className="mx-auto flex max-w-4xl flex-col gap-10 px-6 py-24">
        <div className="flex items-center gap-2 text-sm text-white/50">
          <Image
            src="/logo.png"
            alt=""
            width={28}
            height={28}
            className="h-7 w-7 object-contain"
            priority
          />
          <span className="tracking-wide">MC-DOS TEMPLATE</span>
        </div>

        <div className="grid items-center gap-8 lg:grid-cols-[minmax(0,1fr)_13.5rem]">
          <div className="relative order-1 h-48 w-full overflow-hidden rounded-xl border border-white/10 lg:h-auto lg:aspect-square">
            <Image
              src="/visual.webp"
              alt=""
              fill
              sizes="(max-width: 1023px) 100vw, 216px"
              className="object-cover"
              priority
            />
          </div>

          <div className="order-2 flex flex-col gap-5 lg:order-first">
            <h1 className="text-4xl font-semibold leading-tight sm:text-5xl">
              Nuke this code with the{" "}
              <span className="text-[#3b82f6]">DVFP</span> repo to get
              started.
            </h1>
            <p className="max-w-xl text-white/60">
              This is the base every new MidasCreed project is cloned from.
              It deploys as-is on Vercel with nothing pre-wired — Payments,
              Auth, and Database are each added per project by pointing an
              AI IDE at a guide in /docs. Drop a full DVFP export in with
              the command below, and this page is the first thing it
              replaces.
            </p>
          </div>
        </div>

        <div className="rounded-xl border border-white/10 bg-white/[0.03] px-5 py-4 font-mono text-sm text-white/80">
          <span className="text-[#3b82f6]">$</span> ./scripts/nuke.sh
          &quot;/path/to/dvfp.zip&quot;
        </div>

        <div className="grid grid-cols-1 gap-px overflow-hidden rounded-xl border border-white/10 bg-white/10 sm:grid-cols-2">
          {stack.map((item) => (
            <div key={item.label} className="bg-[#05070d] p-5">
              <p className="text-xs uppercase tracking-wide text-white/40">
                {item.label}
              </p>
              <p className="mt-1 font-medium">{item.name}</p>
              <p className="mt-1 text-sm text-white/50">{item.desc}</p>
            </div>
          ))}
        </div>
      </div>
    </main>
  );
}
