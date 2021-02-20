export default class Player {
  playerID = "";
  username = "";
  socket;
  score = 0;
  team = 0;
  active = true;
  ready = false;

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
    return _.find(state.baseLocations, {location: this.playerID.toString()});
  }

  setBase(state, base) {
    let index = _.findIndex(state.baseLocations, {location: this.playerID.toString()});

    if (!index) {
      return "no such base";
    }

    state.baseLocations[index].location = base.toString();

    this.socket.send(JSON.stringify({
      message: "base receive",
      baseID: base
    }));

    for (let player of state.players) {
      player.socket.send(JSON.stringify({
        message: "base set",
        team: this.team,
        playerID: this.playerID
      }));
    }
  }

  giveBase(state, otherPlayer) {
    let opIndex = _.find(state.players, {...otherPlayer});
    let myBase = this.hasBase(state);

    state[opIndex].setBase(myBase);

    this.socket.send(JSON.stringify({
      message: "base remove",
    }));

    for (let player of state.players) {
      player.socket.send(JSON.stringify({
        message: "base pass",
        team: this.team,
        playerID: this.playerID
      }));
    }
  }

  getIndex(state) {
    return _.find(state.players, {...this});
  }

  removeBase(state) {
    let index = _.findIndex(state.baseLocations, {location: this.playerID.toString()});

    if (!index) {
      return "no such base";
    }

    state.baseLocations[index].location = "home";

    this.socket.send(JSON.stringify({
      message: "base remove",
      baseID: this.hasBase(state)
    }));

    for (let player of state.players) {
      player.socket.send(JSON.stringify({
        message: "base return",
        team: this.team,
        playerID: this.playerID
      }));
    }
  }

  deactivate() {
    this.active = false;
    this.socket.send("{'message': 'deactivate'}");
  }

  activate() {
    this.active = true;
    this.socket.send("{'message': 'activate'}");
  }
}
