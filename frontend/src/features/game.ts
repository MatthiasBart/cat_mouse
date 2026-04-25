import type { Game, Player } from "../types";
import type {
  CaughtMessage,
  GameInitMessage,
  GameUpdateMessage,
} from "./types";

const hasPosition = <
  T extends { position: { x: number; y: number } | undefined },
>(
  entity: T,
): entity is T & { position: { x: number; y: number } } =>
  typeof entity.position !== "undefined";

export function handleGameInitMessage(
  event: GameInitMessage,
  setGameState: (
    value: Game | null | ((prev: Game | null) => Game | null),
  ) => void,
  setPlayer: (
    value: Player | null | ((prev: Player | null) => Player | null),
  ) => void,
) {
  setGameState({
    status: "ongoing",
    subways: event.subways,
    cats: [],
    mice: [],
    fieldSize: event.fieldSize,
  });

  setPlayer({
    name: "player",
    role: event.role,
    x: event.playerPosition.x,
    y: event.playerPosition.y,
  });
}

export function handleGameUpdateMessage(
  event: GameUpdateMessage,
  setGameState: (
    value: Game | null | ((prev: Game | null) => Game | null),
  ) => void,
  setPlayer: (
    value: Player | null | ((prev: Player | null) => Player | null),
  ) => void,
) {
  setGameState((prevGame) => {
    //if (!prevGame) return prevGame;

    const mice = event.mice.filter(hasPosition).map((mouse) => ({
      id: mouse.id,
      name: mouse.name,
      subway: mouse.subway,
      x: mouse.position.x,
      y: mouse.position.y,
    }));

    const cats = event.cats.map((cat) => ({
      id: cat.id,
      name: cat.name,
      type: cat.type,
      x: cat.position.x,
      y: cat.position.y,
    }));

    return {
      //...prevGame,
      status: prevGame?.status ?? "ongoing",
      subways: event.subways ?? prevGame?.subways ?? [],
      fieldSize: event.fieldSize ??
        prevGame?.fieldSize ?? {
          width: 800,
          height: 600,
        },
      seq: event.seq,
      timeLeft: event.timeLeft,
      activeVote: event.active_vote,
      cats,
      mice,
    };
  });

  setPlayer((prevPlayer) => {
    const nextPosition = event.player.position ?? {
      x: prevPlayer?.x ?? 0,
      y: prevPlayer?.y ?? 0,
    };

    /*const previousPosition = {
      x: prevPlayer.x,
      y: prevPlayer.y,
    };*/

    //const nextPosition = event.player.position ?? previousPosition;

    return {
      ...prevPlayer,
      id: event.player.id,
      name: event.player.name,
      role: event.player.role,
      subway: event.player.subway,
      x: nextPosition.x,
      y: nextPosition.y,
    };
  });
}

export function handleCaughtMessage(
  _event: CaughtMessage,
  setGameState: (
    value: Game | null | ((prev: Game | null) => Game | null),
  ) => void,
) {
  setGameState((prevGame) => {
    if (!prevGame) return prevGame;

    return {
      ...prevGame,
      status: "caught",
      activeVote: undefined,
    };
  });
}
