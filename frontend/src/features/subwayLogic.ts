import type { Game, Player } from "../types";

type EnterSubwayMessage = {
  type: "ENTER_SUBWAY";
  subwayId: number;
};

type AutoEnterRef = {
  current: string | null;
};

export function handlePlayerLeaveSubway(exitId: number, ws: WebSocket) {
  ws.send(JSON.stringify({ type: "LEAVE_SUBWAY", exitId }));
}

export function handlePlayerEnterSubway(subwayId: number, ws: WebSocket) {
  const payload: EnterSubwayMessage = {
    type: "ENTER_SUBWAY",
    subwayId: subwayId,
  };

  ws.send(JSON.stringify(payload));
}

export function findNearbySubwayId(player: Player, gameState: Game): number | undefined {
  const subway = gameState.subways.find(
    (s) =>
      typeof s.id !== "undefined" &&
      s.exits.some(
        (exit) =>
          Math.abs(exit.x - player.x) <= 11 &&
          Math.abs(exit.y - player.y) <= 11,
      ),
  );
  return subway?.id;
}
