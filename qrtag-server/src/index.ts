import express from "express";
import cors from "cors";
import { Server } from "http";
import WebSocket from "ws";
import State from "./state";
import Player from "./player";
import _ from "lodash";
import BaseLocation from "./baseLocation";
import TeamScore from "./teamScore";

// Create the state object
let state = new State();

// Create all the state stuff
const app = express();
const http = new Server(app);

const port = process.env.PORT == undefined ? 4003 : process.env.PORT;
const io = new WebSocket.Server({ server: http });

let monitor;

app.use(cors());

// Function to create state update object for monitor
const create_update = (id, request) => {
  return {
    players: [...state.players.keys()].map((key) => {
      let player = state.players.get(key);
      return {
        identifier: key,
        id: player.playerID,
        username: player.username,
        score: player.score,
        active: player.active,
      };
    }),
    teamScores: state.teamScores,
    baseLocations: state.baseLocations,
    message: "update",
    request: request,
    gameOn: state.gameOn,
  };
};

export const genResponse = (data) => {
  return JSON.stringify(data);
};

// Serve the static files
app.use("/", express.static("static"));

// *--------------*
// *  on connect  *
// *--------------*
io.on("connection", (socket, req) => {
  let isMonitor = false;
  let identifier;

  state.connections++;

  console.log("New connection");

  // Tell the client we are ready to connect
  socket.send('{"message": "ready"}');

  // When a message is recieved
  socket.onmessage = (data) => {
    console.log("DATA", data.data);
    const json = JSON.parse(data.data.toString());

    switch (json["message"]) {
      // *-----------------*
      // *      join       *
      // *-----------------*
      case "join":
        // Get the team
        let team = json["team"];

        // Create a new Player object
        let newPlayer = new Player(
          team,
          socket,
          json["userID"],
          json["username"]
        );

        // Check to see that the player ID is not already in use
        for (let c of state.players) {
          let c2 = c[1];
          if (c2.playerID === json["userID"]) {
            socket.send(
              genResponse({
                message: "joined",
                status: "PlayerID already taken",
                uuid: json["uuid"],
              })
            );
            return;
          }
        }

        // Check that the teams has a score
        if (!state.teamScores.find((val) => team == val.team)) {
          state.teamScores.push(new TeamScore(team));
        }

        // Check the the base has been initialized
        if (!state.getBaseLocation(team)) {
          state.baseLocations.push(new BaseLocation(team));
        }

        console.log("Player joining", json);

        // Set the playerID
        identifier = state.players.size + 1;
        // Save the information
        state.players.set(identifier, newPlayer);

        // Tell the client that they successfully joined
        socket.send(
          genResponse({
            message: "joined",
            status: "accepted",
            uuid: json["uuid"],
          })
        );

        if (state.gameOn) {
          socket.send(genResponse({ message: "start game" }));
        }

        if (
          state.connections >= 2 &&
          state.connections === state.players.size
        ) {
          // for (let player of state.players) {
          //   player.socket.send();
          // }
          io.clients.forEach((client) => {
            client.send(JSON.stringify({ message: "start game" }));
          });

          state.gameOn = true;
        }

        break;

      // *-----------------*
      // *      scan       *
      // *-----------------*
      case "scan":
        // Errors:
        //  - base scan
        //  - not active

        let uuid = json["uuid"];
        let type = json["type"];
        let scanner = state.players.get(identifier);

        if (type === "player") {
          if (!scanner.active) {
            scanner.socket.send(
              genResponse({
                message: "not active",
                error: true,
                uuid: uuid,
              })
            );
            return;
          }
          let otherPlayer = undefined;
          for (let player of state.players) {
            if (player[1]["playerID"] == json["id"]) {
              otherPlayer = player[1];
            }
          }
          console.log(state.players);
          console.log(otherPlayer);
          if (otherPlayer === undefined) {
            socket.send(
              JSON.stringify({
                message: "invalid player",
                error: true,
                uuid: uuid,
              })
            );
            return;
          }

          if (scanner.team === otherPlayer.team) {
            if (scanner.hasBase(state) && !otherPlayer.hasBase(state)) {
              scanner.giveBase(state, otherPlayer, uuid);
            } else if (scanner.hasBase(state) && !otherPlayer.hasBase(state)) {
              otherPlayer.giveBase(state, scanner, uuid);
            }
          } else {
            if (otherPlayer.hasBase(state)) {
              otherPlayer.removeBase(state, uuid);
            }
            socket.send(
              JSON.stringify({
                message: "sucessfull tag",
                username: otherPlayer.username,
                team: otherPlayer.team,
                uuid: uuid,
              })
            );
            state.players.get(otherPlayer.getIndex(state)).deactivate();
          }
        } else if (type === "base") {
          let base = json["id"];

          if (base === scanner.team) {
            if (scanner.hasBase(state)) {
              scanner.removeBase(state, uuid);
              let index = scanner.getIndex(state);
              state.players.get(index).increaseScore();
              state.scorePoint(scanner.team);
              io.clients.forEach((client) => {
                client.send(
                  JSON.stringify({
                    message: "point scored",
                    team: scanner.team,
                    username: scanner.username,
                    userID: scanner.playerID,
                  })
                );
              });

              let teams = state.teamScores.sort((a, b) =>
                a.score > b.score ? -1 : a.score === b.score ? 0 : 1
              );

              if (teams[0].score === 3) {
                io.clients.forEach((client) => {
                  client.send(
                    client.send(
                      JSON.stringify({
                        message: "match over",
                        teams: teams,
                        players: [...state.players.values()]
                          .sort((a, b) =>
                            a.score > b.score ? -1 : a.score === b.score ? 0 : 1
                          )
                          .map((e) => {
                            return {
                              username: e.username,
                              playerID: e.playerID,
                              team: e.team,
                            };
                          }),
                      })
                    )
                  );
                });
              }
            }

            state.players.get(identifier).activate(uuid);
          } else {
            if (
              state.getBaseLocation(base).location === "home" &&
              !scanner.hasBase(state)
            ) {
              scanner.giveBase(state, base, uuid);
            }
          }
        }

        break;

      // *-----------------*
      // *     online      *
      // *-----------------*
      case "online":
        socket.send(
          JSON.stringify({
            message: "online",
            connected: state.players.size,
            ready: state.connections,
            uuid: json["uuid"],
          })
        );
        break;

      // *-----------------*
      // *     monitor     *
      // *-----------------*
      case "monitor":
        state.connections--;
        if (!monitor) {
          monitor = socket;
          isMonitor = true;
          socket.send(
            genResponse({ message: "monitor connect", status: "accepted" })
          );
          console.log("Monitor connected");
        } else {
          socket.send({ message: "monitor connect", status: "rejected" });
          socket.close();
        }
        break;
      default:
        break;
    }

    // Notify the monitor about the update
    if (monitor) {
      let data = create_update(identifier, json);
      monitor.send(JSON.stringify(data));
    }
  };

  // *-----------------*
  // *    disconnect   *
  // *-----------------*
  socket.on("close", (_socket) => {
    if (isMonitor) {
      console.log("Monitor disconnected");
      monitor = null;
      return;
    }

    state.connections--;

    // Get the player that disconnected
    let player = state.players.get(identifier);

    if (player) {
      // Delete all the user information and remove from lookup table
      state.players.delete(identifier);

      console.log("Player ", identifier, ":", player.username, "disconnected");
    }

    // Notify the monitor about the update
    if (monitor) {
      let data = create_update(identifier, {
        message: "disconnect",
        id: player.username,
      });
      monitor.send(JSON.stringify(data));
    }
  });
});

app.get("/online", (req, res) => {
  res.send(JSON.stringify({ online: state.players.size }));
});

// Start the server
http.listen(port, () => {
  console.log(`"listening on http://localhost:${port}"`);
});
