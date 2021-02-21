import express from "express";
import cors from "cors";
import {Server} from "http";
import WebSocket from "ws";
import State from "./State.js";
import Player from "./Player.js";
import _ from "lodash";

// Create the state object
let state = new State();

// Create all the state stuff
const app = express();
const http = new Server(app);

const port = process.env.PORT | 4003;
const io = new WebSocket.Server({server: http});

let monitor;

app.use(cors());

// Function to create state update object for monitor
const create_update = (id, request) => {
  return {
    players: [...state.players.keys()].map(key => {
      let player = state.players.get(key);
      return {
        identifier: key,
        id: player.playerID,
        username: player.username,
        score: player.score,
        active: player.active,
      }
    }),
    teamScores: state.teamScores,
    baseLocations: state.baseLocations,
    message: "update",
    request: request,
    gameOn: state.gameOn
  }
};

export const genResponse = (data) => {
  return JSON.stringify(data);

}


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
    console.log("DATA", data.data)
    const json = JSON.parse(data.data);

    switch (json['message']) {
      // *-----------------*
      // *      join       *
      // *-----------------*
      case 'join':
        // Get the team
        let team = json["team"];

        // Create a new Player object
        let newPlayer = new Player(json["userID"], json["username"], team, socket);

        console.log([...state.players.keys()]);

        for (let c of state.players) {
          c = c[1];
          console.log(c.playerID, json["userID"]);
          if (c.playerID === json["userID"]) {
            socket.send(genResponse({message: "joined", status: "PlayerID already taken", uuid: json["uuid"]}));
            return;
          }
        }

        // Check that the teams has a score
        if (!state.teamScores[team]) {
          state.teamScores[team] = 0;
        }

        // Check the the base has been initialized
        if (!state.getBaseLocation(team)) {
          state.baseLocations.push({
            baseID: team,
            location: ""
          })
        }

        console.log("Player joining", json);

        // Set the playerID
        identifier = state.players.size + 1;
        // Save the information
        state.players.set(identifier, newPlayer);

        // Tell the client that they successfully joined
        socket.send(genResponse({
          message: "joined",
          status: "accepted",
          uuid: json["uuid"]
        }));

        if (state.connections >= 2 && state.connections === state.players.size) {
          io.send("{'message': 'start game'}")
          // for (let player of state.players) {
          //   player.socket.send();
          // }
          state.gameOn = true;
        }

        break;

      // *-----------------*
      // *      scan       *
      // *-----------------*
      case 'scan':
        // Errors:
        //  - base scan
        //  - not active

        let uuid = json["uuid"];
        let type = json["type"];
        let scanner = state.players.get(identifier);

        if (type === "player") {
          if (!scanner.active) {
            scanner.socket.send(genResponse({
              message: 'not active',
              error: true,
              uuid: uuid
            }));
            return;
          }
          let otherPlayer = _.find(state.players, {playerID: json["id"]});

          if (!otherPlayer) {
            socket.send(JSON.stringify({
              message: "invalid player",
              error: true,
              uuid: uuid
            }));
            return;
          }

          if (scanner.team === otherPlayer.team) {
            if (scanner.hasBase(state) && !otherPlayer.hasBase(state)) {
              scanner.giveBase(state, otherPlayer, uuid);
            } else if (scanner.hasBase(state) && !otherPlayer.hasBase(state)) {
              otherPlayer.giveBase(state, scanner, uuid);
            }
          } else {
            if (otherPlayer.hasBase()) {
              otherPlayer.removeBase(state, uuid);
            }

            state.players.get(otherPlayer.getIndex(state)).deactivate();
          }
        } else if (type === "base") {
          let base = json["id"];

          if (base === scanner.team) {
            if (scanner.hasBase(state)) {
              scanner.removeBase(state, uuid);
              let index = scanner.getIndex(state);
              state.players.get(index).increaseScore(uuid);
              state.teamScores[scanner.team]++;
              for (let player of state.players) {
                player.socket.send(JSON.stringify({
                  message: "point scored",
                  team: scanner.team,
                  username: scanner.username,
                  userID: scanner.userID
                }))
              }
            }
            state.players.get(identifier).activate(uuid);
          } else {
            if (state.getBaseLocation(base) === "home" && !scanner.hasBase(state)) {
              scanner.giveBase(state, base, uuid);
            }
          }
        }

        break;

      // *-----------------*
      // *     online      *
      // *-----------------*
      case 'online':
        socket.send(JSON.stringify({
          message: 'online',
          connected: state.players.size,
          ready: state.connections,
          uuid: json["uuid"]
        }));
        break;

      case 'monitor':
        state.connections--;
        if (!monitor) {
          monitor = socket;
          isMonitor = true;
          socket.send(genResponse({message: "monitor connect", status: "accepted"}));
          console.log("Monitor connected");
        } else {
          socket.send({message: "monitor connect", status: "rejected"});
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
  }

  // *-----------------*
  // *    disconnect   *
  // *-----------------*
  socket.on("close", _socket => {
    if (monitor) {
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
      let data = create_update(identifier, json);
      monitor.send(JSON.stringify(data));
    }
  });
});

app.get("/online", (req, res) => {
  res.send(JSON.stringify({online: state.players.size}));
});

// Start the server
http.listen(port, "0.0.0.0", () => {
  console.log(`"listening on http://localhost:${port}"`);
});
