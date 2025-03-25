import { View, Text, StyleSheet } from 'react-native';
import { useFonts, Heebo_400Regular, Heebo_700Bold } from '@expo-google-fonts/heebo';
import { useEffect } from 'react';
import { SplashScreen } from 'expo-router';

SplashScreen.preventAutoHideAsync();

export default function CalendarScreen() {
  const [fontsLoaded, fontError] = useFonts({
    'Heebo-Regular': Heebo_400Regular,
    'Heebo-Bold': Heebo_700Bold,
  });

  useEffect(() => {
    if (fontsLoaded || fontError) {
      SplashScreen.hideAsync();
    }
  }, [fontsLoaded, fontError]);

  if (!fontsLoaded && !fontError) {
    return null;
  }

  return (
    <View style={styles.container}>
      <Text style={styles.title}>יומן</Text>
      <View style={styles.calendarContainer}>
        {/* Calendar implementation will go here */}
      </View>
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
  calendarContainer: {
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