# Paychangu Guide

How best to add a working payment flow through Paychangu, at whichever level of completeness the project actually needs right now — a demo that just needs a real-feeling "pay now" button, or a production build that needs to reliably record that someone actually paid.

## The one idea worth understanding before writing any code

When Paychangu finishes processing a payment, it redirects the customer's browser back to a URL you provided, and it appends a `tx_ref` (and sometimes a status) as part of that URL. It's tempting to read that status straight off the URL and call it done — but that value is sitting in the browser's address bar, fully visible and editable by anyone. Someone could hand-type a URL with `status=successful` and land on your confirmation page without ever paying anything.

The `tx_ref` in that URL is useful for exactly one thing: it tells your server which transaction to ask about. The actual answer comes from your own server calling Paychangu directly — a private, authenticated request that the customer's browser never sees or touches:

```
GET https://api.paychangu.com/verify-payment/{tx_ref}
Authorization: Bearer {PAYCHANGU_SECRET_KEY}
```

Whatever that call returns is the truth. The URL parameter is just a pointer to which transaction to check.

It's also worth knowing, from experience, that Paychangu's webhook notifications don't reliably fire — the dashboard's own "test webhook" button can succeed while a real payment's webhook simply never arrives. Rather than fighting that, this guide treats the verify call above as the only mechanism that needs to be trusted, and treats a webhook, if you add one at all, as a convenience on top — never the thing a payment's success actually depends on.

## Environment variables

```env
PAYCHANGU_PUBLIC_KEY=
PAYCHANGU_SECRET_KEY=
NEXT_PUBLIC_APP_URL=
```

The public and secret keys come from the Paychangu dashboard, under API & Webhook settings. Whether you're in test or live mode is determined entirely by which secret key you paste in — there's no separate toggle. A sandbox account's key is the right choice for anything demo-stage; a client's own live key only belongs here once a project is actually going into production. `NEXT_PUBLIC_APP_URL` is used to build the URLs Paychangu redirects back to — it should point at `http://localhost:3000` while developing locally and the real deployed domain once it's live. All three live in the same single `.env` file as everything else the project uses; nothing about Paychangu needs its own separate env file.

One convenience worth knowing: Paychangu doesn't check which origin a request is coming from the way some auth providers do, so testing the whole flow against `localhost` works without any extra configuration — there's no allowlist to update before a payment can be tested locally.

## The shared piece both tiers use

Regardless of how complete the integration needs to be, the actual calls to Paychangu are the same two operations — starting a checkout, and verifying one afterward. It's worth putting both in one small file, `lib/paychangu.ts`, so nothing else in the project needs to know the details of Paychangu's API shape:

```typescript
const PAYCHANGU_BASE_URL = "https://api.paychangu.com";

function getSecretKey(): string {
  const key = process.env.PAYCHANGU_SECRET_KEY;
  if (!key) throw new Error("PAYCHANGU_SECRET_KEY is not set.");
  return key;
}

export interface InitiateCheckoutParams {
  amount: number;
  currency?: "MWK" | "USD";
  email?: string;
  firstName?: string;
  lastName?: string;
  title: string;
  description?: string;
  txRef?: string;
  callbackUrl: string;
  returnUrl: string;
  meta?: Record<string, unknown>;
}

export async function initiateCheckout(params: InitiateCheckoutParams) {
  const txRef = params.txRef ?? crypto.randomUUID();

  const res = await fetch(`${PAYCHANGU_BASE_URL}/payment`, {
    method: "POST",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      Authorization: `Bearer ${getSecretKey()}`,
    },
    // If Paychangu rejects this with a validation error, try sending
    // amount as a string instead of a number -- some integrations report
    // needing that.
    body: JSON.stringify({
      amount: params.amount,
      currency: params.currency ?? "MWK",
      email: params.email,
      first_name: params.firstName,
      last_name: params.lastName,
      tx_ref: txRef,
      callback_url: params.callbackUrl,
      return_url: params.returnUrl,
      customization: { title: params.title, description: params.description },
      meta: params.meta,
    }),
  });

  const body = await res.json();
  if (!res.ok || body.status !== "success") {
    throw new Error(`Paychangu initiate failed: ${body.message ?? res.statusText}`);
  }

  return { checkoutUrl: body.data.checkout_url as string, txRef: body.data.data.tx_ref as string };
}

export interface VerifyTransactionResult {
  status: "success" | "pending" | "failed" | string;
  txRef: string;
  currency: string;
  amount: number;
  mode: "live" | "test" | string;
  raw: unknown;
}

export async function verifyTransaction(txRef: string): Promise<VerifyTransactionResult> {
  const res = await fetch(`${PAYCHANGU_BASE_URL}/verify-payment/${encodeURIComponent(txRef)}`, {
    headers: { Accept: "application/json", Authorization: `Bearer ${getSecretKey()}` },
  });

  const body = await res.json();
  if (!res.ok || body.status !== "success") {
    throw new Error(`Paychangu verify failed: ${body.message ?? res.statusText}`);
  }

  return {
    status: body.data.status,
    txRef: body.data.tx_ref,
    currency: body.data.currency,
    amount: body.data.amount,
    mode: body.data.mode,
    raw: body.data,
  };
}
```

## If this is a demo, without a real database yet

For a prototype running on mock data and localStorage, the goal is just to make the payment button feel completely real, without needing anywhere to actually store the result. A route handler kicks off the checkout:

```typescript
// app/api/paychangu/checkout/route.ts
import { NextRequest, NextResponse } from "next/server";
import { initiateCheckout } from "@/lib/paychangu";

export async function POST(req: NextRequest) {
  const body = await req.json();
  const origin = req.nextUrl.origin;

  const { checkoutUrl } = await initiateCheckout({
    amount: body.amount,
    title: body.title,
    description: body.description,
    email: body.email,
    callbackUrl: `${origin}/api/paychangu/callback`,
    returnUrl: `${origin}/checkout/failed`,
  });

  return NextResponse.json({ checkoutUrl });
}
```

And a second route handles the redirect back, verifying server-side and handing the confirmed result on to the browser as URL parameters — this route runs on the server and has no access to localStorage itself, so it doesn't try to:

```typescript
// app/api/paychangu/callback/route.ts
import { NextRequest, NextResponse } from "next/server";
import { verifyTransaction } from "@/lib/paychangu";

export async function GET(req: NextRequest) {
  const txRef = req.nextUrl.searchParams.get("tx_ref");
  if (!txRef) return NextResponse.redirect(new URL("/checkout/failed", req.url));

  try {
    const result = await verifyTransaction(txRef);
    if (result.status === "success") {
      const url = new URL("/checkout/success", req.url);
      url.searchParams.set("tx_ref", result.txRef);
      url.searchParams.set("amount", String(result.amount));
      return NextResponse.redirect(url);
    }
    return NextResponse.redirect(new URL("/checkout/failed", req.url));
  } catch {
    return NextResponse.redirect(new URL("/checkout/failed", req.url));
  }
}
```

The last piece is the page the customer actually lands on, and this one runs in the browser — which is exactly where the localStorage write belongs, so the payment shows up consistently with everything else the demo already simulates:

```tsx
// app/checkout/success/page.tsx
"use client";

import { useEffect } from "react";
import { useSearchParams } from "next/navigation";

export default function CheckoutSuccessPage() {
  const params = useSearchParams();

  useEffect(() => {
    const txRef = params.get("tx_ref");
    const amount = params.get("amount");
    if (!txRef) return;

    // Match whatever mock structure the rest of this project already
    // uses -- this is just an illustrative shape.
    const existing = JSON.parse(localStorage.getItem("demo_orders") ?? "[]");
    localStorage.setItem(
      "demo_orders",
      JSON.stringify([...existing, { txRef, amount, status: "paid", paidAt: Date.now() }])
    );
  }, [params]);

  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-4 px-6 text-center">
      <h1 className="text-3xl font-semibold">Payment successful</h1>
      <a href="/" className="text-sm underline underline-offset-4">Back</a>
    </main>
  );
}
```

That's genuinely the whole thing at this level — no database, no webhook, nothing that needs to be idempotent, since there's nothing being written twice.

## Once there's a real database

The only thing that changes at this stage is what happens after a successful verification — instead of just redirecting, the result gets written to a real table, and it needs to be written exactly once even if the customer refreshes the confirmation page. Add a place to record it:

```prisma
model Order {
  id        String   @id @default(uuid()) @db.Uuid
  reference String   @unique
  status    String   @default("pending")
  amount    Int
  createdAt DateTime @default(now()) @map("created_at")

  payments Payment[]

  @@map("orders")
}

model Payment {
  id           String   @id @default(uuid()) @db.Uuid
  orderId      String   @map("order_id") @db.Uuid
  order        Order    @relation(fields: [orderId], references: [id])
  paychanguRef String   @unique @map("paychangu_ref")
  status       String
  confirmedAt  DateTime @default(now()) @map("confirmed_at")

  @@map("payments")
}
```

As with the `User` model in the Neon Auth guide, `Order` and `Payment` are placeholder names — if this project already has an entity for "the thing being paid for" (a booking, a reservation, whatever it's actually called), that's what should be used instead of introducing a redundant second table. The one part that actually matters structurally is a unique field somewhere storing Paychangu's `tx_ref`, since that uniqueness is what makes the next step safe.

The callback route becomes:

```typescript
// app/api/paychangu/callback/route.ts
import { NextRequest, NextResponse } from "next/server";
import { verifyTransaction } from "@/lib/paychangu";
import { prisma } from "@/lib/db";

export async function GET(req: NextRequest) {
  const txRef = req.nextUrl.searchParams.get("tx_ref");
  if (!txRef) return NextResponse.redirect(new URL("/checkout/failed", req.url));

  try {
    const result = await verifyTransaction(txRef);

    const existing = await prisma.payment.findUnique({ where: { paychanguRef: txRef } });
    if (existing) {
      return NextResponse.redirect(new URL(`/checkout/success?tx_ref=${txRef}`, req.url));
    }

    const order = await prisma.order.findUnique({ where: { reference: txRef } });
    if (!order) return NextResponse.redirect(new URL("/checkout/failed", req.url));

    if (result.status === "success") {
      await prisma.$transaction([
        prisma.order.update({ where: { id: order.id }, data: { status: "confirmed" } }),
        prisma.payment.create({ data: { orderId: order.id, paychanguRef: txRef, status: "completed" } }),
      ]);
      return NextResponse.redirect(new URL(`/checkout/success?tx_ref=${txRef}`, req.url));
    }

    await prisma.order.update({ where: { id: order.id }, data: { status: "cancelled" } });
    return NextResponse.redirect(new URL("/checkout/failed", req.url));
  } catch (err) {
    console.error(err);
    return NextResponse.redirect(new URL("/checkout/failed", req.url));
  }
}
```

The check for an existing payment before doing anything else is what makes it safe for this route to run more than once for the same transaction — whether that's from a page refresh or from also having a webhook enabled alongside this. If the database driver in use doesn't support multi-statement transactions (this varies by which Postgres driver a project uses), the two writes can be run one after another instead.

## Adding a webhook, if it's actually wanted

This is optional, and it's worth being clear it's a backup rather than the primary mechanism. Set the webhook URL in Paychangu's dashboard to point at `https://yourdomain.com/api/paychangu/webhook`, generate a webhook secret there, and save it as `PAYCHANGU_WEBHOOK_SECRET`. The handler should verify the signature, but then still re-verify the transaction through the same API call as everything else — never act on the payload's own claimed status directly, for the same reason the redirect URL isn't trusted on its own:

```typescript
// app/api/paychangu/webhook/route.ts
import { NextRequest, NextResponse } from "next/server";
import { verifyTransaction } from "@/lib/paychangu";
import { prisma } from "@/lib/db";
import crypto from "crypto";

function verifySignature(payload: string, signature: string | null, secret: string) {
  if (!signature) return false;
  const clean = signature.replace(/^(sha256=)/, "");
  const expected = crypto.createHmac("sha256", secret).update(payload, "utf8").digest("hex");
  if (clean.length !== expected.length) return false;
  return crypto.timingSafeEqual(Buffer.from(clean, "hex"), Buffer.from(expected, "hex"));
}

export async function POST(req: NextRequest) {
  const payload = await req.text();
  const signature = req.headers.get("x-paychangu-signature");
  const secret = process.env.PAYCHANGU_WEBHOOK_SECRET;

  if (!secret || !verifySignature(payload, signature, secret)) {
    return NextResponse.json({ error: "invalid signature" }, { status: 401 });
  }

  const data = JSON.parse(payload).data ?? JSON.parse(payload);
  const txRef = data.tx_ref ?? data.reference;
  if (!txRef) return NextResponse.json({ error: "no tx_ref" }, { status: 400 });

  const result = await verifyTransaction(txRef);
  const existing = await prisma.payment.findUnique({ where: { paychanguRef: txRef } });
  if (existing) return NextResponse.json({ received: true, alreadyProcessed: true });

  const order = await prisma.order.findUnique({ where: { reference: txRef } });
  if (!order) return NextResponse.json({ received: true, orderNotFound: true });

  if (result.status === "success") {
    await prisma.$transaction([
      prisma.order.update({ where: { id: order.id }, data: { status: "confirmed" } }),
      prisma.payment.create({ data: { orderId: order.id, paychanguRef: txRef, status: "completed" } }),
    ]);
  }

  return NextResponse.json({ received: true });
}
```

## Things that have gone wrong before

An initiate call getting rejected is sometimes down to `amount` being sent as a number rather than a string — worth trying the string form if validation fails for no obvious reason. A user landing on a broken page after paying usually means `callback_url` was pointed at the webhook endpoint instead of an actual page route — they need to be different URLs, since one is meant for a browser to land on and the other isn't. A webhook that tests successfully from the dashboard but never arrives for real payments is the known platform limitation mentioned earlier, not a configuration mistake — it's exactly why this guide doesn't depend on webhooks arriving. A payment recorded twice almost always means the existing-payment check was skipped somewhere. And if checkout URLs look right locally but wrong once deployed, it's usually `NEXT_PUBLIC_APP_URL` not being set for that specific environment in Vercel.

## Getting a new project to this point

Whichever tier applies, the shape of the work is: add the three environment variables, add `lib/paychangu.ts`, then either the two demo-tier routes and the client-side success page, or the Prisma models plus the persisting version of the callback route if a real database is already part of the project. A webhook is worth adding only after the rest is working and only if there's a specific reason to want the extra backup. Test everything against the sandbox key before a live key ever gets involved.
