import { StyleSheet, Image, Platform } from "react-native";

import { Collapsible } from "@/components/Collapsible";
import { ExternalLink } from "@/components/ExternalLink";
import ParallaxScrollView from "@/components/ParallaxScrollView";
import { ThemedText } from "@/components/ThemedText";
import { ThemedView } from "@/components/ThemedView";
import { IconSymbol } from "@/components/ui/IconSymbol";
import { AuthGuard } from "@/components/AuthGuard";

export default function TabTwoScreen() {
  return (
    <AuthGuard>
      <ParallaxScrollView
        headerBackgroundColor={{ light: "#D0D0D0", dark: "#353636" }}
        headerImage={
          <IconSymbol
            size={310}
            color="#808080"
            name="chevron.left.forwardslash.chevron.right"
            style={styles.headerImage}
          />
        }
      >
        <ThemedView style={styles.titleContainer}>
          <ThemedText type="title">Test</ThemedText>
        </ThemedView>
        <Collapsible title="What is this?">
          <ThemedText>
            This is a test screen to show how to use the{" "}
            <ExternalLink href="https://docs.expo.dev/versions/latest/sdk/webview/">
              WebView
            </ExternalLink>
            .
          </ThemedText>
        </Collapsible>
      </ParallaxScrollView>
    </AuthGuard>
  );
}

const styles = StyleSheet.create({
  headerImage: {
    color: "#808080",
    bottom: -90,
    left: -35,
    position: "absolute",
  },
  titleContainer: {
    flexDirection: "row",
    gap: 8,
  },
});
