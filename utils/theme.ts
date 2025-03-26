interface ThemeColors {
  background: string;
  surface: string;
  text: string;
  textSecondary: string;
  primary: string;
  border: string;
  error: string;
}

export const lightTheme: ThemeColors = {
  background: "#f5f5f5",
  surface: "#ffffff",
  text: "#333333",
  textSecondary: "#666666",
  primary: "#0066cc",
  border: "#e5e5e5",
  error: "#dc2626",
};

export const darkTheme: ThemeColors = {
  background: "#111827",
  surface: "#1f2937",
  text: "#ffffff",
  textSecondary: "#9ca3af",
  primary: "#3b82f6",
  border: "#374151",
  error: "#ef4444",
};

export const getThemedStyles = (isDark: boolean) => {
  const theme = isDark ? darkTheme : lightTheme;
  return {
    theme,
    contentBackground: {
      backgroundColor: theme.background,
    },
    surfaceBackground: {
      backgroundColor: theme.surface,
    },
    text: {
      color: theme.text,
    },
    textSecondary: {
      color: theme.textSecondary,
    },
    border: {
      borderColor: theme.border,
    },
  };
};
