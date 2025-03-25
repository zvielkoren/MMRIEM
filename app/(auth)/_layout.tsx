import { Stack } from 'expo-router';
import { useAuth } from '@/hooks/useAuth';
import { Redirect } from 'expo-router';

export default function AuthLayout() {
  const { user, loading } = useAuth();

  if (loading) return null;
  
  if (user) {
    return <Redirect href="/(tabs)" />;
  }

  return (
    <Stack screenOptions={{
      headerShown: false,
      contentStyle: { backgroundColor: '#ffffff' }
    }}>
      <Stack.Screen name="login" />
      <Stack.Screen name="register" />
    </Stack>
  );
}