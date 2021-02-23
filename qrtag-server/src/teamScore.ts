export default class TeamScore {
  public score: number;

  constructor(public team: number) {
    this.score = 0;
  }

  incrementScore() {
    this.score++;
  }
}
