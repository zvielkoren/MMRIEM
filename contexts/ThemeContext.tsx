import React, { createContext, useContext, useState, useEffect } from "react";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { Platform, useColorScheme } from "react-native";

interface ThemeContextType {
  isDark: boolean;
  toggleTheme: () => void;
}

const ThemeContext = createContext<ThemeContextType>({
  isDark: false,
  toggleTheme: () => {},
});

export const ThemeProvider: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => {
  const [isDark, setIsDark] = useState(false);
  const systemColorScheme = useColorScheme();

  useEffect(() => {
    loadThemePreference();
  }, []);

  const loadThemePreference = async () => {
    try {
      const savedTheme = await AsyncStorage.getItem("theme");
      if (savedTheme) {
        setIsDark(savedTheme === "dark");
      } else {
        // Set system default based on platform
        if (Platform.OS === "web") {
          const colorScheme = window?.matchMedia?.(
            "(prefers-color-scheme: dark)"
          )?.matches;
          setIsDark(colorScheme ?? false);
        } else {
          setIsDark(systemColorScheme === "dark");
        }
      }
    } catch (error) {
      console.error("Error loading theme preference:", error);
      // Fallback to light theme
      setIsDark(false);
    }
  };

  const toggleTheme = async () => {
    try {
      const newTheme = !isDark;
      await AsyncStorage.setItem("theme", newTheme ? "dark" : "light");
      setIsDark(newTheme);
    } catch (error) {
      console.error("Error saving theme preference:", error);
    }
  };

  return (
    <ThemeContext.Provider value={{ isDark, toggleTheme }}>
      {children}
    </ThemeContext.Provider>
  );
};

export const useTheme = () => useContext(ThemeContext);
