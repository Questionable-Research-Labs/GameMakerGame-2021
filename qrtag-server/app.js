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
        id: player.userID,
        username: player.username,
        score: player.score,
        active: player.active,
      }
    }),
    teamScores: state.team_scores,
    baseLocations: state.base_locations,
    message: "update"
  }
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
        let newPlayer = new Player(json["playerID"], json["username"], socket);

        // Add the player id to team lookup table
        state.lookup[newPlayer.playerID] = team;

        // Check that the teams has a score
        if (!state.team_scores[team]) {
          state.team_scores[team] = 0;
        }

        console.log("Player joining", json);

        // Save the information
        state.players[ip] = newPlayer;

        // Tell the client that they successfully joined
        socket.send('{"message": "joined", "state": "accepted"}');
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

      // Delete all the user information and remove from lookup table
      state.players.delete(ip);
      state.lookup.delete(ip);

      console.log("Player ", ip, ":", player.username, "disconnected");
    } catch (e) {
      console.log("Error on disconect: ",e)
    }
    
  });
});

// Start the server
http.listen(port, "0.0.0.0", () => {
  console.log(`"listening on http://localhost:${port}"`);
});
