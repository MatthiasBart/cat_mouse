import {
  LocationProvider,
  ErrorBoundary,
  Router,
  Route,
  useLocation,
} from 'preact-iso';

import { useEffect } from 'preact/hooks';

import { GameForm } from './features/enter-game/GameForm.js';
import { GameDetails } from './features/room/GameDetails.js';

import './app.css';

export function App() {
  return (
    <LocationProvider>
      <ErrorBoundary>
        <header>
          <h1>Cat & Mouse</h1>
        </header>
        <main id="center">
          <Router>
            <Route path="/" component={GameForm} />
            <Route path="/*" component={Games} />
            <Route default component={Redirect} />
          </Router>
        </main>
      </ErrorBoundary>
      <footer id="next-steps">
        <div>PPL - Group X</div>
      </footer>
    </LocationProvider>
  );
}

function Games() {
  return (
    <ErrorBoundary>
      <Router>
        <Route path="/:code" component={GameDetails} />
        <Route default component={Redirect} />
      </Router>
    </ErrorBoundary>
  );
}

function Redirect() {
  const location = useLocation();

  useEffect(() => {
    location.route('/');
  }, [location]);

  return <div>Redirecting...</div>;
}
