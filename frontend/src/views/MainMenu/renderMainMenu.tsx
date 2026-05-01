import { useState } from "preact/hooks";
import type { JSX } from "preact/jsx-runtime";
import "./style.css";
import type { Role } from "../../types";
import { createGame, joinGame } from "../../api/api";

export function renderMainMenu(onJoin: (code: string) => void): JSX.Element {
  const [name, setName] = useState("");
  const [role, setRole] = useState<Role | null>();
  const [code, setCode] = useState<string>("");

  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: Event) => {
    e.preventDefault();

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

  const handleJoin = async () => {
    if (!code) return setError("Enter a code");
    if (!role) return setError("Select a role");
    if (!name) return setError("Enter a name");
    try {
      const gameCode = await joinGame(name, code, role);
      onJoin(code);
      setError(null);
    } catch (e) {
      setError("Failed: server running?");
    }
    /*
              renderButton("Create Game & Join (as mouse)", async () => {
          const gameCode = await joinGame(await createGame(), "mouse");
          setGameCode(gameCode);
        })
          */
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
        <div style={{ height: "8px" }} />

        <button type="submit">Create New Game</button>

        <div style={{ height: "16px" }} />
        <label for="code">Game Code</label>
        <input
          id="code"
          type="text"
          value={code}
          onInput={(e) => setCode((e.target as HTMLInputElement).value)}
          placeholder="Enter code to join"
        />
        <button
          type="button"
          onClick={async () => {
            try {
              if (!role || !code) {
                setError(
                  "Please select a role and enter a code to join a game.",
                );
                return;
              }
              await handleJoin();
              setError(null);
            } catch (e) {
              setError(
                "Failed to join game. Is the server running and the code correct?",
              );
            }
          }}
        >
          Join Existing Game
        </button>
        {error && <p class="error">{error}</p>}
      </div>
    </form>
  );
}
