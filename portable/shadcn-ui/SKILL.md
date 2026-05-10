---
name: shadcn-ui
description: Use when setting up shadcn/ui, installing components, building forms with React Hook Form and Zod, customizing themes with Tailwind CSS, or implementing accessible UI patterns (buttons, dialogs, dropdowns, tables, complex layouts).
metadata:
  version: 0.2.0
  portable: true
  tags: [shadcn, react, ui, portable]
---

# shadcn/ui Component Patterns

Expert guide for building accessible, customizable UI components with shadcn/ui, Radix UI, and Tailwind CSS.

## What is shadcn/ui?

Not a traditional npm package — a **collection of reusable components you copy into your project**. You own the code. Built with Radix UI primitives for accessibility, styled with Tailwind CSS.

## Use when

- Setting up a new project with shadcn/ui.
- Installing or configuring individual components.
- Building forms with React Hook Form and Zod validation.
- Creating accessible UI components (buttons, dialogs, dropdowns, sheets, tables).
- Customizing component styling with Tailwind CSS or CSS variables.
- Building Next.js applications with TypeScript and shadcn/ui.

## Quick Start

```bash
# New project
npx create-next-app@latest my-app --typescript --tailwind --eslint --app
cd my-app
npx shadcn@latest init

# Existing project — install deps then init
npm install tailwindcss-animate class-variance-authority clsx tailwind-merge lucide-react
npx shadcn@latest init

# Install components
npx shadcn@latest add button input form card dialog select table toast
```

## Key configuration files

After `init`, verify these are set:

**`components.json`** — registry path, style, Tailwind config, import aliases  
**`tailwind.config.ts`** — `darkMode: ["class"]`, content paths include `./components/**`  
**`globals.css`** — CSS variables for `--background`, `--foreground`, `--primary`, `--radius`, etc.  
**`tsconfig.json`** — path aliases: `@/*` → `./*`

## Core workflow

1. `npx shadcn@latest add <component>` — installs to `components/ui/`
2. Import and compose: `import { Button } from "@/components/ui/button"`
3. Extend with `cn()` utility for conditional Tailwind classes
4. Theme via CSS variables in `globals.css` — no component code changes needed

## Forms (React Hook Form + Zod)

```bash
npm install react-hook-form zod @hookform/resolvers
npx shadcn@latest add form input label
```

Pattern: `Form` → `FormField` → `FormItem` → `FormLabel` + `FormControl` + `FormMessage`

## Best practices

- Use `cn()` from `lib/utils` for all conditional class merging.
- Wrap `ThemeProvider` at the root for dark mode support.
- Prefer CSS variables for theming over hardcoded Tailwind colors.
- Server components: mark interactive wrappers with `"use client"`.
- Toast: use `useToast()` hook + `<Toaster />` in root layout.

## Reference files

| File | Contents |
|------|----------|
| `reference.md` | Component API quick reference (Button, Input, Dialog, Select, Table, Toast, Sheet) |
| `ui-reference.md` | Extended component patterns and composition examples |
| `official-ui-reference.md` | Full official component documentation |
| `learn.md` | Learning path and deeper guides |

## Constraints

- Requires Tailwind CSS v3 (v4 support is experimental as of shadcn 0.9+).
- Interactive components need `"use client"` — cannot be used in RSC directly.
- No built-in i18n or RTL support.
- Toast/Sonner requires root layout placement.
