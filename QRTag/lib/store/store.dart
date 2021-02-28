import 'package:redux/redux.dart';

import '../model/app_state.dart';
import 'reducer.dart';

final Store<AppState> store =
      Store<AppState>(reducer, initialState: AppState());