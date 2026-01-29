import { View, StyleSheet } from 'react-native';
import { Button } from './components/Button';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import type { RootStackParamList } from './App';

export default function MainScreen() {
  const navigation =
    useNavigation<NativeStackNavigationProp<RootStackParamList>>();

  return (
    <View style={styles.container}>
      <Button
        title="Open Editor"
        onPress={() => navigation.navigate('Editor')}
      />
      <Button
        title="Open reanimated Editor"
        onPress={() => navigation.navigate('ReanimatedEditor')}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
});
