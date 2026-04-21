import type { Game, Player } from "../types";

type EnterSubwayMessage = {
  type: "ENTER_SUBWAY";
  subwayId: number;
};

type AutoEnterRef = {
  current: string | null;
};

export function handlePlayerEnterSubway(subwayId: number, ws: WebSocket) {
  const payload: EnterSubwayMessage = {
    type: "ENTER_SUBWAY",
    subwayId: subwayId,
  };

  ws.send(JSON.stringify(payload));
}

export function checkAutoEnterSubwayAsMouse(
  player: Player,
  gameState: Game,
  lastAutoEnterKeyRef: AutoEnterRef,
  ws: WebSocket,
) {
  console.log("checkAutoEnterSubwayAsMouse");
  console.log(player);
  if (
    player.role !== "mouse" ||
    gameState.status === "caught" ||
    typeof player.subway !== "undefined"
  ) {
    lastAutoEnterKeyRef.current = null;
    return;
  }

  const subwayAtPlayerPosition = gameState.subways.find(
    (subway) =>
      typeof subway.id !== "undefined" &&
      subway.exits.some(
        (exit) =>
          Math.abs(exit.x - player.x) <= 11 &&
          Math.abs(exit.y - player.y) <= 11,
      ),
  );

  if (
    !subwayAtPlayerPosition ||
    typeof subwayAtPlayerPosition.id === "undefined"
  ) {
    lastAutoEnterKeyRef.current = null;
    return;
  }

  const currentAutoEnterKey = `${subwayAtPlayerPosition.id}:${player.x}:${player.y}`;
  if (lastAutoEnterKeyRef.current === currentAutoEnterKey) return;

  lastAutoEnterKeyRef.current = currentAutoEnterKey;
  console.log(
    `Auto ENTER_SUBWAY: subwayId=${subwayAtPlayerPosition.id}, x=${player.x}, y=${player.y}`,
  );
  handlePlayerEnterSubway(subwayAtPlayerPosition.id, ws);
}
