import { useEffect, useRef, useState } from "preact/hooks";
import "./app.css";
import type { Game, Player } from "./types";
import type {
  CaughtMessage,
  ConnectionInitMessage,
  ErrorMessage,
  GameEndedMessage,
  GameInitMessage,
  GameUpdateMessage,
  PlayerJoinedMessage,
  VoteResultMessage,
} from "./features/types";
import { renderGameField } from "./views/renderGame";
import { renderButton } from "./views/renderComponents";
import {
  handleCaughtMessage,
  handleGameEndedMessage,
  handleGameInitMessage,
  handleGameUpdateMessage,
} from "./features/game";
import { handlePlayerVote, handleStartPlayerVote } from "./features/voting";
import {
  findNearbySubwayId,
  handlePlayerEnterSubway,
  handlePlayerLeaveSubway,
} from "./features/subwayLogic";
import { renderMainMenu } from "./views/MainMenu/renderMainMenu";
import { RenderRoom } from "./views/Room/renderRoom";

export function App() {
  const [gameActive, setGameActive] = useState<"true" | "room" | "false">(
    "false",
  );
  //const [gameCodeInput, setGameCodeInput] = useState("");
  const [connectionInitResult, setConnectionInitResult] =
    useState<ConnectionInitMessage | null>(null);
  const [gameState, setGameState] = useState<Game | null>(null);
  const [player, setPlayer] = useState<Player | null>(null);
  const [voteResult, setVoteResult] = useState<{
    winSubway: number;
    token: number;
  } | null>(null);

  const wsRef = useRef<WebSocket | null>(null);

  const parseServerMessage = (
    rawMessage: MessageEvent["data"],
  ):
    | GameInitMessage
    | GameUpdateMessage
    | GameEndedMessage
    | VoteResultMessage
    | CaughtMessage
    | ConnectionInitMessage
    | PlayerJoinedMessage
    | ErrorMessage
    | null => {
    if (typeof rawMessage === "string") {
      try {
        return JSON.parse(rawMessage);
      } catch (error) {
        console.error("Failed to parse websocket message:", error);
        return null;
      }
    }

    if (typeof rawMessage === "object" && rawMessage !== null) {
      return rawMessage as
        | ConnectionInitMessage
        | PlayerJoinedMessage
        | CaughtMessage
        | GameInitMessage
        | GameUpdateMessage
        | VoteResultMessage
        | ErrorMessage;
    }

    return null;
  };

  const onJoin = async (code: string): Promise<void> => {
    sessionStorage.setItem("gameCode", code);
    setGameActive("room");
    console.log("opening websocket");
    const socket = new WebSocket(`ws://localhost:8080/games/${code}/ws`);

    socket.onopen = () => console.log("Connected to WebSocket server");
    socket.onmessage = (event: MessageEvent) => {
      const serverMessage = parseServerMessage(event.data);

      if (!serverMessage) return;
      console.log(serverMessage.type + " WS msg");
      console.log(event.data);

      switch (serverMessage.type) {
        case "GAME_INIT":
          handleGameInitMessage(serverMessage, setGameState, setPlayer);
          setGameActive("true");
          break;
        case "GAME_UPDATE":
          if (!serverMessage.mice) {
            return;
          }
          handleGameUpdateMessage(serverMessage, setGameState, setPlayer);
          setGameActive("true");
          break;
        case "GAME_ENDED":
          handleGameEndedMessage(serverMessage, player, setGameState);
          break;
        case "CAUGHT":
          handleCaughtMessage(serverMessage, setGameState);
          break;
        case "VOTE_RESULT":
          setVoteResult((prevResult) => ({
            winSubway: serverMessage.win_subway,
            token: (prevResult?.token ?? 0) + 1,
          }));
          break;
        case "CONNECTION_INIT":
          setConnectionInitResult(serverMessage);
          break;
        case "PLAYER_JOINED":
          console.log("[WS] PLAYER_JOINED");
          //if (!connectionInitResult) break;
          setConnectionInitResult((previousState) => {
            if (!previousState) return previousState;

            const alreadyKnown = previousState.players.some(
              (player) => player.playerId === serverMessage.player.playerId,
            );
            if (alreadyKnown) return previousState;
            return {
              ...previousState,
              players: [...previousState.players, serverMessage.player],
            };
          });
          break;
        case "ERROR":
          alert(`Error: ${serverMessage.message} (Code: ${serverMessage.code})`);
          break;
      }
    };
    socket.onclose = () => {
      console.log("Disconnected from WebSocket server");
      if (wsRef.current === socket) {
        exitGame();
      }
    };
    socket.onerror = (err) => console.error("WebSocket error:", err);
    wsRef.current = socket;
  };

  const onGameStarted = async (): Promise<void> => {
    setGameActive("true");
  };

  // Exit room/game functionality, as used by "onExitRoom" and main exit button
  const exitGame = () => {
    if (wsRef.current?.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify({ type: "LEAVE_GAME" }));
    }
    const ws = wsRef.current;
    wsRef.current = null;
    ws?.close();
    sessionStorage.removeItem("gameCode");
    setConnectionInitResult(null);
    setGameState(null);
    setPlayer(null);
    setVoteResult(null);
    setGameActive("false");
  };

  // Provide onExitRoom for RenderRoom (room phase), just closes and resets as above
  const onExitRoom = (): void => {
    exitGame();
  };

  useEffect(() => {}, [wsRef.current]);

  useEffect(() => {
    const savedCode = sessionStorage.getItem("gameCode");
    if (savedCode) {
      onJoin(savedCode);
    }
    return () => {
      const ws = wsRef.current;
      wsRef.current = null;
      ws?.close();
    };
  }, []);

  useEffect(() => {
    if (!voteResult) return;

    const currentToken = voteResult.token;
    const timer = setTimeout(() => {
      setVoteResult((prevResult) => {
        if (!prevResult) return prevResult;
        if (prevResult.token !== currentToken) return prevResult;
        return null;
      });
    }, 15000);

    return () => clearTimeout(timer);
  }, [voteResult]);

  const handleVote = (subwayId: number) => {
    if (player?.role === "mouse" && gameState?.status === "caught") return;

    const ws = wsRef.current;
    if (!ws || ws.readyState !== WebSocket.OPEN) return;

    handlePlayerVote(subwayId, ws);
  };

  const handleStartVote = () => {
    if (player?.role === "mouse" && gameState?.status === "caught") return;

    const ws = wsRef.current;
    if (!ws || ws.readyState !== WebSocket.OPEN) return;

    handleStartPlayerVote(ws);
  };

  const handleEnterSubway = (subwayId: number) => {
    if (player?.role === "mouse" && gameState?.status === "caught") return;

    const ws = wsRef.current;
    if (!ws || ws.readyState !== WebSocket.OPEN) return;

    handlePlayerEnterSubway(subwayId, ws);
  };

  const handleLeaveSubway = (exitId: number) => {
    if (player?.role === "mouse" && gameState?.status === "caught") return;

    const ws = wsRef.current;
    if (!ws || ws.readyState !== WebSocket.OPEN) return;

    handlePlayerLeaveSubway(exitId, ws);
  };

  useEffect(() => {
    console.log("gameActive:", gameActive);
    console.log("gameState:", gameState);
    console.log("player:", player);
  }, [gameActive, gameState, player]);

  // catch keydown events for moving:
  useEffect(() => {
    if (!gameActive) return;
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === "e" || e.key === "E") {
        if (
          player?.role === "mouse" &&
          gameState &&
          typeof player.subway === "undefined"
        ) {
          const ws = wsRef.current;
          if (ws && ws.readyState === WebSocket.OPEN) {
            const subwayId = findNearbySubwayId(player, gameState);
            if (typeof subwayId !== "undefined")
              handlePlayerEnterSubway(subwayId, ws);
          }
        }
        return;
      }
      if (
        e.key !== "ArrowUp" &&
        e.key !== "ArrowDown" &&
        e.key !== "ArrowLeft" &&
        e.key !== "ArrowRight"
      ) {
        return;
      }
      if (player?.role === "mouse" && gameState?.status === "caught") return;

      //console.log("onKeyDown " + e.key);
      e.preventDefault();
      const ws = wsRef.current;
      if (!ws || ws.readyState !== WebSocket.OPEN) return;

      const directionByKey: Record<string, "UP" | "DOWN" | "LEFT" | "RIGHT"> = {
        ArrowUp: "UP",
        ArrowDown: "DOWN",
        ArrowLeft: "LEFT",
        ArrowRight: "RIGHT",
      };
      const direction = directionByKey[e.key];

      ws.send(
        JSON.stringify({
          type: "MOVE",
          direction,
        }),
      );

      const maxX = gameState?.fieldSize?.width ?? 600;
      const maxY = gameState?.fieldSize?.height ?? 450;

      setPlayer((prevPlayer: Player | null) => {
        if (!prevPlayer) return prevPlayer;

        let { x, y } = prevPlayer;
        switch (e.key) {
          case "ArrowUp":
            y -= 10;
            break;
          case "ArrowDown":
            y += 10;
            break;
          case "ArrowLeft":
            x -= 10;
            break;
          case "ArrowRight":
            x += 10;
            break;
          default:
            break;
        }
        x = Math.max(0, Math.min(maxX, x));
        y = Math.max(0, Math.min(maxY, y));

        return {
          ...prevPlayer,
          x,
          y,
        };
      });
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [gameActive, player, gameState?.status, gameState?.fieldSize]);

  return (
    <>
      <section id="center">
        <h1>Cat & Mouse</h1>
        {/* Render the role selection screen. */}
        {gameActive === "false" && renderMainMenu(onJoin)}

        {/* Render a connection info. */}
        {gameActive === "room" && !connectionInitResult && (
          <p>Connecting to room...</p>
        )}

        {/* Render the joining room. */}
        {gameActive === "room" && connectionInitResult && (
          <RenderRoom
            connectionInitResult={connectionInitResult}
            onGameStarted={onGameStarted}
            onExitRoom={onExitRoom}
          />
        )}

        {/* Render a loading info. */}
        {!gameState && gameActive === "true" && <p> Loading Game ...</p>}

        {/* Render the time left banner. */}
        {gameState &&
          gameActive === "true" &&
          typeof gameState.timeLeft !== "undefined" && (
            <div
              style={{
                marginBottom: 8,
                padding: "6px 16px",
                borderRadius: 6,
                backgroundColor: "rgba(0,0,0,0.75)",
                color: "#fff",
                fontFamily: "monospace",
                fontSize: 18,
                fontWeight: 700,
                textAlign: "center",
              }}
            >
              ⏱ {Math.max(0, Math.floor(gameState.timeLeft))}s
            </div>
          )}

        {/* Render the main game field. */}
        {gameState &&
          gameActive === "true" &&
          player &&
          renderGameField(
            gameState,
            player,
            handleVote,
            handleStartVote,
            handleEnterSubway,
            handleLeaveSubway,
          )}
        {/* Render the Exit button at the bottom with spacing from above */}
        {gameActive === "true" && (
          <div
            style={{
              marginTop: "64px",
              display: "flex",
              justifyContent: "center",
            }}
          >
            {renderButton("Exit", exitGame)}
          </div>
        )}

        {/* Render the voting result. */}
        {voteResult && (
          <div
            style={{
              margin: "8px auto",
              maxWidth: "420px",
              padding: "8px 12px",
              border: "1px solid #14532d",
              borderRadius: 8,
              backgroundColor: "#dcfce7",
              color: "#14532d",
              fontWeight: 600,
            }}
          >
            Vote finished. Winning subway:{" "}
            {gameState?.subways.find(
              (subway) => subway.id === voteResult.winSubway,
            )?.name ?? `#${voteResult.winSubway}`}
          </div>
        )}

        {/* Render the caught message. */}
        {player?.role === "mouse" && gameState?.status === "caught" && (
          <div
            style={{
              margin: "8px auto",
              maxWidth: "420px",
              padding: "8px 12px",
              border: "1px solid #7f1d1d",
              borderRadius: 8,
              backgroundColor: "#fee2e2",
              color: "#7f1d1d",
              fontWeight: 600,
            }}
          >
            You were caught. Spectating mode active.
          </div>
        )}

        <div
          style={{
            margin: "16px auto",
            maxWidth: "420px",
            padding: "8px 12px",
            border: "1px solid #d1d5db",
            borderRadius: 8,
            backgroundColor: "#f3f4f6",
            color: "#1f2937",
            fontSize: "15px",
          }}
        >
          <strong>Controls:</strong>
          <ul style={{ margin: "8px 0 0 18px", padding: 0 }}>
            <li>
              <kbd>Arrow Keys</kbd>: Move your character
            </li>
            <li>
              <kbd>E</kbd>: Enter nearby subway (as mouse)
            </li>
          </ul>
        </div>
      </section>

      <section id="footer">
        <div id="footer">
          <p>PPL - Group X</p>
        </div>
      </section>
    </>
  );
}
