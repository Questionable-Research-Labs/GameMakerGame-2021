const app = require('express')();
const http = require('http').Server(app);
const io = require('socket.io')(http);

class State {
  team_scores = new Map();
  players = new Map();
  player_scores = new Map();
  event_history = [];
  base_locations = new Map();
}

let state = new State

app.get('/', (req, res) => {
  res.sendFile(__dirname + '/index.html');
});

io.on('connection', (socket) => {
  console.log('a user connected');
});

io.on('join', (data) => {
  let player_data = JSON.parse(data);

  stat
});

http.listen(3000, () => {
  console.log('listening on *:3000');
});