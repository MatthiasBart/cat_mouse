export type Game = {
  status: "inactive" | "ongoing" | "caught" | "won" | "lost";
  subways: Subway[];
  cats: Cat[];
  mice: Mouse[];
  fieldSize: {
    width: number;
    height: number;
  };
  seq?: number;
  timeLeft?: number;
  activeVote?: ActiveVote;
};

interface Positionable {
  x: number;
  y: number;
}
export type Role = "cat" | "mouse";
export interface Player extends Positionable {
  id?: number;
  name: string;
  role: Role;
  subway?: number;
}
export type Subway = {
  id?: number;
  name?: string;
  exits: { id?: number; x: number; y: number }[];
};
export interface Cat extends Positionable {
  id: number;
  name: string;
  type: "live" | "ghost";
}
export interface Mouse extends Positionable {
  id: number;
  name: string;
  subway?: number;
}

export type ActiveVote = {
  timeLeft: number;
  votes: { subwayId: number; votes: number }[];
};
