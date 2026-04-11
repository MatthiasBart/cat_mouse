# REST API Spec (WIP)

## Create Game

- POST `/games/` -> create Game with code e.g ABCDEFG, creates a session
  also auto-joins this game.
  response:
  role:
  code:
  playerId:

## Join Game

- POST `/games/{code}/players` -> join Game with code, creates a session
  queryParameter: role: "cat" or "mouse"
  queryParameter: playerName: string
  Response:

after obtaining a valid session, [establish a WS connection](WS.md)
