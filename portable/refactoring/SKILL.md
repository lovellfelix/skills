---
name: refactoring
description: Simplify and refine code for clarity, consistency, and maintainability while preserving functionality. Use when code needs cleanup, after features are implemented, or during review.
version: 0.1.0
portable: true
tags: [refactoring, maintainability, portable]
---

## Purpose

Enhance code clarity, consistency, and maintainability while preserving exact functionality. Balance readable, explicit code over overly compact solutions.

## Core Principles

1. **Preserve Functionality**: Never change what code does - only how it does it. All original features, outputs, and behaviors must remain intact.

2. **Apply Project Standards**: Follow established conventions from AGENTS.md:
   - Use ES modules with proper import sorting
   - Prefer explicit return types for top-level functions
   - Follow language-specific patterns (see project's AGENTS.md)
   - Use proper error handling patterns

3. **Enhance Clarity**: Simplify code structure by:
   - Reducing unnecessary complexity and nesting
   - Eliminating redundant code and abstractions
   - Improving readability through clear naming
   - Consolidating related logic
   - Removing obvious comments that restate the code
   - **Avoid nested ternaries** - prefer switch/if-else for multiple conditions
   - **Choose clarity over brevity** - explicit code beats clever one-liners

4. **Maintain Balance**: Avoid over-simplification that could:
   - Reduce code clarity or maintainability
   - Create overly clever solutions that are hard to understand
   - Combine too many concerns into single functions
   - Remove helpful abstractions that improve organization
   - Prioritize "fewer lines" over readability
   - Make the code harder to debug or extend

## Refactoring Patterns

| Pattern | When to Apply | Example |
|---------|--------------|---------|
| Extract method | Function > 20 lines or does multiple things | Split `processData()` into `validateData()` + `transformData()` |
| Guard clauses | Deep nesting from conditionals | Replace nested if/else with early returns |
| Reduce nesting | > 3 levels of indentation | Use early returns, extract helper functions |
| Consolidate conditionals | Multiple conditions with same result | Combine into single conditional with descriptive name |
| Replace magic numbers | Unexplained literals | Use named constants |
| Simplify boolean expressions | Complex conditionals | Extract to well-named boolean variable |

## When to Use

- Before adding features to tangled code
- After implementing a feature (cleanup pass)
- When complexity metrics exceed thresholds
- During dedicated refactoring sprints
- After code review identifies structural issues

## Process

1. Identify code sections needing improvement
2. Analyze for opportunities to enhance elegance and consistency
3. Apply project-specific best practices
4. Verify all functionality remains unchanged
5. Ensure refined code is simpler and more maintainable
6. Run tests to confirm behavior preservation
