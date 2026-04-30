import type { Game, Cat, Mouse, Subway, Player, ActiveVote } from "../types";
import type { JSX } from "preact/jsx-runtime";

export function renderGameField(
  gameState: Game,
  player: Player,
  onVote: (subwayId: number) => void,
  onStartVote: () => void,
  onEnterSubway: (subwayId: number) => void,
  onLeaveSubway: (exitId: number) => void,
): JSX.Element {
  return (
    <div
      style={{
        position: "relative",
        backgroundColor: "grey",
        width: gameState.fieldSize.width,
        height: gameState.fieldSize.height,
      }}
    >
      {renderDevPlayerPosition(player)}
      <div
        style={{
          position: "absolute",
          inset: 0,
        }}
      >
        {renderComponents(
          gameState,
          player,
          onVote,
          onStartVote,
          onEnterSubway,
          onLeaveSubway,
        )}
      </div>
    </div>
  );
}

const renderDevPlayerPosition = (player: Player): JSX.Element => {
  return (
    <div
      style={{
        position: "absolute",
        top: 8,
        left: 8,
        zIndex: 20,
        padding: "4px 8px",
        borderRadius: 6,
        backgroundColor: "rgba(0, 0, 0, 0.75)",
        color: "#ffffff",
        fontSize: "12px",
        fontFamily: "monospace",
        pointerEvents: "none",
      }}
    >
      Player: ({player.x}, {player.y})
    </div>
  );
};

export function renderComponents(
  gameState: Game,
  player: Player,
  onVote: (subwayId: number) => void,
  onStartVote: () => void,
  onEnterSubway: (subwayId: number) => void,
  onLeaveSubway: (exitId: number) => void,
): JSX.Element {
  const canAct = !(player.role === "mouse" && gameState.status === "caught");
  const showVotingMenu =
    canAct &&
    player.role === "mouse" &&
    typeof player.subway !== "undefined" &&
    typeof gameState.activeVote !== "undefined";

  return (
    <div>
      {player && renderPlayer(player, gameState.fieldSize)}
      {(() => {
        const mouseSize = 50;
        const gap = 10;
        const subwayMice = gameState.mice.filter((m) => typeof m.subway !== "undefined");
        const playerLeft = typeof player.subway !== "undefined" ? gameState.fieldSize.width / 2 : player.x;
        const playerTop = typeof player.subway !== "undefined" ? gameState.fieldSize.height / 2 : player.y;
        const lineTop = playerTop - mouseSize - 20;
        const lineStartLeft = playerLeft - (subwayMice.length * (mouseSize + gap) - gap) / 2;

        return gameState.mice.map((mouse: Mouse, index: number) => {
          let left: number;
          let top: number;
          if (typeof mouse.subway !== "undefined") {
            const subwayIndex = subwayMice.indexOf(mouse);
            left = lineStartLeft + subwayIndex * (mouseSize + gap);
            top = lineTop;
          } else {
            left = mouse.x;
            top = mouse.y;
          }
          return (
            <div
              key={index}
              style={{ position: "absolute", left, top, transform: "translate(-50%, -50%)", display: "flex", flexDirection: "column", alignItems: "center" }}
            >
              <img src="./mouse.png" alt="mouse" style={{ width: mouseSize, height: mouseSize }} />
              {renderNameTag(mouse.name)}
            </div>
          );
        });
      })()}
      {gameState.cats.map((cat: Cat, index: number) => {
        return (
          <div
            key={index}
            style={{
              position: "absolute",
              left: cat.x,
              top: cat.y,
              transform: "translate(-50%, -50%)",
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
            }}
          >
            <img
              src="./cat.png"
              alt={cat.type === "ghost" ? "ghost cat" : "cat"}
              style={{
                width: 90,
                height: 90,
                opacity: cat.type === "ghost" ? 0.6 : 1,
                filter: cat.type === "ghost" ? "grayscale(100%)" : "none",
              }}
            />
            {renderNameTag(cat.name)}
          </div>
        );
      })}
      {gameState.subways.map((subway: Subway, index: number) => {
        return (
          <>
            {subway.exits.map((exit, exitIdx) => (
              <div
                key={`subway-${subway.id ?? index}-exit-${exitIdx}`}
                onClick={() => {
                  if (!canAct) return;
                  if (typeof subway.id !== "undefined")
                    onEnterSubway(subway.id);
                }}
                style={{
                  position: "absolute",
                  left: exit.x,
                  top: exit.y,
                  transform: "translate(-50%, -50%)",
                }}
              >
                <span
                  role="img"
                  aria-label="subway entrance"
                  style={{
                    fontSize: "2.5rem",
                    display: "inline-block",
                    width: 50,
                    height: 50,
                    lineHeight: "50px",
                    textAlign: "center",
                  }}
                >
                  🕳️
                </span>

                <div
                  style={{ fontSize: "0.8rem", color: "#333", lineHeight: 1.1 }}
                >
                  <div>
                    {typeof subway.id !== "undefined"
                      ? `ID: ${subway.id}`
                      : "ID: -"}{" "}
                    Exit: ({exit.x}, {exit.y})
                  </div>
                  {typeof subway.name !== "undefined" && (
                    <div style={{ marginTop: 1 }}>Name: {subway.name}</div>
                  )}
                </div>
              </div>
            ))}
          </>
        );
      })}
      {showVotingMenu && gameState.activeVote
        ? renderVotingMenu(gameState.activeVote, gameState.subways, onVote)
        : renderStartVoteButton(player, canAct, onStartVote)}
      {canAct &&
        player.role === "mouse" &&
        typeof player.subway !== "undefined" &&
        renderLeaveSubwayMenu(player.subway, gameState.subways, onLeaveSubway)}
    </div>
  );
}

const renderNameTag = (name: string): JSX.Element => (
  <div
    style={{
      marginTop: 2,
      padding: "1px 5px",
      borderRadius: 4,
      backgroundColor: "rgba(0,0,0,0.55)",
      color: "#fff",
      fontSize: 11,
      whiteSpace: "nowrap",
    }}
  >
    {name}
  </div>
);

const renderPlayer = (player: Player, fieldSize: { width: number; height: number }): JSX.Element => {
  const isOutside = player.role === "mouse" && player.subway === undefined;
  const left = typeof player.subway !== "undefined" ? fieldSize.width / 2 : player.x;
  const top = typeof player.subway !== "undefined" ? fieldSize.height / 2 : player.y;
  return (
    <div
      style={{
        position: "absolute",
        left,
        top,
        transform: "translate(-50%, -50%)",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
      }}
    >
      <img
        src={player.role === "cat" ? "cat.png" : "./mouse.png"}
        alt="player"
        style={
          player.role === "cat"
            ? { width: 100, height: 100 }
            : {
                width: 45,
                height: 45,
                ...(isOutside
                  ? {
                      filter: "drop-shadow(0 0 8px #ef4444)",
                      outline: "2px solid #ef4444",
                      borderRadius: "50%",
                    }
                  : {}),
              }
        }
      />
      {renderNameTag(player.name)}
    </div>
  );
};

const renderVotingMenu = (
  activeVote: ActiveVote,
  subways: Subway[],
  onVote: (subwayId: number) => void,
): JSX.Element => {
  return (
    <div
      style={{
        position: "absolute",
        right: 16,
        top: 16,
        zIndex: 10,
        padding: 12,
        minWidth: 220,
        borderRadius: 8,
        border: "1px solid #1f2937",
        backgroundColor: "rgba(17, 24, 39, 0.95)",
        color: "#f9fafb",
      }}
    >
      <div style={{ fontWeight: 700, marginBottom: 6 }}>Vote Ongoing</div>
      <div style={{ marginBottom: 10 }}>Time left: {activeVote.timeLeft}s</div>
      {activeVote.votes.map((vote) => {
        const subway = subways.find((entry) => entry.id === vote.subwayId);
        const label = subway?.name ?? `Subway ${vote.subwayId}`;
        return (
          <button
            key={vote.subwayId}
            onClick={() => {
              if (subway) onVote(vote.subwayId);
            }}
            style={{
              display: "block",
              width: "100%",
              marginBottom: 6,
              padding: "6px 8px",
            }}
          >
            {label}: {vote.votes}
          </button>
        );
      })}
    </div>
  );
};

const renderLeaveSubwayMenu = (
  subwayId: number,
  subways: Subway[],
  onLeaveSubway: (exitId: number) => void,
): JSX.Element => {
  const subway = subways.find((s) => s.id === subwayId);
  return (
    <div
      style={{
        position: "absolute",
        right: 16,
        bottom: 16,
        zIndex: 10,
        padding: 12,
        minWidth: 180,
        borderRadius: 8,
        border: "1px solid #1f2937",
        backgroundColor: "rgba(17, 24, 39, 0.95)",
        color: "#f9fafb",
      }}
    >
      <div style={{ fontWeight: 700, marginBottom: 8 }}>
        {subway?.name ?? `Subway ${subwayId}`}
      </div>
      {subway?.exits.map((exit, idx) => (
        <button
          key={exit.id ?? idx}
          disabled={typeof exit.id === "undefined"}
          onClick={() => {
            if (typeof exit.id !== "undefined") onLeaveSubway(exit.id);
          }}
          style={{ display: "block", width: "100%", marginBottom: 6, padding: "6px 8px" }}
        >
          Leave via exit {idx + 1} ({exit.x}, {exit.y})
        </button>
      ))}
    </div>
  );
};

const renderStartVoteButton = (
  player: Player,
  canAct: boolean,
  onStartVote: () => void,
): JSX.Element => {
  const canStartVote = canAct && typeof player.subway !== "undefined";

  return (
    <div
      style={{
        position: "absolute",
        right: 16,
        top: 16,
        zIndex: 10,
      }}
    >
      <button
        disabled={!canStartVote}
        onClick={() => {
          const subwayId = player.subway;
          if (typeof subwayId !== "undefined") onStartVote();
        }}
        style={{ padding: "8px 10px" }}
      >
        Start vote
      </button>
    </div>
  );
};
