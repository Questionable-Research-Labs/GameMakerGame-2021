import express from "express";
import { Server } from "http";
import { Server as socketIO } from "socket.io";
import State from "./state.js";

let state = new State();

const app = express();
const http = new Server(app);
const io = new socketIO(http);

const port = process.env.PORT | 4003;

app.use("/", express.static("static"));

io.on("connection", (socket) => {
  console.log("a user connected");
});

io.on("join", (data) => {
  let player_data = JSON.parse(data);

  console.log("Player joined: data " + player_data);
});

http.listen(port, () => {
  console.log(`"listening on http://localhost:${port}"`);
});
