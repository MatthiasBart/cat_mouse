export type Game = {
  player: Player;
  subways: Subway[];
  cats: Cat[];
  mice: Mouse[];
};

interface Positionable {
  x: number;
  y: number;
}
export type Role = "cat" | "mouse";
export interface Player extends Positionable {
  name: string;
  role: Role;
}
export interface Subway extends Positionable {}
export interface Cat extends Positionable {}
export interface Mouse extends Positionable {}

type Moveable = {};

type Component = {};

//async function mouse(): Component {}
//async function cat(): Component {}

async function layerone() {}
