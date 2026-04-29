import { StyleSheet, Text, View } from 'react-native';

export function StatCard({
  title,
  value,
}: {
  title: string;
  value: string;
}) {
  return (
    <View style={styles.card}>
      <Text style={styles.title}>{title}</Text>
      <Text style={styles.value}>{value}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#2a292d',
    borderRadius: 12,
    padding: 16,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 10,
  },
  title: { color: '#bbb' },
  value: { color: '#fff', fontSize: 16, fontWeight: '600' },
});
