export default class Player {
  playerID = "";
  username = "";
  socket;
  score = 0;

  constructor(playerID, username, socket) {
    this.playerID = playerID;
    this.username = username;
    this.socket = socket;
    this.score = 0;
  }
}
