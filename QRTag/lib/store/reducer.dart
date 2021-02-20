import '../model/app_state.dart';
import 'actions.dart';

AppState reducer(AppState prevState, dynamic action) {
  AppState newState = AppState.fromAppState(prevState);

  if (action is Test) {
    newState.test = action.payload;
  }

  return newState;
}