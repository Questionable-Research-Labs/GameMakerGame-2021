import Player from "./player";

export default class State {
  public teamScores: Map<number, number>;
  public players: Map<number, Player>;
  public event_history: Array<any>;
  public baseLocations: Map<number, string>;
  public gameOn: boolean;
  public connections: number;

  constructor() {
    this.teamScores = new Map<number, number>();
    this.players = new Map<number, Player>();
    this.event_history = [];
    this.baseLocations = new Map<number, string>();
    this.gameOn = false;
    this.connections = 0;
  }

  getBaseLocation(baseID: number): string {
    return this.baseLocations.get(baseID);
  }
}
