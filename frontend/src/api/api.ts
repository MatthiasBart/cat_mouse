import type { Role } from "../types";

export const joinGame = async (name: string, gameCode: string, role: Role): Promise<void> => {
  console.log("Joining game " + gameCode);
  const response = await fetch(
    `http://localhost:8080/games/${gameCode}/players?playerName=${encodeURIComponent(name)}&role=${role}`,
    {
      method: "POST",
      credentials: "include",
    },
  );

  if (!response.ok) {
    throw new Error("Failed to add AI");
  }
};

export const createGame = async (
  role: Role,
  playerName: string,
): Promise<string> => {
  const url = `http://localhost:8080/games?role=${encodeURIComponent(role)}&playerName=${encodeURIComponent(playerName)}`;
  const res = await fetch(url, {
    method: "POST",
    credentials: "include",
  });

  if (!res.ok) throw new Error("Failed to create game");
  const data = await res.json();
  console.log("gamecode. " + data?.code);
  return data?.code;
};

export async function addAI(code: string, role: Role): Promise<void> {
  console.log("addAI called with:", { code, role: role.toUpperCase() });
  const response = await fetch(
    `http://localhost:8080/games/${encodeURIComponent(code)}/ai?role=${encodeURIComponent(role.toUpperCase())}`,
    {
      method: "POST",
      credentials: "include",
    },
  );

  if (!response.ok) {
    throw new Error("Failed to add AI");
  }
}

export async function startGame(code: string): Promise<void> {
  const response = await fetch(
    `http://localhost:8080/games/${encodeURIComponent(code)}`,
    {
      method: "PATCH",
      credentials: "include",
    },
  );

  if (!response.ok) {
    throw new Error("Failed to start game");
  }
}
