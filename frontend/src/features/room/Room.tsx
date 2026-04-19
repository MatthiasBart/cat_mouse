import './style.css';
import type { RoomPlayer } from './types';
import type { AIRole } from './api';

type RoomProps = {
  code: string;
  players: RoomPlayer[];
  currentPlayerId: number | null;
  isCurrentPlayerCreator: boolean;
  creatorName: string | null;
  onStartGame: () => void;
  onAddAI: () => void;
  onAIRoleChange: (role: AIRole) => void;
  aiRole: AIRole;
  starting: boolean;
  addingAI: boolean;
  error: string | null;
};

export function Room({
  code,
  players,
  currentPlayerId,
  isCurrentPlayerCreator,
  creatorName,
  onStartGame,
  onAddAI,
  onAIRoleChange,
  aiRole,
  starting,
  addingAI,
  error,
}: RoomProps) {
  return (
    <section class="room-card">
      <div class="room-header">
        <h2>Room {code}</h2>
        <button onClick={() => navigator.clipboard.writeText(code)}>
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
          {players.map((player) => {
            const isCurrent = currentPlayerId === player.playerId;
            return (
              <tr
                key={player.playerId}
                class={isCurrent ? 'current-player' : ''}>
                <td>{player.playerId}</td>
                <td>
                  {player.playerName}
                  {isCurrent ? ' (you)' : ''}
                  {player.isCreator ? ' (creator)' : ''}
                  {player.isComputer ? ' (computer)' : ''}
                </td>
                <td>{player.role}</td>
              </tr>
            );
          })}
        </tbody>
      </table>

      {isCurrentPlayerCreator ? (
        <div class="room-actions">
          <button type="button" onClick={onStartGame} disabled={starting}>
            {starting ? 'Starting...' : 'Start Game'}
          </button>

          <div class="ai-actions">
            <label for="ai-role">AI Role</label>
            <select
              id="ai-role"
              value={aiRole}
              onChange={(event) =>
                onAIRoleChange((event.target as HTMLSelectElement).value as AIRole)
              }>
              <option value="CAT">Cat</option>
              <option value="MOUSE">Mouse</option>
            </select>
            <button type="button" onClick={onAddAI} disabled={addingAI}>
              {addingAI ? 'Adding AI...' : 'Add AI'}
            </button>
          </div>
        </div>
      ) : (
        <p>
          Waiting for {creatorName ?? 'creator'} (creator) to start the game.
        </p>
      )}

      {error && <p class="error">{error}</p>}
    </section>
  );
}
