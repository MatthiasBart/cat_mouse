# REST API Spec (WIP)

Routes: 
Host:
* `/games/create` -> create Game with code e.g ABCDEFG
* `/games/{code}/join` -> join Game with code
* `/games/{code}/start` -> start Game

for both a session is created and a link will be returned for the WS URL 
which can be used to open a WS connection.

