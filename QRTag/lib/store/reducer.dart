import '../model/app_state.dart';
import 'actions.dart';

AppState reducer(AppState prevState, dynamic action) {
  AppState newState = AppState.fromAppState(prevState);

  switch (action) {
    case Test:
      newState.test = action.payload;
      break;
    case Location:
      newState.location = action.payload;
      break;
    default:
  }

  return newState;
}