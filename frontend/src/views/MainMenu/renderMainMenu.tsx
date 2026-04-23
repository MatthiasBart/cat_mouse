import { useState } from "preact/hooks";
import type { JSX } from "preact/jsx-runtime";
import "./style.css";
import { renderButton } from "../renderComponents";
import type { Role } from "../../types";
import { createGame, joinGame } from "../../api/api";

export function renderMainMenu(onJoin: (code: string) => void): JSX.Element {
  const [name, setName] = useState("");
  const [role, setRole] = useState<Role | null>();

  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: Event) => {
    e.preventDefault();
    // const gameCode = await joinGame(await createGame(), "cat");
    /*
              renderButton("Create Game & Join (as mouse)", async () => {
          const gameCode = await joinGame(await createGame(), "mouse");
          setGameCode(gameCode);
        })
          */

    const trimmedName = name.trim();

    if (!trimmedName) {
      setError("Please enter a name.");
      return;
    }

    if (!role) {
      setError("Please choose a role.");
      return;
    }

    try {
      const code = await createGame(role, name);
      onJoin(code);
      console.log("response code");
      console.log(code);
    } catch (e) {
      setError("Failed: server running?");
    }

    setError(null);
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
          }
        >
          <option value="">Select a role</option>
          <option value="cat">Cat</option>
          <option value="mouse">Mouse</option>
        </select>

        <button type="submit">Join Game</button>

        {error && <p class="error">{error}</p>}
      </div>
    </form>
  );
}
