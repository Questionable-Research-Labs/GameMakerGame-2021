import State from "./state";
import WebSocket from "ws";

export default class Player {
  public score: number;
  public active: boolean;

  constructor(
    public team: number,
    public socket: WebSocket,
    public playerID: number,
    public username: string
  ) {
    this.score = 0;
    this.active = true;
  }

  hasBase(state: State) {
    return state.baseLocations.find(val => val.location == this.playerID.toString());
  }

  setBase(state: State, base: number, uuid: string, io: WebSocket.Server) {
    let index = state.baseLocations.findIndex((element) => element.base = this.team);

    if (!index) {
      this.socket.send(JSON.stringify({
        message: 'no such base',
        errror: true,
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

    io.clients.forEach((client) => {
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
    let index = undefined;
    for (let player of state.players.entries()) {
      if (player[1]["playerID"] == this["playerID"]) {
        index = player[0]
      }
    }
    let opIndex = index.find(state.players, { ...otherPlayer });
    let myBase = this.hasBase(state);

    state[opIndex].setBase(myBase);

    this.socket.send(JSON.stringify({
      message: "base remove",
      uuid: uuid
    }));
  }

  getIndex(state) {
    let index = undefined;
    for (let player of state.players.entries()) {
      if (player[1]["playerID"] == this["playerID"]) {
        index = player[0]
      }
    }
    return index;
  }

  removeBase(state, uuid) {
    let index = state.baseLocations.findIndex((element) => element.base = this.team);

    if (!index) {
      this.socket.send(JSON.stringify({
        message: 'no such base',
        error: true,
        uuid: uuid
      }));
      return;
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

  increaseScore() {
    this.score++;

    this.socket.send(JSON.stringify({
      message: "score change",
      score: this.score
    }))
  }
}
