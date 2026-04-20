import { useEffect, useRef, useState } from "preact/hooks";
import "./app.css";
import type { Game, Player, Role } from "./types";
import type {
  CaughtMessage,
  GameInitMessage,
  GameUpdateMessage,
  VoteResultMessage,
} from "./features/types";
import { renderGameField } from "./views/renderGame";
import { renderButton } from "./views/renderMenus";
import {
  handleCaughtMessage,
  handleGameInitMessage,
  handleGameUpdateMessage,
} from "./features/game";
import { handlePlayerVote, handleStartPlayerVote } from "./features/voting";
import {
  checkAutoEnterSubwayAsMouse,
  handlePlayerEnterSubway,
} from "./features/subwayLogic";

export function App() {
  const [gameCode, setGameCode] = useState<string | null>(null);
  const [gameCodeInput, setGameCodeInput] = useState("");
  const [backendError, setBackendError] = useState<string | null>(null);
  const [gameState, setGameState] = useState<Game | null>(null);
  const [player, setPlayer] = useState<Player | null>(null);
  const [voteResult, setVoteResult] = useState<{
    winSubway: number;
    token: number;
  } | null>(null);

  //const getNewStuff(stuff => renderGameField(stuff))

  const wsRef = useRef<WebSocket | null>(null);
  const lastAutoEnterKeyRef = useRef<string | null>(null);

  const parseServerMessage = (
    rawMessage: MessageEvent["data"],
  ):
    | GameInitMessage
    | GameUpdateMessage
    | VoteResultMessage
    | CaughtMessage
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
        | CaughtMessage
        | GameInitMessage
        | GameUpdateMessage
        | VoteResultMessage;
    }

    return null;
  };

  const joinGame = async (gameCode: string, role: Role): Promise<string> => {
    try {
      setBackendError(null);
      console.log("Joining game " + gameCode);
      await fetch(
        `http://localhost:8080/games/${gameCode}/players?playerName=${encodeURIComponent("playerName")}?role=${role}`, // todo add role:
        // joinGame and createGame also set the playerId, see REST.md
        {
          method: "POST",
          credentials: "include",
        },
      );
    } catch (error) {
      console.error("Failed to create game:", error);
      setBackendError("Failed: server running?");
      throw error;
    }

    //console.log(response);
    console.log("opening websocket");
    const socket = new WebSocket("ws://localhost:8080/games/ws");

    socket.onopen = () => console.log("Connected to WebSocket server");
    socket.onmessage = (event: MessageEvent) => {
      //const msg = JSON.parse(event.data);
      //console.log("raw WS msg", msg);
      const serverMessage = parseServerMessage(event.data);
      if (!serverMessage) return;

      //console.log("onmessage:", serverMessage);
      switch (serverMessage.type) {
        case "GAME_INIT":
          handleGameInitMessage(serverMessage, setGameState, setPlayer);
          break;
        case "GAME_UPDATE":
          if (!serverMessage.mice) {
            return;
          }
          handleGameUpdateMessage(serverMessage, setGameState, setPlayer);
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
      }
    };
    socket.onclose = () => console.log("Disconnected from WebSocket server");
    socket.onerror = (err) => console.error("WebSocket error:", err);
    wsRef.current = socket;
    wsRef.current = socket;
    return gameCode;
  };
  const exitGame = () => {
    wsRef.current?.close();
    wsRef.current = null;
    setGameCode(null);
  };

  useEffect(() => {}, [wsRef.current]);
  useEffect(() => {}, [gameCode, gameState]);

  useEffect(() => {
    return () => wsRef.current?.close();
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

  const createGame = async (): Promise<string> => {
    try {
      setBackendError(null);
      // todo: it also auto-joins that game
      const res = await fetch("http://localhost:8080/games", {
        method: "POST",
        credentials: "include",
      });
      if (!res.ok) throw new Error("Failed to create game");
      const data = await res.json(); // { role, playerName, code }
      console.log("gamecode. " + data.code);
      return data.code;
    } catch (error) {
      console.error("Failed to create game:", error);
      setBackendError("Failed: server running?");
      throw error;
    }
  };

  // https://medium.com/@chaman388/websockets-in-reactjs-a-practical-guide-with-real-world-examples-2efe483ee150

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

  useEffect(() => {
    if (!gameCode || !gameState || !player) {
      lastAutoEnterKeyRef.current = null;
      return;
    }
    const ws = wsRef.current;
    if (!ws || ws.readyState !== WebSocket.OPEN) return;

    checkAutoEnterSubwayAsMouse(player, gameState, lastAutoEnterKeyRef, ws);
  }, [gameCode, gameState, player?.role, player?.subway, player?.x, player?.y]);

  // catch keydown events for moving:
  useEffect(() => {
    if (!gameCode) return;
    const onKeyDown = (e: KeyboardEvent) => {
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
      ws.send(
        JSON.stringify({
          type: "MOVE",
          test: e.key,
        }),
      );

      // Change the player's x or y coordinates depending on the key press.
      // Use the previous state to avoid stale closures in this effect.
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
        // Keep within bounds if needed (optional, can be removed/modified)
        x = Math.max(0, Math.min(350, x)); // todo gamefield size width and height
        y = Math.max(0, Math.min(350, y));

        return {
          ...prevPlayer,
          x,
          y,
        };
      });
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [gameCode, player, gameState?.status]);

  // mock update message:
  useEffect(() => {
    if (!gameCode) return;

    const mockGameUpdate: GameUpdateMessage = {
      type: "GAME_UPDATE",
      seq: 1,
      timeLeft: 119,
      player: {
        id: 7,
        name: "player",
        role: "mouse",
        subway: undefined,
        position: undefined,
      },
      mice: [
        {
          id: 21,
          name: "outside-mouse",
          subway: undefined,
          position: { x: 220, y: 120 },
        },
      ],
      cats: [
        {
          id: 1,
          name: "tom",
          position: { x: 320, y: 220 },
          type: "live",
        },
        {
          id: 2,
          name: "ghost-tom",
          position: { x: 130, y: 240 },
          type: "ghost",
        },
      ],
      active_vote: undefined /* {
        timeLeft: 15,
        votes: [
          { subwayId: 1, votes: 2 },
          { subwayId: 2, votes: 3 },
        ],
      },*/,
    };

    const timer = setTimeout(
      () => handleGameUpdateMessage(mockGameUpdate, setGameState, setPlayer),
      1200,
    );

    return () => clearTimeout(timer);
  }, [gameCode]);

  // mock vote result message:
  useEffect(() => {
    if (!gameCode) return;

    const mockVoteResult: VoteResultMessage = {
      type: "VOTE_RESULT",
      win_subway: 2,
    };

    const timer = setTimeout(() => {
      setVoteResult((prevResult) => ({
        winSubway: mockVoteResult.win_subway,
        token: (prevResult?.token ?? 0) + 1,
      }));
    }, 5000);

    return () => clearTimeout(timer);
  }, [gameCode]);

  // mock caught message: TODO remove
  /*useEffect(() => {
    if (!gameCode) return;
    if (player?.role !== "mouse") return;

    const mockCaught: CaughtMessage = {
      type: "CAUGHT",
    };

    const timer = setTimeout(() => {
      handleCaughtMessage(mockCaught, setGameState);
    }, 30000);

    return () => clearTimeout(timer);
  }, [gameCode, player?.role]);*/

  // mock init message:
  useEffect(() => {
    if (!gameCode) return;
    // Mock data resembling a GAME_INIT message
    const mockGameInit: GameInitMessage = {
      type: "GAME_INIT",
      role: "mouse",
      fieldSize: {
        width: 600,
        height: 400,
      },
      playerPosition: { x: 50, y: 50 },
      subways: [
        {
          id: 1,
          name: "Red Line",
          exits: [
            { x: 100, y: 100 },
            { x: 300, y: 200 },
          ],
        },
        {
          id: 2,
          name: "Blue Line",
          exits: [
            { x: 400, y: 100 },
            { x: 200, y: 350 },
          ],
        },
      ],
    };

    // Call the handler with mock data to initialize game state
    setTimeout(
      () => handleGameInitMessage(mockGameInit, setGameState, setPlayer),
      500,
    );

    // Only once per gameCode
    // eslint-disable-next-line
  }, [gameCode]);

  return (
    <>
      <section id="center">
        <h1>Cat & Mouse</h1>
        {gameCode && renderButton("Exit", exitGame)}

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
        {backendError && (
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
            {backendError}
          </div>
        )}
        {gameState &&
          gameCode &&
          player &&
          renderGameField(
            gameState,
            player,
            handleVote,
            handleStartVote,
            handleEnterSubway,
          )}
        {!gameCode &&
          renderButton("Create Game & Join (as cat)", async () => {
            const gameCode = await joinGame(await createGame(), "cat");
            setGameCode(gameCode);
          })}
        {!gameCode &&
          renderButton("Create Game & Join (as mouse)", async () => {
            const gameCode = await joinGame(await createGame(), "mouse");
            setGameCode(gameCode);
          })}
        {!gameCode && (
          <input
            type="text"
            placeholder="Enter Game Code"
            value={gameCodeInput}
            onInput={(e) =>
              setGameCodeInput((e.target as HTMLInputElement).value)
            }
            style={{ margin: "8px", padding: "4px", fontSize: "1rem" }}
          />
        )}

        {!gameCode &&
          renderButton("Join Game (as cat)", async () => {
            const gameCode = await joinGame(gameCodeInput, "cat");
            setGameCode(gameCode);
          })}
      </section>

      <section id="next-steps">
        <div id="footer">
          <p>PPL - Group X</p>
        </div>
      </section>
    </>
  );
}
