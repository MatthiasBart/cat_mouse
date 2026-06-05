### Questions

> Which number and forms of subways, number of exits, number and strategies of mice and cats (as well as mice and cats controlled by computer algorithms), playing time, mechanisms of how players control mice and cats, etc., provide the most exciting gaming experience? Which variations did you try out?

**Answer:**
We found that dynamically scaling the map based on player count provides the best experience. 
The total number of subway exits is set to `cats.count * 3`. These exits are then randomly grouped into subways containing a random number of exits (between 1 and half the remaining exits). This creates an unpredictable fun map.

We only enforce that a game must be started:
- with at least 2 mice
- with at least 1 cat
to keep it flexibel and let players try out different configurations.

We added "ghost cats", showing the last positions of cats shortly after mice enter a subway to guide the voting process.

For AI strategies:
- **Cat AI:** 
Initially, cats would clump together to chase the single closest mouse. 
We updated their strategy so they ignore mice that are already "covered" by another cat. 

If no mice are visible, they patrol random subway exits. Before they always hovered at the last exit a mouse was seen, which resulted in the 
all the cats doing the same.

- **Mouse AI:** 
Mouses "escape" from nearby cats. Instead of blindly running in the exact opposite direction of a cat (which resulted in them getting stuck on the field boundaries), mice now choose the "best" subway exit and try to reach that. They prioritize exits that are closer to them than to the cat and the winning subway (of a vote).

> Which program organization did you select for which reasons? Did you try out alternatives?

**Answer:**
We selected a strict Client-Server architecture.
The central server holds the "source of truth" and strictly enforces visibility rules (i.e., hiding cats for mice in subways, or hiding subway connections for cats) before broadcasting state updates. 
We deliberately separated the AI into completely distinct standalone processes rather than embedding them directly in the server loop. This guarantees that the AI connects over the same WebSockets and receives the exact same filtered information as human players, strictly adhering to the assignment that algorithms must not get more information. 

Before that we did try to seperate the server into communication and logic. However, during the process it seemed more natural to keep the communication close to game logic, and since placing the ai in standalone
processes made a lot of sense and had other benefits we decided on that.

> Which programming languages and paradigms did you select for which parts of the task and for which reasons?

**Answer:**
- **Server, OO:** Written in **Swift** using the Vapor framework. We chose the OO paradigm here because modeling a complex, stateful game world with interacting entities (`Game`, `Subway`, `Voting`, `Player`) naturally fits into encapsulated classes and structs.
- **Frontend, Functional:** Written in **TypeScript** using **Preact**. The user interface is built entirely with functional components and React hooks. State is treated as immutable, and the UI is rendered as a pure function of the current game state received from the server.
- **AI Bots, Procedural:** Written in **Go**. The bots are implemented using a purely procedural style. The code consists of top-level procedures that operate via side-effects on shared global variables (`State`, `MouseState`). This makes the bot's decision loop extremely fast, lightweight, and straightforward to read.