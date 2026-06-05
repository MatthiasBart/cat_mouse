# Game AI

Procedural style:

- mostly functions with no return values (procedures)
- => procedures have side effects

> go version go1.26.1

## Running

### development

```
go run . --code="ABCDEFG" --role="cat" --name="ai-bot"
```

### building

```
go build .
```

building and running

```
go build . && ./game-ai --code="ABCDEFG" --role="cat" --name="ai-bot"
```

## AI behavior (WIP)

### Cat AI

- state
  - store current target (mouse or random subway exit)

- movement behavior
  1. If mice are visible, chase the closest mouse that is not already covered (fixed radius) by another cat
  2. If no mice are visible (or all are covered), pick a random subway exit and move there

### Mouse AI

- state
  - store current target (subway exit coordinate)
  - store winning subway id (from recent vote results)

- movement behavior (top ones have priority)
  1. If a cat is nearby (configurable radius), try to escape to "best" exits (preferring exits closer to the mouse than the cat, and exists of the last voting winning subway).
  2. If no cat is nearby, but there is a winning subway (from a previous vote), target the closest exit of that subway.
  3. If no target and no winning subway, pick a completely random subway exit and move there.

- subway & voting behavior
  - when entering or inside a subway:
    - if the mouse is already in the winning subway, it simply stays there and waits.
    - if there is no active vote, it sends a `START_VOTE` message.
    - if there is an active vote, it votes for a random subway (and remembers if it has voted before)
    - once a `VOTE_RESULT` is received, it records the winning subway and leaves its current subway via a random exit.
