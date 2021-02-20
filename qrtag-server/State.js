import _ from "lodash";

export default class State {
  teamScores = new Map();
  players = new Map();
  event_history = [];
  baseLocations = [];
  gameOn = false;
  connections = 0;

  getBaseLocation(baseID) {
    return _.find(this.baseLocations, {baseID: baseID})
  }
}
