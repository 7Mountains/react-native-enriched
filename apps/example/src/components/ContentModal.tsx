import { useCallback, useState, type FC } from 'react';
import { Modal, StyleSheet, TextInput, View } from 'react-native';
import { Icon } from './Icon';
import { Pressable } from 'react-native';
import { Button } from './Button';

type Props = {
  onSubmit: (
    text: string,
    type: string,
    src: string,
    attributes: string
  ) => void;
  onClose: () => void;
  visible: boolean;
};

const TYPE = 'image';

export const ContentModal: FC<Props> = ({ visible, onClose, onSubmit }) => {
  const [text, setText] = useState('');
  const [src, setSrc] = useState('');

  const handleSubmit = useCallback(() => {
    const someAdditionalAttributes = {
      test: 'value',
      test2: 'value2',
    };
    onSubmit(text, TYPE, src, JSON.stringify(someAdditionalAttributes));
  }, [onSubmit, src, text]);

  return (
    <Modal visible={visible} animationType="slide" transparent>
      <View style={styles.container}>
        <View style={styles.modal}>
          <View style={styles.header}>
            <Pressable onPress={onClose} style={styles.closeButton}>
              <Icon name="close" color="rgb(0, 26, 114)" size={20} />
            </Pressable>
          </View>
          <View style={styles.content}>
            <TextInput
              placeholder="Text"
              style={styles.input}
              onChangeText={setText}
            />
            <TextInput
              placeholder="Url"
              style={styles.input}
              onChangeText={setSrc}
            />
            <Button
              title="Save"
              onPress={handleSubmit}
              disabled={src.length === 0 || text.length === 0}
              style={styles.saveButton}
            />
          </View>
        </View>
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: 'rgb(0, 0, 0, 0.5)',
  },
  modal: {
    width: 300,
    height: 240,
    backgroundColor: 'white',
    borderRadius: 8,
    padding: 16,
  },
  header: {
    width: '100%',
    alignItems: 'flex-end',
  },
  closeButton: {
    justifyContent: 'center',
    alignItems: 'center',
    width: 24,
    height: 24,
  },
  content: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  input: {
    fontSize: 15,
    borderBottomWidth: 1,
    borderBottomColor: 'grey',
    width: '100%',
    marginVertical: 10,
  },
  saveButton: {
    width: '75%',
  },
});
