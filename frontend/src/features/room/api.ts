const API_BASE_URL = "http://localhost:8080/games";

async function parseError(response: Response, fallback: string): Promise<Error> {
  const text = await response.text();
  return new Error(text || `${fallback}: ${response.status} ${response.statusText}`);
}

async function startGame(code: string): Promise<void> {
  const response = await fetch(`${API_BASE_URL}/${encodeURIComponent(code)}`, {
    method: "PATCH",
    credentials: "include",
  });

  if (!response.ok) {
    throw await parseError(response, "Failed to start game");
  }
}

export default {
  startGame,
};
