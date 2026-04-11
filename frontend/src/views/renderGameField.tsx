import type { Game, Cat, Mouse, Subway, Player } from "../types";
import type { JSX } from "preact/jsx-runtime";

export function renderGameField(
  gameState: Game,
  renderFunction: (gameState: Game, onMove: () => void) => JSX.Element,
): JSX.Element {
  return (
    <div
      style={{
        flex: 1,
        backgroundColor: "grey",
        width: 400, // todo from game init msg
        height: 400,
      }}
    >
      {renderFunction(gameState, () => {})}
    </div>
  );
}

export function renderComponents(
  gameState: Game,
  onMove: () => void,
): JSX.Element {
  return (
    <div>
      {renderPlayer(gameState.player)}
      {gameState.mice.map((mouse: Mouse, index: number) => {
        return (
          <div
            key={index}
            style={{
              position: "relative",
              left: `${mouse.x}px`,
              top: `${mouse.y}px`,
            }}
          >
            <img
              src="./mouse.png"
              alt="mouse"
              style={{ width: 50, height: 50 }}
            />
          </div>
        );
      })}
      {gameState.cats.map((cat: Cat, index: number) => {
        return (
          <div
            key={index}
            style={{
              position: "relative",
              left: `${cat.x}px`,
              top: `${cat.y}px`,
            }}
          >
            <img src="./cat.png" alt="cat" style={{ width: 50, height: 50 }} />
          </div>
        );
      })}
      {gameState.subways.map((subway: Subway, index: number) => {
        return (
          <div
            key={index}
            style={{
              position: "relative",
              left: `${subway.x}px`,
              top: `${subway.y}px`,
            }}
          >
            <img
              src="./subway.png"
              alt="subway"
              style={{ width: 50, height: 50 }}
            />
          </div>
        );
      })}
    </div>
  );
}

const renderPlayer = (player: Player): JSX.Element => {
  return (
    <div
      style={{
        position: "relative",
        left: `${player.x}px`,
        top: `${player.y}px`,
      }}
    >
      <img
        src={player.type === "cat" ? "cat.png" : "./mouse.png"}
        alt="player"
        style={{ width: 150, height: 150 }}
      />
    </div>
  );
};
