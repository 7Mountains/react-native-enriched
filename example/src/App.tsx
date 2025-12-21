import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import {
  initialWindowMetrics,
  SafeAreaProvider,
} from 'react-native-safe-area-context';

import { MainScreen } from './screens/MainScreen';
import { EditorScreen } from './screens/EditorScreen/index';
import { PreviewScreen } from './screens/PreviewScreen';
import { enableFreeze, enableScreens } from 'react-native-screens';

export type RootStackParamList = {
  Main: undefined;
  Editor: undefined;
  Preview: { html: string };
};

enableScreens(false);
enableFreeze(false);

const Stack = createNativeStackNavigator<RootStackParamList>();

const contentHtml = Array(1)
  .fill(
    `<p><u>Test</u></p><checklist checked="false">This is a checklist item</checklist>`
  )
  .join('');

const html = '<html>' + contentHtml + '</html>';

console.log(html);

export default function App() {
  return (
    <SafeAreaProvider initialMetrics={initialWindowMetrics}>
      <NavigationContainer>
        <Stack.Navigator>
          <Stack.Screen name="Main" component={MainScreen} />
          <Stack.Screen name="Editor" component={EditorScreen} />
          <Stack.Screen name="Preview" component={PreviewScreen} />
        </Stack.Navigator>
      </NavigationContainer>
    </SafeAreaProvider>
  );
}
