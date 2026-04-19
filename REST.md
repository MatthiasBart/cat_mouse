# REST API Spec

The REST API is session cookie based. Use `credentials: include` (browser) or preserve cookies (non-browser clients) between REST and WebSocket calls.

## Create Game

- `POST /games`
- Query parameters:
  - `role`: required, `cat` or `mouse`
  - `playerName`: optional, defaults to `Anonymous` if missing or blank

Creates a new game and automatically joins the caller as the **creator**.

Response: `201 Created`

```json
{
  "playerId": 1,
  "role": "CAT",
  "playerName": "tom123",
  "code": "A3E2E18E-332B-49D4-B00C-FAE4D14C56D0"
}
```

## Join Game

- `POST /games/{code}/players`
- Query parameters:
  - `role`: required, `cat` or `mouse` (case-insensitive)
  - `playerName`: optional, defaults to `Anonymous` if missing or blank

Joins an existing game and stores/updates the player session for the caller.

Response: `200 OK`

```json
{
  "playerId": 2,
  "role": "MOUSE",
  "playerName": "jerry123",
  "code": "A3E2E18E-332B-49D4-B00C-FAE4D14C56D0"
}
```

## Start Game

- `PATCH /games/{code}`

Starts a game. This endpoint is **creator-only**:

- only the session that created the game can start it
- the session game code must match `{code}`
- game must not already be started
- game must contain at least one cat and one mouse

Response: `204 No Content`

## Add AI / Computer Player

TBD

## Error Behavior

- `400 Bad Request`: missing/invalid role or malformed request
- `401 Unauthorized`: missing/invalid session
- `403 Forbidden`: caller is not allowed to start this game or session/game mismatch
- `404 Not Found`: game code does not exist
- `409 Conflict`: game already started or game is not ready to start

After obtaining a valid session, [establish a WS connection](WS.md).
