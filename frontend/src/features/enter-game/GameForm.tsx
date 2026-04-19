import { useState } from 'preact/hooks';
import { useLocation } from 'preact-iso';
import './style.css';
import api from './api';
import type { Role } from '../../types/player';

type Action = 'create' | 'join';

export function GameForm() {
  const location = useLocation();

  const [name, setName] = useState('');
  const [role, setRole] = useState<Role>('MOUSE');
  const [joinCode, setJoinCode] = useState('');

  const [action, setAction] = useState<Action>('create');
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: Event) => {
    e.preventDefault();

    const trimmedName = name.trim();
    const trimmedCode = joinCode.trim();

    if (!trimmedName) {
      setError('Name is required.');
      return;
    }

    if (action === 'join' && !trimmedCode) {
      setError('Join code is required when joining a room.');
      return;
    }

    setError(null);

    if (action === 'join') {
      try {
        const player = await api.joinGame(trimmedCode, role, trimmedName);
        console.debug(player);
        location.route(`/${encodeURIComponent(player.code)}`);
      } catch (error) {
        console.error(error);
        setError('Failed to join game. Check logs for details.');
      }
      return;
    }

    console.log('Create room', { name: trimmedName, role });
    try {
      const player = await api.createGame(role, trimmedName);
      console.debug(player);
      location.route(`/${encodeURIComponent(player.code)}`);
    } catch (error) {
      console.error(error);
      setError('Unkown error occurred check logs for detail.');
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <div class="game-form">
        <label for="name">Name</label>
        <input
          id="name"
          type="text"
          value={name}
          autocomplete="username"
          onInput={(e) => setName((e.target as HTMLInputElement).value)}
          placeholder="Your name"
        />
        <label for="role">Role</label>

        <select
          id="role"
          name="role"
          onChange={(e) =>
            setRole((e.target as HTMLSelectElement).value as Role)
          }>
          <option value="CAT">Cat</option>
          <option value="MOUSE">Mouse</option>
        </select>

        <button type="submit" onClick={() => setAction('create')}>
          Create Game
        </button>

        <label for="code">or join with</label>
        <input
          id="code"
          type="text"
          value={joinCode}
          onInput={(e) => setJoinCode((e.target as HTMLInputElement).value)}
          placeholder="Code"
        />

        <button type="submit" onClick={() => setAction('join')}>
          Join Game
        </button>

        {error && <p class="error">{error}</p>}
      </div>
    </form>
  );
}
