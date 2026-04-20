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

- "memory" behavior
  - if a mouse enters a hole, keep track of which hole for this mouse (playerId)
  - if a mouse leaves hole, remove

- movement behavior
  - compares
    1. Mouses on the surfaces (received from server)
    2. Last seen holes positions (see memory behavior)
  - Runs to nearest mouse (1) or hole (2) based on the euclidean distance, if its at a hole, just waits there

- actions
  - always catch mouse if touched

### Mouse AI

- "memory" behavior
  - when entering a hole, remember position of cats
  - remember result of last vote

- movement behavior (multiple rules, top ones have priority)
  1. avoid cats in a XXX (TODO: test some values) radius, if inside the radius:
    - run into opposite direction of all cats in the radius (calc. direction vectors)
    - enter holes if in radius
  2. if vote exists:
    - move towards any of the voted subway holes
    - iterate over all holes and choose the first suitable one (no cat hovering over hole in a XXX radius)
    - if all holes are besetzt, do skip and do 3.
  3. if no vote: 
    - move towards nearest subway hole
    - iterate over all holes and choose the first suitable one (no cat hovering over hole in a XXX radius)
    - if all holes are besetzt, do skip and do 4.
  4. iterate over all holes and choose the first suitable one (no cat hovering over hole in a XXX radius)
    - if all holes are besetzt just run in a random direction

- voting
  - TBD

- actions
  - enter hole if touched and hole is target (see movement behavior) hole
