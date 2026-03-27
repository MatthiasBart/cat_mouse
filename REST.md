# REST API Spec (WIP)


* POST `/games/` -> create Game with code e.g ABCDEFG, creates a session
* POST `/games/{code}/players` -> join Game with code, creates a session

after obtaining a valid session, [establish a WS connection](WS.md)

