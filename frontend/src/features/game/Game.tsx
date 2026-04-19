import { useEffect, useRef, useState } from "preact/hooks";

import type { Game, Cat, Mouse } from "../../types";
import { renderComponents, renderGameField } from "../../views/renderGameField";
import { renderButton } from "../../views/renderMenus";

//const wss = new WebSocket.Server({ port: 8080 });
//const websocket = new WebSocket("ws://localhost:8080/games/ws");

/*
async function renderMain() {
  //login()
  //renderTunnels()
  //


  map(tunnels) { tunnel in 
    render(tunnel)
  }
}

renderMain();


async function renderTunnels(tunnels: Tunnel[]) {

        foreach(tunnel) return renderTunnels()
}

*/

/*async function getInitialState() {

  
}*/

export function Game() {
  //const [count, setCount] = useState(0);

  //const initialState: Game = { game: null };
  const [gameCode, setGameCode] = useState<string | null>(null);
  const [gameState, setGameState] = useState<Game>({
    player: { type: "cat", name: "todo", x: 100, y: 100 },
    mice: [
      { x: 10, y: 10 },
      { x: 55, y: 200 },
      { x: 100, y: 100 },
      { x: 100, y: 100 },
    ],
    subways: [
      { x: 100, y: 100 },
      { x: 33, y: 66 },
      { x: 140, y: 200 },
    ],
    cats: [
      { x: 150, y: 70 },
      { x: 200, y: 140 },
      { x: 250, y: 50 },
      { x: 300, y: 180 },
    ],
  });
  //const getNewStuff(stuff => renderGameField(stuff))
  //const [messages, setMessages] = useState([]);

  const wsRef = useRef<WebSocket | null>(null);

  const joinGame = async (gameCode: string): Promise<string> => {
    console.log("Joining game " + gameCode);
    const response = await fetch(
      `http://localhost:8080/games/${gameCode}/players?playerName=${encodeURIComponent("playerName")}`, // todo add role:
      // joinGame and createGame also set the playerId, see REST.md
      {
        method: "POST",
        credentials: "include",
      },
    );
    //console.log(response);
    console.log("opening websocket");
    const socket = new WebSocket("ws://localhost:8080/games/ws");

    socket.onopen = () => console.log("Connected to WebSocket server");
    socket.onmessage = (event: MessageEvent) => {
      console.log("onmessage:", event.data);
      // setGameState(...)
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

  const createGame = async (): Promise<string> => {
    // todo: it also auto-joins that game
    const res = await fetch("http://localhost:8080/games", {
      method: "POST",
      credentials: "include",
    });
    if (!res.ok) throw new Error("Failed to create game");
    const data = await res.json(); // { role, playerName, code }
    console.log("gamecode. " + data.code);
    return data.code;
  };

  // return UI with Join button calling joinGame

  // https://medium.com/@chaman388/websockets-in-reactjs-a-practical-guide-with-real-world-examples-2efe483ee150

  /*const sendMessage = () => {
    if (ws && ws.readyState === WebSocket.OPEN) {
      ws.send(input);
      setInput("");
    }
  };*/

  const onMove = (ws: WebSocket | null) => {
    // according to claude, the client renders his own prediction but the server validates

    if (!ws) return;
    ws.send(JSON.stringify({ type: "MOVE", test: "test" }));
  };
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
      console.log("onKeyDown " + e.key);
      e.preventDefault();
      const ws = wsRef.current;
      if (!ws || ws.readyState !== WebSocket.OPEN) return;
      ws.send(
        JSON.stringify({
          type: "MOVE",
          test: e.key,
        }),
      );

      // Change the player's x or y coordinates depending on the key press
      setGameState((prevGameState: Game) => {
        if (!prevGameState || !prevGameState.player) return prevGameState;
        let { x, y } = prevGameState.player;
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
          ...prevGameState,
          player: {
            ...prevGameState.player,
            x,
            y,
          },
        };
      });
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [gameCode]);

  /*useEffect(() => {
    const intervalId = setInterval(() => {
      setGameState((prevGameState: Game) => {
        if (prevGameState.mice.length === 0) {
          return prevGameState;
        }

        const moveX = (x: number): number => {
          if (x < 600) {
            return x + 4;
          }
          if (x > 0) {
            return x - 4;
          }
          return x;
        };
        const newMice = prevGameState.mice.map((mouse, index) => {
          if (index !== 0) return mouse;

          return {
            ...mouse,
            x: moveX(mouse.x),
            y: mouse.y,
          };
        });

        return {
          ...prevGameState,
          mice: newMice,
        };
      });
    }, 50);

    return () => clearInterval(intervalId);
  }, []);*/

  return (
    <>
        {gameCode && renderButton("Exit", exitGame)}
        {gameState && gameCode && renderGameField(gameState, renderComponents)}
        {!gameCode &&
          renderButton("Create Game", async () => {
            const gameCode = await joinGame(await createGame());
            setGameCode(gameCode);
          })}
    </>
  );
}
