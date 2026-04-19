import { Game } from '../game/Game';
import { Room } from './Room';
import { useGameConnection } from './useGameConnection';

interface GameDetailsProps {
  code: string;
}
export function GameDetails({ code }: GameDetailsProps) {
  const {
    status,
    started,
    players,
    currentPlayerId,
    starting,
    error,
    creatorName,
    isCurrentPlayerCreator,
    onStartGame,
    onAddAI,
    setAIRole,
    aiRole,
    addingAI,
    serverGameState,
  } = useGameConnection(code);

  return (
    <>
      {!started ? (
        <Room
          code={code}
          players={players}
          currentPlayerId={currentPlayerId}
          isCurrentPlayerCreator={isCurrentPlayerCreator}
          creatorName={creatorName}
          onStartGame={onStartGame}
          onAddAI={onAddAI}
          onAIRoleChange={setAIRole}
          aiRole={aiRole}
          starting={starting}
          addingAI={addingAI}
          error={error}
        />
      ) : (
        <Game gameCode={code} gameState={serverGameState} />
      )}
      <p>{status}</p>
    </>
  );
}
