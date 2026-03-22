# WebSocket Protocol

Clients connect to a WebSocket via the url received after either creating or joining a game (REST routes `/join/{code}` or `create`).

## Messages (WIP)
### Overview
| Type | Direction | Link |
| - | - | - |
| `GAME_UPDATE` | Server -> Client |  |
| `GAME_OVER` | Server -> Client |  |
| `MOVE` | Client -> Server |  |
| `LEAVE_SUBWAY` | Client -> Server |  |
| `ENTER_SUBWAY` | Client -> Server |  |
| `BEGIN_VOTE` | Client -> Server |  |
| `END_VOTE` | Client -> Server |  |
| `VOTE` | Client -> Server |  |
| `ERROR` | Server <-> Client |  |

### Server -> Clients

#### Game update (TBD)
*Note*: Here we should ensure to send updates only to allowed clients (e.g visibility on surface and in each subway)
* `seq` ... ordering of all updates TODO: do we need a sequence number?
* `time` ... ms since gamestart

edge cases TBD:
* client disconnected
* ...

this needs to be considered aswell:
* > When a mouse safely enters a subway, it informs other mice in this subway about positions of cats at the time of entering.

```json
{
  "type": "GAME_UPDATE", 
  "seq": 42,
  "time": 100000,
  "player": {
    "id": 5,
    "username": "tom123",
    "status": "IN_SUBWAY",
    "subway": 5,
    "position": { "x": 10, "y": 20 }
  },
  "mice": [
    { 
      "id": 12, 
      "position": { "x": 12, "y": 18 },
      "subway": null
    },
    {...}
  ],
  "cats": [{...}]
}
```

#### Game over (TBD)

* `player` ... winning player, either cat or mouse object depending on the team.
  * if cat then the cat that caught most mice
  * if mouse then the mouse that spent most time on the surface
* `team` ... either `CATS` | `MOUSE` // TODO: redundant if type is already stated in winner? 
  * cats win if after game ran out of time *or* if only one mouse left
  * mouses win if all surving mice are located in the same subway

```json
{
  "type": "GAME_OVER", 
  "player": {
    "id": 7,
    "name": "jerry123",
    "type": "CAT"
  },
  "team": "CATS",
  "time": 100000
}
```

*Quote from assignment*:
> A game ends when all surviving mice are located
> in the same subway (the surviving mouse that spent most time on
> the surface is the winner) or after a predefined amount of time (the
> cat that caught most mice is the winner).

### Client -> Server

#### Movement (TBD)
* either send position or direction?
* sending direction based on timestamp and direction might be smart 
to prevent cheating -> movement calculated only on server
```json
{
  "type": "MOVE", 
  "player": 7,
  "direction": "TOP",
  "time": 100000
}
```

#### Vote (TBD)
```json
{
  "type": "VOTE", 
  ...
}
```