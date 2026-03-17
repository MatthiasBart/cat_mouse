export type Game = {
  subways: Subway[];
  cats: Cat[];
  mice: Mouse[];
};

type Subway = {};

interface Positionable {
  x: number;
  y: number;
}
export interface Cat extends Positionable {}
export interface Mouse extends Positionable {}

type Moveable = {};

type Component = {};

//async function mouse(): Component {}
//async function cat(): Component {}

async function layerone() {}
