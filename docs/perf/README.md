# Performance results

- `baseline.json`: the agreed baseline. Owner-only; promoted through a `governance/*` PR.
- `<run-id>/results.json`: results from a pipeline run, written by the performance agent.
- `<run-id>/proposed-baseline.json`: written when no baseline exists yet.

Suggested shape:

```json
{
  "recorded_at": "2026-01-01T12:00:00Z",
  "commit": "abc1234",
  "conditions": "Pixel 7 emulator, release build, 500 shifts seeded",
  "metrics": {
    "cold_start_ms": 820,
    "p95_interaction_ms": 45,
    "peak_memory_mb": 180
  }
}
```

For the performance-test analyst agent you're building separately, this is the
natural hand-off point: point the `Performance` command in `CLAUDE.md` at your
load test, and have it write `results.json` in this shape.
