import Player from "./player";
import _ from "lodash";
import BaseLocation from "./baseLocation";
import TeamScore from "./teamScore";

export default class State {
  public teamScores: TeamScore[];
  public players: Map<number, Player>;
  public event_history: Array<any>;
  public baseLocations: BaseLocation[];
  public gameOn: boolean;
  public connections: number;

  constructor() {
    this.teamScores = [];
    this.players = new Map<number, Player>();
    this.event_history = [];
    this.baseLocations = [];
    this.gameOn = false;
    this.connections = 0;
  }

  getBaseLocation(baseID: number): BaseLocation {
    return _.find(this.baseLocations, {base: baseID});
  }

  scorePoint(baseID: number) {
    let index = this.teamScores.findIndex(val => val.team == baseID);
    this.teamScores[index].incrementScore();
  }
}
