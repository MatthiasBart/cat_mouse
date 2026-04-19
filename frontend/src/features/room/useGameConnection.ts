import { useEffect, useMemo, useState } from 'preact/hooks';
import { useLocation } from 'preact-iso';

import api from './api';
import type { AIRole } from './api';
import type {
  ConnectionInitMessage,
  GameInitMessage,
  GameUpdateMessage,
  PlayerJoinedMessage,
  RoomPlayer,
} from './types';

type GameConnectionState = {
  status: string;
  started: boolean;
  players: RoomPlayer[];
  currentPlayerId: number | null;
  starting: boolean;
  addingAI: boolean;
  aiRole: AIRole;
  error: string | null;
  serverGameState: GameUpdateMessage | null;
};

export function useGameConnection(code: string) {
  const location = useLocation();
  const [state, setState] = useState<GameConnectionState>({
    status: 'Connecting...',
    started: false,
    players: [],
    currentPlayerId: null,
    starting: false,
    addingAI: false,
    aiRole: 'MOUSE',
    error: null,
    serverGameState: null,
  });

  useEffect(() => {
    const ws = new WebSocket(`ws://localhost:8080/games/${encodeURIComponent(code)}/ws`);

    ws.onopen = () => {
      setState((previousState) => ({
        ...previousState,
        status: `Connected to room ${code}`,
      }));
    };

    ws.onmessage = (event) => {
      try {
        const parsed = JSON.parse(String(event.data)) as
          | ConnectionInitMessage
          | PlayerJoinedMessage
          | GameInitMessage
          | GameUpdateMessage;

        if (parsed.type === 'CONNECTION_INIT') {
          console.log('[WS] CONNECTION_INIT', parsed);
          setState((previousState) => ({
            ...previousState,
            started: parsed.started,
            currentPlayerId: parsed.currentPlayerId,
            players: parsed.players,
          }));
          return;
        }

        if (parsed.type === 'GAME_INIT') {
          console.log('[WS] GAME_INIT', parsed);
          setState((previousState) => ({ ...previousState, started: true }));
          return;
        }

        if (parsed.type === 'PLAYER_JOINED') {
          console.log('[WS] PLAYER_JOINED', parsed);
          setState((previousState) => {
            const alreadyKnown = previousState.players.some(
              (player) => player.playerId === parsed.player.playerId,
            );
            if (alreadyKnown) return previousState;
            return { ...previousState, players: [...previousState.players, parsed.player] };
          });
          return;
        }

        if (parsed.type === 'GAME_UPDATE') {
          setState((previousState) => ({ ...previousState, serverGameState: parsed }));
        }
      } catch {
        // ignore non-json placeholder messages for now
      }
    };

    ws.onerror = () => {
      setState((previousState) => ({
        ...previousState,
        status: 'Connection rejected. Redirecting...',
      }));
      location.route('/');
    };

    ws.onclose = () => {
      setState((previousState) => ({
        ...previousState,
        status: 'Session invalid or expired. Redirecting...',
      }));
      location.route('/');
    };

    return () => {
      ws.close();
    };
  }, [code, location]);

  const creator = useMemo(
    () => state.players.find((player) => player.isCreator) ?? null,
    [state.players],
  );

  const isCurrentPlayerCreator =
    state.currentPlayerId !== null && creator?.playerId === state.currentPlayerId;

  const onStartGame = async () => {
    setState((previousState) => ({ ...previousState, error: null, starting: true }));
    try {
      await api.startGame(code);
    } catch (startError) {
      console.error(startError);
      setState((previousState) => ({
        ...previousState,
        error: 'Failed to start game.',
      }));
    } finally {
      setState((previousState) => ({ ...previousState, starting: false }));
    }
  };

  const setAIRole = (role: AIRole) => {
    setState((previousState) => ({ ...previousState, aiRole: role }));
  };

  const onAddAI = async () => {
    setState((previousState) => ({ ...previousState, error: null, addingAI: true }));
    try {
      await api.addAI(code, state.aiRole);
    } catch (addError) {
      console.error(addError);
      setState((previousState) => ({
        ...previousState,
        error: 'Failed to add AI.',
      }));
    } finally {
      setState((previousState) => ({ ...previousState, addingAI: false }));
    }
  };

  return {
    ...state,
    creatorName: creator?.playerName ?? null,
    isCurrentPlayerCreator,
    onStartGame,
    onAddAI,
    setAIRole,
  };
}
