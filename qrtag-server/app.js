import express from "express";
import { Server } from "http";
import { Server as socketIO } from "socket.io";
import State from "./State.js";
import Player from "./Player.js";

let state = new State();

const app = express();
const http = new Server(app);
const io = new socketIO(http);

const port = process.env.PORT | 4003;

app.use("/", express.static("static"));

io.on("connection", (socket) => {
  console.log("a user connected");

  socket.emit('ready');

  socket.on('join', (data) => {
    let playerData = JSON.parse(data);

    console.log("Player joining", playerData);

    state.players[socket.ipAddress] = new Player(playerData["playerID"], playerData["username"], socket);

    socket.on("disconnect", socket => {
      let player = state.players[socket.ipAddress];
      state.players.delete(socket.ipAddress);

      console.log("Player ", player.playerID, ":", player.username, "disconnected");
    })
  });
});

http.listen(port, () => {
  console.log(`"listening on http://localhost:${port}"`);
});
