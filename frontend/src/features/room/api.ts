const API_BASE_URL = "http://localhost:8080/games";

export type AIRole = 'CAT' | 'MOUSE';

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

async function addAI(code: string, role: AIRole): Promise<void> {
  const response = await fetch(
    `${API_BASE_URL}/${encodeURIComponent(code)}/ai?role=${encodeURIComponent(role)}`,
    {
      method: 'POST',
      credentials: 'include',
    },
  );

  if (!response.ok) {
    throw await parseError(response, 'Failed to add AI');
  }
}

export default {
  startGame,
  addAI,
};
