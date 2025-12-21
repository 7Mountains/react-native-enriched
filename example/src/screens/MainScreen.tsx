import { View, Text, Button, StyleSheet } from 'react-native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { RootStackParamList } from '.././App';

type Props = NativeStackScreenProps<RootStackParamList, 'Main'>;

export function MainScreen({ navigation }: Props) {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Main Screen</Text>
      <Button
        title="Go to Editor"
        onPress={() => navigation.navigate('Editor')}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  title: { fontSize: 24, fontWeight: 'bold' },
});
