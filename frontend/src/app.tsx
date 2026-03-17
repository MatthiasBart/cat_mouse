import { useEffect, useState } from "preact/hooks";

import "./app.css";
import type { Game, Cat, Mouse } from "./types";
import type { JSX } from "preact/jsx-runtime";
//const WebSocket = require("ws");
//const wss = new WebSocket.Server({ port: 8080 });

function renderComponents(gameState: Game, onMove: () => void): JSX.Element {
  return (
    <div>
      {gameState.mice.map((mouse: Mouse, index: number) => {
        return (
          <div
            key={index}
            style={{
              position: "relative",
              left: `${mouse.x}px`,
              top: `${mouse.y}px`,
            }}
          >
            <p style={{ fontSize: 50 }}>🙀</p>
          </div>
        );
      })}{" "}
    </div>
  );
}

/*async function getInitialState() {

  
}*/

function renderGameField(
  gameState: Game,
  renderFunction: (gameState: Game, onMove: () => void) => JSX.Element,
): JSX.Element {
  return (
    <div
      style={{
        flex: 1,
        backgroundColor: "yellow",
        minWidth: 400,
      }}
    >
      {renderFunction(gameState, () => {})}
    </div>
  );
}

export function App() {
  //const [count, setCount] = useState(0);

  //const initialState: Game = { game: null };
  const [gameState, setGameState] = useState<Game>({
    mice: [
      { x: 10, y: 10 },
      { x: 55, y: 200 },
    ],
    subways: [],
    cats: [],
  });
  //const getNewStuff(stuff => renderGameField(stuff))
  //const [messages, setMessages] = useState([]);

  const [ws, setWs] = useState(null);

  /*useEffect(() => {
    const websocket = new WebSocket("ws://localhost:8080");
    setWs(websocket);

    websocket.onopen = () => console.log("Connected to WebSocket server");
    websocket.onmessage = (event: any) => {
      // setGameState(...)
      //setMessages((prevMessages: any) => [...prevMessages, event.data]);
    };
    websocket.onclose = () => console.log("Disconnected from WebSocket server");

    // Cleanup on unmount
    return () => websocket.close();
  }, []);*/

  /*const sendMessage = () => {
    if (ws && ws.readyState === WebSocket.OPEN) {
      ws.send(input);
      setInput("");
    }
  };*/

  const onMove = () => {
    console.log("onMove");
  };

  useEffect(() => {
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
  }, []);

  return (
    <>
      <section id="center">
        <h1>Cat & Mouse</h1>
        {gameState && renderGameField(gameState, renderComponents)}
      </section>

      <section id="next-steps">
        <div id="footer">
          <p>PPL - Group X</p>
        </div>
      </section>
    </>
  );
}
