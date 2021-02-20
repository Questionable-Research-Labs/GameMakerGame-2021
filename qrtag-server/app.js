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
const io = new WebSocket.Server({server: http});
const port = process.env.PORT | 4003;

let monitor;

app.use(cors());

// Function to create state update object for monitor
const create_update = () => {
  return {
    players: [...state.players.keys()].map(key => {
      let player = state.players[key];
      return {
        ipAddress: key,
        id: player.playerID,
        username: player.username,
        score: player.score,
        active: player.active,
      }
    }),
    teamScores: state.teamScores,
    baseLocations: state.baseLocations,
    message: "update"
  }
};

// Function to split all the players into teams
const split_player_into_teams = () => {
  let teams = [];
  for (let team of state.teamScores.keys()) {
    teams[team] = [...state.players.entries()].filter(val => val["team"] === team);
  }
  return teams;
};

// Serve the static files
app.use("/", express.static("static"));

// *--------------*
// *  on connect  *
// *--------------*
io.on("connection", (socket, req) => {
  let isMonitor = false;
  let ip = req.connection.remoteAddress;
  console.log("New connection from", ip);

  // Tell the client we are ready to connect
  socket.send('{"message": "ready"}');

  // When a message is recieved
  socket.onmessage = (data) => {
    const json = JSON.parse(data.data);

    switch (json['message']) {
      // *-----------------*
      // *      join       *
      // *-----------------*
      case 'join':
        // Get the team
        let team = json["team"];

        // Create a new Player object
        let newPlayer = new Player(json["playerID"], json["username"], team, socket);

        if (ip in state.players.keys()) {
          socket.send('{"message": "joined", "state": "Device already connected"}');
          break;
        }

        for (let c of state.players) {
          if (c.playerID === json["playerID"]) {
            socket.send('{"message": "joined", "state": "PlayerID already taken"}');
            return;
          } else if (c.username === json["username"]) {
            socket.send('{"message": "joined", "state": "Username already taken"}');
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

        // Save the information
        state.players[ip] = newPlayer;

        // Tell the client that they successfully joined
        socket.send('{"message": "joined", "state": "accepted"}');
        break;

      case 'scan':
        let type = json["type"];
        let scanner = state.players[ip];

        if (type === "player") {
          let otherPlayer = _.find(state.players, {playerID: json["id"]});

          if (!otherPlayer) {
            socket.send("{'message': 'bad scan'}");
            return;
          }

          if (scanner.team === otherPlayer.team) {
            if (scanner.hasBase(state) && !otherPlayer.hasBase(state)) {
              scanner.giveBase(state, otherPlayer);
            } else if (scanner.hasBase(state) && !otherPlayer.hasBase(state)) {
              otherPlayer.giveBase(state, scanner);
            }
          } else {
            if (otherPlayer.hasBase()) {
              otherPlayer.removeBase();
            }

            state.players[otherPlayer.getIndex(state)].deactivate();
          }
        } else if (type === "base") {
          let base = json["id"];

          if (base === scanner.team) {
            state.players[ip].activate();
          } else {
            if (state.getBaseLocation(base) === "home" && !scanner.hasBase(state)) {
              scanner.giveBase(state, base);
            }
          }
        }

        break;

      case 'online':
        socket.send(JSON.stringify({message: 'connected', value: state.players}))
        break;

      case 'ready':
        state.players[ip].ready = true;

        let unreadied = _.filter(state.players, {ready: false});
        if (unreadied.length < 1) {
          state.gameOn = true;
          io.emit("{'message': 'game start'}");
        }
        break;

      case 'monitor':
        if (!monitor) {
          monitor = socket;
          isMonitor = true;
          socket.send('{"message": "monitor connect", "status": "accepted"}');
          console.log("Monitor connected");
        } else {
          socket.send('{"message": "monitor connect", "status": "rejected"}');
          socket.close();
        }
        break;
      default:
        break;
    }

    // Notify the monitor about the update
    if (monitor) {
      let data = create_update();
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

    // Get the player that disconnected
    let player = state.players[ip];

    if (player) {
      // Delete all the user information and remove from lookup table
      state.players.delete(ip);
      state.lookup.delete(ip);

      console.log("Player ", ip, ":", player.username, "disconnected");
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
