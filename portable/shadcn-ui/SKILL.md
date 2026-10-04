---
name: shadcn-ui
description: Use when setting up shadcn/ui, adding or customizing its components, building forms with React Hook Form and Zod, theming with Tailwind CSS variables and dark mode, using the shadcn CLI or registries, or building accessible React UI (dialogs, dropdowns, tables, sidebars) in Next.js, Vite, Remix, or TanStack Start.
metadata:
  version: 0.3.0
  portable: true
  tags: [shadcn, react, tailwind, radix, ui, forms, portable]
---

# shadcn/ui

Not a package: the CLI **copies component source into your project** (`components/ui/`), so you own and edit it. Built on Radix UI primitives (accessibility) and Tailwind CSS (styling).

APIs and setup change often. When unsure, check https://ui.shadcn.com/docs (or the reference files below) instead of trusting memory, and check the repo's `components.json` and Tailwind version before generating code.

## Setup

```bash
npx shadcn@latest init                 # existing app: detects framework + Tailwind, writes components.json
npx shadcn@latest add button dialog form input select table sonner
npx shadcn@latest add --all            # everything
```

New Next.js app: `npx create-next-app@latest my-app` (TypeScript, Tailwind, App Router), then `npx shadcn@latest init`. Other frameworks (Vite, Remix, TanStack Start, Astro, Laravel) have their own install page.

Check after `init`:

- `components.json`: style, Tailwind CSS path, aliases (`@/components`, `@/lib/utils`), registries.
- Tailwind **v4** (current default): theme tokens are CSS variables in the global CSS file under `@theme inline`; no `tailwind.config` needed; animations via `tw-animate-css`.
- Tailwind **v3** (older projects): `tailwind.config.ts` with `darkMode: ["class"]`, content paths including components; `tailwindcss-animate`.
- `tsconfig.json` path alias `@/*`.

## Working rules

- Compose from installed components: `import { Button } from "@/components/ui/button"`.
- Merge classes with `cn()` from `@/lib/utils`; never string-concatenate Tailwind classes.
- Variants via `cva` (class-variance-authority) inside the component, not ad-hoc props.
- Theme through CSS variables (`--background`, `--primary`, `--radius`, …), not hardcoded Tailwind colors. Dark mode via a `ThemeProvider` (e.g. `next-themes`) toggling the `dark` class.
- Next.js App Router: components using state, effects, or event handlers need `"use client"`; keep wrappers small so pages stay server components.
- Toasts: use `sonner` (`<Toaster />` once in the root layout, `toast()` to fire). The older `toast`/`useToast` component is deprecated.
- Keep Radix accessibility intact: don't strip `DialogTitle`/`aria-*`; use `VisuallyHidden` if a title shouldn't show.
- Editing `components/ui/*` is expected, but re-running `add` overwrites it. Prefer wrapping for app-specific behavior.

## Forms (React Hook Form + Zod)

```bash
npm install react-hook-form zod @hookform/resolvers
npx shadcn@latest add form input label
```

Structure: `Form` → `FormField` (`control`, `name`, `render`) → `FormItem` → `FormLabel` + `FormControl` + `FormDescription` + `FormMessage`. Schema with `zod`, resolver with `zodResolver(schema)`, and infer types with `z.infer<typeof schema>`.

## Reference files

| File                       | Contents                                                                              |
| -------------------------- | ------------------------------------------------------------------------------------- |
| `learn.md`                 | Concepts and learning path                                                            |
| `ui-reference.md`          | Snippets from ui.shadcn.com: framework installs, `components.json`, registry examples, sidebar |
| `official-ui-reference.md` | Snippets from ui.shadcn.com: changelog, registry authoring/namespaces, component usage (button, chart, navigation-menu, …) |

Both reference files are point-in-time scrapes. Search them with `grep -n "### <topic>"`; for anything version-sensitive, confirm against the live docs.
