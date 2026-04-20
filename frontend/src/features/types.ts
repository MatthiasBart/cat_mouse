import type { Role } from "../types";

export type GameInitMessage = {
  type: "GAME_INIT";
  role: Role;
  playerPosition: { x: number; y: number };
  fieldSize: {
    width: number;
    height: number;
  };
  subways: {
    id: number;
    name: string;
    exits: {
      x: number;
      y: number;
    }[];
  }[];
};

export type GameUpdateMessage = {
  type: "GAME_UPDATE";
  seq: number;
  timeLeft: number; // time until game ends (until cats win)
  player: {
    id: number;
    name: string;
    role: Role;
    subway: number | undefined; // id of the subway if inside one
    position: { x: number; y: number } | undefined; // undefined if inside a subway
  };
  mice: {
    id: number;
    position: { x: number; y: number } | undefined; // if outside, it sees other outside mice
    name: string;
    subway: number | undefined; // same id as current player
  }[];
  cats: {
    id: number;
    position: { x: number; y: number }; // as mouse if outside or as cat
    name: string;
    type: "live" | "ghost"; // live if actual player, ghost if it's the last known position of a cat when a mouse enters the same
    // subway like the player.
  }[];
  active_vote:
    | {
        timeLeft: number; // in seconds // optional?
        votes: { subwayId: number; votes: number }[]; // current results for all tunnels
      }
    | undefined;
};

export type VoteResultMessage = {
  type: "VOTE_RESULT";
  win_subway: number;
};

export type CaughtMessage = {
  type: "CAUGHT";
};
