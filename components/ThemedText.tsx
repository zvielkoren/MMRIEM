import { Text, TextProps } from "react-native";
import { useTheme } from "@/contexts/ThemeContext";
import { getThemedStyles } from "@/utils/theme";

export function ThemedText(props: TextProps) {
  const { isDark } = useTheme();
  const themed = getThemedStyles(isDark);

  return <Text {...props} style={[themed.text, props.style]} />;
}
