import type { Role } from "../types";

const backendBase = () => `http://${window.location.hostname}:8080`;

export const joinGame = async (name: string, gameCode: string, role: Role): Promise<void> => {
  console.log("Joining game " + gameCode);
  const response = await fetch(
    `${backendBase()}/games/${gameCode}/players?playerName=${encodeURIComponent(name)}&role=${role}`,
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
  const url = `${backendBase()}/games?role=${encodeURIComponent(role)}&playerName=${encodeURIComponent(playerName)}`;
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
    `${backendBase()}/games/${encodeURIComponent(code)}/ai?role=${encodeURIComponent(role.toUpperCase())}`,
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
    `${backendBase()}/games/${encodeURIComponent(code)}`,
    {
      method: "PATCH",
      credentials: "include",
    },
  );

  if (!response.ok) {
    throw new Error("Failed to start game");
  }
}
