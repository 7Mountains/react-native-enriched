import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import MainScreen from './MainScreen';
import EditorScreen from './EditorScreen';
import { KeyboardProvider } from 'react-native-keyboard-controller';
import {
  SafeAreaProvider,
  initialWindowMetrics,
} from 'react-native-safe-area-context';
import ReanimatedEditorScreen from './ReanimatedEditorScreen';

const Stack = createNativeStackNavigator();

export default function App() {
  return (
    <KeyboardProvider preload>
      <SafeAreaProvider initialMetrics={initialWindowMetrics}>
        <NavigationContainer>
          <Stack.Navigator>
            <Stack.Screen name="Main" component={MainScreen} />
            <Stack.Screen name="Editor" component={EditorScreen} />
            <Stack.Screen
              name="ReanimatedEditor"
              component={ReanimatedEditorScreen}
            />
          </Stack.Navigator>
        </NavigationContainer>
      </SafeAreaProvider>
    </KeyboardProvider>
  );
}
