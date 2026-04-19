export type RoomPlayer = {
  playerId: number;
  playerName: string;
  role: 'CAT' | 'MOUSE';
  isCreator: boolean;
  isComputer: boolean;
};

export type ConnectionInitMessage = {
  type: 'CONNECTION_INIT';
  code: string;
  started: boolean;
  currentPlayerId: number;
  players: RoomPlayer[];
};

export type PlayerJoinedMessage = {
  type: 'PLAYER_JOINED';
  code: string;
  player: RoomPlayer;
};

export type GameInitMessage = {
  type: 'GAME_INIT';
  code: string;
  role: 'CAT' | 'MOUSE';
};

export type GameUpdateMessage = {
  type: 'GAME_UPDATE';
  // TODO: add all missing fields as described in WS.md
  seq: number;
  time: number;
};
