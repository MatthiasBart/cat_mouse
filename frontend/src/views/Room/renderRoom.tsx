import type { JSX } from "preact/jsx-runtime";
import "./style.css";
import type { Role } from "../../types";
import { addAI, startGame } from "../../api/api";
import { useState } from "preact/hooks";
import type { ConnectionInitMessage } from "../../features/types";

export type RoomPlayer = {
  playerId: number;
  playerName: string;
  role: Role;
  isCreator: boolean;
  isComputer: boolean;
};

export function RenderRoom({
  connectionInitResult,
  onGameStarted,
  onExitRoom,
}: {
  connectionInitResult: ConnectionInitMessage;
  onGameStarted: () => void;
  onExitRoom: () => void;
}) {
  const [addingAI, setAddingAI] = useState<boolean>(false);
  const [aiRole, setAIRole] = useState<Role | null>(null);
  const [starting, setStarting] = useState<boolean>(false);

  const [error, setError] = useState<string>("");

  /*const [state, setState] = useState<GameConnectionState>({
    status: "Connecting...",
    players: [],
    currentPlayerId: null,
    starting: false,

    aiRole: "MOUSE",
    error: null,
    serverGameState: null,
  });*/

  const onAddAI = async () => {
    setAddingAI(true);

    try {
      if (aiRole) await addAI(connectionInitResult.code, aiRole);
    } catch (addError) {
      console.error(addError);
      setError("Failed to add AI.");
    } finally {
      setAddingAI(false);
    }
  };

  const onStartGame = async (code: string) => {
    setError("");
    setStarting(true);

    try {
      await startGame(code);
      onGameStarted();
    } catch (startError) {
      console.error(startError);

      setError("Failed to start game.");
    } finally {
      setStarting(false);
    }
  };

  // New: Handler for exit room
  const handleExitRoom = () => {
    if (onExitRoom) onExitRoom();
  };

  return (
    <section class="room-card">
      <div class="room-header">
        <div>
          <h2>Room</h2>
          <div>
            <button
              onClick={() =>
                navigator.clipboard.writeText(connectionInitResult.code)
              }
            >
              Copy Code
            </button>
            <button
              type="button"
              class="exit-room-btn"
              style={{ marginLeft: "0.5rem" }}
              onClick={handleExitRoom}
            >
              Exit Room
            </button>
          </div>
        </div>

        <code>{connectionInitResult.code}</code>
      </div>

      <table class="room-table">
        <thead>
          <tr>
            <th>Name</th>
            <th>Role</th>
          </tr>
        </thead>
        <tbody>
          {connectionInitResult.players.map((player) => {
            const isCurrent =
              connectionInitResult.currentPlayerId === player.playerId;
            return (
              <tr
                key={player.playerId}
                class={isCurrent ? "current-player" : ""}
                title={`${player.playerId}`}
              >
                <td>
                  {player.playerName}
                  {isCurrent ? " (you)" : ""}
                  {player.isCreator ? " (creator)" : ""}
                  {player.isComputer ? " (computer)" : ""}
                </td>
                <td>{player.role}</td>
              </tr>
            );
          })}
        </tbody>
      </table>

      {connectionInitResult.currentPlayerId !== null &&
      connectionInitResult.players.find((player) => player.isCreator)
        ?.playerId === connectionInitResult.currentPlayerId ? (
        <>
        <div class="room-actions">
          <button
            type="button"
            onClick={() => onStartGame(connectionInitResult.code)}
            disabled={
              starting ||
              !connectionInitResult.players.some(
                (p) => p.role.toLowerCase() === "mouse",
              ) ||
              !connectionInitResult.players.some(
                (p) => p.role.toLowerCase() === "cat",
              )
            }
          >
            {starting ? "Starting..." : "Start Game"}
          </button>

          <div class="ai-actions">
            <label for="ai-role">AI Role</label>
            <select
              id="ai-role"
              value={aiRole ?? ""}
              onChange={(event) =>
                setAIRole((event.target as HTMLSelectElement).value as Role)
              }
            >
              <option value="cat">Cat</option>
              <option value="mouse">Mouse</option>
            </select>
            <button type="button" onClick={onAddAI} disabled={addingAI}>
              {addingAI ? "Adding AI..." : "Add AI"}
            </button>
          </div>
        </div>
        <div class="hint"><i>To start a game, at least 2 mice players and 1 cat player are required.</i></div>
        </>
          
      ) : (
        <p>
          Waiting for{" "}
          {connectionInitResult.players.find((player) => player.isCreator)
            ?.playerName ?? "creator"}{" "}
          (creator) to start the game.
        </p>
      )}

      {error && <p class="error">{error}</p>}
    </section>
  );
}
