import { useMemo, type FC } from 'react';
import { Pressable, StyleSheet, Text } from 'react-native';

interface ColorButtonProps {
  text: string;
  isActive: boolean;
  onPress: (color: string) => void;
  color: string;
  disabled?: boolean;
}

export const ToolbarColorButton: FC<ColorButtonProps> = ({
  text,
  isActive,
  onPress,
  color,
  disabled,
}) => {
  const handlePress = () => {
    onPress(color);
  };

  const containerStyle = useMemo(
    () => [
      styles.container,
      { backgroundColor: isActive ? color : 'rgba(0, 26, 114, 0.8)' },
      disabled && styles.disabled,
    ],
    [isActive, color, disabled]
  );

  return (
    <Pressable style={containerStyle} onPress={handlePress} disabled={disabled}>
      <Text style={[styles.text, !isActive && { color }]}>{text}</Text>
    </Pressable>
  );
};

const styles = StyleSheet.create({
  container: {
    justifyContent: 'center',
    alignItems: 'center',
    width: 56,
    height: 56,
  },
  text: {
    color: 'white',
    fontSize: 20,
  },
  disabled: {
    opacity: 0.5,
  },
});
