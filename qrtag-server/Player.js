export default class Player {
  playerID = "";
  username = "";
  socket;

  constructor(playerID, username, socket) {
    this.playerID = playerID;
    this.username = username;
    this.socket = socket;
  }
}
