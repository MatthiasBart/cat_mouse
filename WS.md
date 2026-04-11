# WebSocket API Spec

Clients can connect `/games/ws` to with a valid session (see [REST specs](./REST.md)).

## Messages (WIP)

### Overview

| Type           | Direction        | Link |
| -------------- | ---------------- | ---- |
| `GAME_UPDATE`  | Server -> Client |      |
| `GAME_OVER`    | Server -> Client |      |
| `MOVE`         | Client -> Server |      |
| `LEAVE_SUBWAY` | Client -> Server |      |
| `ENTER_SUBWAY` | Client -> Server |      |
| `BEGIN_VOTE`   | Client -> Server |      |
| `END_VOTE`     | Client -> Server |      |
| `VOTE`         | Client -> Server |      |
| `ERROR`        | Server -> Client |      |

### Server -> Clients

#### Game update (TBD)

_Note_: Here we should ensure to send updates only to allowed clients (e.g visibility on surface and in each subway)

- `seq` ... ordering of all updates TODO: do we need a sequence number? Ignored for now.
- `time` ... ms since gamestart

edge cases TBD:

- client disconnected
- ...

this needs to be considered aswell:

- > When a mouse safely enters a subway, it informs other mice in this subway about positions of cats at the time of entering.

// voting, entering

#### GameInit Message

When player joins a game as a mouse:

```json
{
  "type": "GAME_INIT",
  "role": "mouse",
  "fieldSize": {
    "width": 600,
    "height": 450
  },
  "subways: [ {
      "id": number,
      "name": string,
      "exits": { "x": number, "y": number }[]
    }]
}
```

When player joins a game as a cat:

```json
{
  "type": "GAME_INIT",
  "role": "mouse",
  "subways: [ {
      "exits": { "x": number, "y": number }[]
    }]
}
```

#### GameUpdate Message

```json
{
  "type": "GAME_UPDATE",
  "seq": 42,
  "timeLeft": 100000, // time until game ends (until cats win)
  "player": {
    "id": 5,
    "name": "tom123",
    "role": "mouse" | "cat",
    "subway": 5 | undefined, // id of the subway if inside one
    "position": { "x": 10, "y": 20 } | undefined // undefined if inside a subway
  },
  "mice":
    {
      "id": 12,
      "position": { "x": 12, "y": 18 } | undefined, // if outside, it sees other outside mice
      "name": string,
      "subway": 5 | undefined // same id as current player
    }[],
  "cats": {
    {
      "id": 1,
      "position": { "x": 5, "y": 5 }, // as mouse if outside or as cat
      "name": string,
      "type": "live" | "ghost" // live if actual player, ghost if it's the last known position of a cat when a mouse enters the same
        // subway like the player.
    },
  }[],
  "active_vote": {
    "timeLeft": "15", // in seconds // optional?
    "votes": {"subwayId": 5, "votes": 5}[] // current results of all tunnels
  }
}
```

#### CaughtMessage

Message received if you get caught as a mouse:

```json
{
  "type": "CAUGHT"
}
```

#### Vote Result Message

Message received if you voted for a subway and are in it:

```json
{
  "type": "VOTE_RESULT",
  "win_subway": 2 // id of winning subway
}
```

#### Game ended

- `player` ... winning player, either cat or mouse object depending on the team.
  - if cat then the cat that caught most mice
  - if mouse then the mouse that spent most time on the surface
- `team` ... either `CATS` | `MOUSE` // TODO: redundant if type is already stated in winner?
  - cats win if after game ran out of time _or_ if only one mouse left
  - mouses win if all surving mice are located in the same subway

```json
{
  "type": "GAME_ENDED",
  "player": {
    "id": 7,
    "name": "jerry123",
    "type": "CAT"
  },
  "team": "CATS",
  "totalTime": 100000
}
```

_Quote from assignment_:

> A game ends when all surviving mice are located
> in the same subway (the surviving mouse that spent most time on
> the surface is the winner) or after a predefined amount of time (the
> cat that caught most mice is the winner).

### Client -> Server

#### Movement

- either send position or direction?
- sending direction based on timestamp and direction might be smart
  to prevent cheating -> movement calculated only on server

##### Move

```json
{
  "type": "MOVE",
  "direction": "UP" | "DOWN" | "LEFT" | "RIGHT", // steps of 10
}
```

- Entering a subway as a mouse, front-end can decide how this is implemented

```json
{
  "type": "ENTER_SUBWAY",
  "subwayId": 5
}
```

##### Start a vote

- Start a vote in a tunnel if no current vote is active. Optional.

```json
{
  "type": "START_VOTE"
}
```

##### Leave Game

```json
{
  "type": "LEAVE_GAME"
}
```

#### Make a voting decision

```json
{
  "type": "VOTE_DECISION",
  "target_subway_id_vote": number
  ...
}
```
