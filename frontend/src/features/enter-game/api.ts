import type { Player, Role } from "../../types/player";

const API_BASE_URL = "http://localhost:8080/games";

async function parseError(response: Response, fallback: string): Promise<Error> {
  const text = await response.text();
  return new Error(text || `${fallback}: ${response.status} ${response.statusText}`);
}

function playerParams(role: Role, playerName: string): URLSearchParams {
  return new URLSearchParams({ role, playerName });
}

async function createGame(role: Role, playerName: string): Promise<Player> {
  const url = new URL(API_BASE_URL);

  url.search = playerParams(role, playerName).toString();

  const response = await fetch(url.toString(), {
    method: "POST",
    credentials: "include",
  });

  if (!response.ok) {
    throw await parseError(response, "Failed to create game");
  }

  return response.json();
}

async function joinGame(code: string, role: Role, playerName: string): Promise<Player> {
  const url = new URL(`${API_BASE_URL}/${encodeURIComponent(code)}/players`);
  url.search = playerParams(role, playerName).toString();

  const response = await fetch(url.toString(), {
    method: "POST",
    credentials: "include",
  });

  if (!response.ok) {
    throw await parseError(response, "Failed to join game");
  }

  return response.json();
}

export default {
  createGame,
  joinGame
};
