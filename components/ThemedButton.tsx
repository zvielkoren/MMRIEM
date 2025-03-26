import {
  TouchableOpacity,
  TouchableOpacityProps,
  StyleSheet,
} from "react-native";
import { useTheme } from "@/contexts/ThemeContext";
import { getThemedStyles } from "@/utils/theme";
import { ThemedText } from "./ThemedText";

interface ThemedButtonProps extends TouchableOpacityProps {
  variant?: "primary" | "secondary" | "danger";
  title: string;
}

export function ThemedButton({
  variant = "primary",
  title,
  style,
  ...props
}: ThemedButtonProps) {
  const { isDark } = useTheme();
  const themed = getThemedStyles(isDark);

  const getVariantStyle = () => {
    switch (variant) {
      case "primary":
        return {
          backgroundColor: themed.theme.primary,
          borderColor: themed.theme.primary,
        };
      case "secondary":
        return {
          backgroundColor: isDark ? "#374151" : "#f3f4f6",
          borderColor: themed.theme.border,
        };
      case "danger":
        return {
          backgroundColor: themed.theme.error,
          borderColor: themed.theme.error,
        };
    }
  };

  const getTextColor = () => {
    if (variant === "secondary") {
      return themed.theme.text;
    }
    return "#ffffff";
  };

  return (
    <TouchableOpacity
      style={[styles.button, getVariantStyle(), style]}
      activeOpacity={0.7}
      {...props}
    >
      <ThemedText style={[styles.text, { color: getTextColor() }]}>
        {title}
      </ThemedText>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  button: {
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderRadius: 8,
    alignItems: "center",
    justifyContent: "center",
    borderWidth: 1,
  },
  text: {
    fontSize: 16,
    fontFamily: "Heebo-Bold",
  },
});
