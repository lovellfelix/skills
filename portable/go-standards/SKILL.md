---
name: go-standards
description: "Use when writing, reviewing, testing, or refactoring Go code (.go files, go.mod, goroutines, error wrapping, interfaces, table-driven tests, golangci-lint)."
metadata:
  version: 0.2.0
  portable: true
  tags: [go, golang, standards, idioms, error-handling, concurrency, testing]
---

# Go Standards

Idiomatic, boring Go. Follow the repo's existing conventions (logger, assertion library, linters) before these defaults.

## Errors

- Return errors; don't `panic` outside truly unrecoverable init failures.
- Wrap with context: `fmt.Errorf("load config %s: %w", path, err)`. Lowercase, no trailing punctuation, no "failed to" stacking.
- Inspect with `errors.Is` / `errors.As`, never string matching. Export sentinel errors (`var ErrNotFound = errors.New(...)`) only when callers need to branch on them.
- Handle each error once: either log it or return it, not both.
- Discarding an error (`_ = f.Close()`) needs a comment saying why it's safe.

## Interfaces and types

- Define interfaces in the consuming package. Accept interfaces, return concrete types.
- Small interfaces (often one method). Don't create one until a second implementation or a test seam needs it.
- Make the zero value useful where practical.

## Packages and layout

- Package name = directory name: short, lowercase, no `util`/`common`/`helpers`.
- `main.go` only wires dependencies and starts things; logic lives in packages.
- `internal/` for anything not meant as public API.

## Concurrency

- `ctx context.Context` is the first parameter of anything that blocks, does I/O, or spawns work. Never store contexts in structs.
- Every goroutine has a documented owner and exit condition. Use `errgroup.Group` (with `WithContext`) to run and cancel groups of goroutines.
- Channels to pass ownership and coordinate; mutexes to guard shared state. Keep a given piece of state under one mechanism.
- Run tests with `-race` in CI.

## Testing

- Table-driven tests with `t.Run` subtests; `t.Parallel()` where tests are independent.
- `t.Helper()` in test helpers, `t.Cleanup()` for teardown, `t.TempDir()` for files.
- Use `testify` only if the project already does; otherwise stdlib `testing` with `cmp.Diff` for comparisons.
- Benchmarks (`func BenchmarkX(b *testing.B)`) for hot paths you change.

```go
func TestParseLimit(t *testing.T) {
	tests := []struct {
		name    string
		in      string
		want    int
		wantErr bool
	}{
		{name: "empty uses default", in: "", want: 10},
		{name: "valid", in: "25", want: 25},
		{name: "negative", in: "-1", wantErr: true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := ParseLimit(tt.in)
			if (err != nil) != tt.wantErr {
				t.Fatalf("ParseLimit(%q) error = %v, wantErr %v", tt.in, err, tt.wantErr)
			}
			if got != tt.want {
				t.Errorf("ParseLimit(%q) = %d, want %d", tt.in, got, tt.want)
			}
		})
	}
}
```

## Observability

- Use the project's logger; for new code default to `log/slog` with structured key/value pairs.
- Log or emit a metric for errors at the boundary where they're handled, not at every layer they pass through.

## Quality gates before done

```bash
gofmt -l .          # must print nothing (or goimports)
go vet ./...
golangci-lint run   # if configured; includes staticcheck
go test -race ./...
```

## Avoid

- `init()` with side effects. Global mutable state.
- Naked returns in anything longer than a few lines.
- Goroutines without an exit path; `time.Sleep` for synchronization.
- Premature interfaces and generic helpers for a single call site.
