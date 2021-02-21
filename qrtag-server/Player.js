export default class Player {
  playerID = "";
  username = "";
  socket;
  score = 0;
  team = 0;
  active = true;

  constructor(playerID, username, team, socket) {
    this.playerID = playerID;
    this.username = username;
    this.socket = socket;
    this.score = 0;
    this.active = true;
    this.team = team;
    this.ready = false;
  }

  hasBase(state) {
    return _.find(state.baseLocations, { location: this.playerID.toString() });
  }

  setBase(state, base, uuid) {
    let index = _.findIndex(state.baseLocations, { location: this.playerID.toString() });

    if (!index) {
      socket.send(JSON.stringify({
        message: 'no such base',
        uuid: uuid
      }));
      return;
    }

    state.baseLocations[index].location = base.toString();

    this.socket.send(JSON.stringify({
      message: "base receive",
      baseID: base,
      uuid: uuid
    }));

    io.clients.forEach(function each(client) {
      client.send(
        JSON.stringify({
          message: "base move",
          uuid: uuid,
          team: this.team,
          username: this.username,
          playerID: this.playerID
        }));
    });
  }

  giveBase(state, otherPlayer, uuid) {
    let opIndex = _.find(state.players, { ...otherPlayer });
    let myBase = this.hasBase(state);

    state[opIndex].setBase(myBase);

    this.socket.send(JSON.stringify({
      message: "base remove",
      uuid: uuid
    }));
  }

  getIndex(state) {
    return _.find(state.players, { ...this });
  }

  removeBase(state, uuid) {
    let index = _.findIndex(state.baseLocations, { location: this.playerID.toString() });

    if (!index) {
      return "no such base";
    }

    state.baseLocations[index].location = "home";

    this.socket.send(JSON.stringify({
      message: "base remove",
      baseID: this.hasBase(state),
      uuid: uuid
    }));

    for (let player of state.players) {
      player.socket.send(JSON.stringify({
        message: "base return",
        team: this.team,
        playerID: this.playerID,
        uuid: uuid
      }));
    }
  }

  deactivate() {
    this.active = false;
    this.socket.send(JSON.stringify({
      message: 'deactivate',
    }));
  }

  activate(uuid) {
    this.active = true;
    this.socket.send(JSON.stringify({
      message: 'activate',
      uuid: uuid
    }));
  }

  increaseScore(uuid) {
    this.score++;
  }
}
