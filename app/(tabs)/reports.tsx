import { View, Text, StyleSheet, ScrollView } from 'react-native';

export default function ReportsScreen() {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>דוחות</Text>
      <ScrollView style={styles.reportsContainer}>
        {/* Reports implementation will go here */}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
    padding: 16,
  },
  title: {
    fontFamily: 'Heebo-Bold',
    fontSize: 24,
    textAlign: 'right',
    marginBottom: 16,
    color: '#333333',
  },
  reportsContainer: {
    flex: 1,
    backgroundColor: '#ffffff',
    borderRadius: 12,
    padding: 16,
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
});