import '../model/app_state.dart';
import 'actions.dart';

AppState reducer(AppState prevState, dynamic action) {
  AppState newState = AppState.fromAppState(prevState);
  print("REDUCER");
  print(newState);
  switch (action.runtimeType) {
    case Test:
      newState.test = action.payload;
      break;
    case Location:
      newState.location = action.payload;
      break;
    case TeamID:
      newState.teamID = action.payload;
      break;
    case PlayerID:
      newState.playerID = action.payload;
      break;
    default: 
      print("Unmatched reducer AppState Action!!!!!");
  }

  return newState;
}