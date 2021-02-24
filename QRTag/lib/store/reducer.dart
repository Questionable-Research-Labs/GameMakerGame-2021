import '../model/app_state.dart';
import 'actions.dart';

AppState reducer(AppState prevState, dynamic action) {
  AppState newState = AppState.fromAppState(prevState);
  switch (action.runtimeType) {
    case Location:
      newState.location = action.payload;
      break;
    case TeamID:
      newState.teamID = action.payload;
      break;
    case PlayerID:
      newState.playerID = action.payload;
      break;
    case Username:
      newState.username = action.payload;
      break;
    case PlayerNumbers:
      newState.playerNumbers = action.payload;
      break;
    case WebSocketChannel:
      newState.webSocketChannel = action.payload;
      break;
    case SocketReady:
      newState.socketReady = action.payload;
      break;
    case CurrentlyDeactivated:
      newState.currentlyDeactivated = action.payload;
      break;
    case HomeBaseStolen:
      newState.homeBaseStolen = action.payload;
      break;
    case RediedUp:
      newState.readiedUp = action.payload;
      break;
    default: 
      print("Unmatched reducer AppState Action!!!!!");
  }

  return newState;
}