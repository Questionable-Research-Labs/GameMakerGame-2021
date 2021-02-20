import express from "express";
import {Server} from "http";
import {Server as socketIO} from "socket.io";
import State from "./State.js";
import Player from "./Player.js";

// Create the state object
let state = new State();

// Create all the state stuff
const app = express();
const http = new Server(app);
const io = new socketIO(http, {
  cors: {
    origin: '*',
  }
});
const port = process.env.PORT | 4003;

// Serve the static files
app.use("/", express.static("static"));

// *--------------*
// *  on connect  *
// *--------------*
io.on("connection", (socket) => {
  console.log("New connection from client");
  socket.emit('ready');

  // *-----------------*
  // *      join       *
  // *-----------------*

  socket.on('join', (data) => {
    // Get the users id
    let ip = socket.handshake.address;

    console.log(ip);

    // Deserialize the request
    let playerData = JSON.parse(data);

    // Get the team
    let team = playerData["team"];

    // Create a new Player object
    let newPlayer = new Player(playerData["playerID"], playerData["username"], socket);

    // Add the player id to team lookup table
    state.lookup[newPlayer.playerID] = team;

    // Check that the teams has a score
    if (!state.team_scores[team]) {
      state.team_scores[team] = 0;
    }

    console.log("Player joining", playerData);

    // Save the information
    state.players[ip] = newPlayer;

    // Tell the client that they successfuly joined
    socket.emit('joined');
  });

  // *-----------------*
  // *    disconnect   *
  // *-----------------*
  socket.on("disconnect", socket => {
    try {
      // Get the websockets IP Address
      let ip = socket.handshake?.address;

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
