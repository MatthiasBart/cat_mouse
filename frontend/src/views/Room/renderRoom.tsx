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
}: {
  connectionInitResult: ConnectionInitMessage;
  onGameStarted: () => void;
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

  return (
    <section class="room-card">
      <div class="room-header">
        <h2>Room {connectionInitResult.code}</h2>
        <button
          onClick={() =>
            navigator.clipboard.writeText(connectionInitResult.code)
          }
        >
          Copy Code
        </button>
      </div>

      <table class="room-table">
        <thead>
          <tr>
            <th>Player ID</th>
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
              >
                <td>{player.playerId}</td>
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
        <div class="room-actions">
          <button
            type="button"
            onClick={() => onStartGame(connectionInitResult.code)}
            disabled={starting}
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
