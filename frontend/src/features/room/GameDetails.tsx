import { useEffect, useState } from 'preact/hooks';
import { useLocation } from 'preact-iso';

interface GameDetailsProps {
  code: string;
}
export function GameDetails({ code }: GameDetailsProps) {
  const location = useLocation();
  const [status, setStatus] = useState('Connecting...');
  const [messages, setMessages] = useState<string[]>([]);

  useEffect(() => {
    console.debug('connect to', code);

    const ws = new WebSocket(
      `ws://localhost:8080/games/${encodeURIComponent(code)}/ws`,
    );

    ws.onopen = () => {
      setStatus(`Connected to room ${code}`);
    };

    ws.onmessage = (event) => {
      const text = String(event.data);
      setMessages((previousMessages) =>
        [text, ...previousMessages].slice(0, 10),
      );
    };

    ws.onerror = () => {
      setStatus('Connection rejected. Redirecting...');
      location.route('/');
    };

    ws.onclose = () => {
      setStatus('Session invalid or expired. Redirecting...');
      location.route('/');
    };

    return () => {
      ws.close();
      console.debug('disconnect', code);
    };
  }, [code, location]);

  return (
    <section>
      <h2>Room {code}</h2>
      <p>{status}</p>
      {messages.length > 0 && (
        <ul>
          {messages.map((message, index) => (
            <li key={`${index}-${message}`}>{message}</li>
          ))}
        </ul>
      )}
    </section>
  );
}
