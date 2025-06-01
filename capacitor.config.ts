import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.finans.app',
  appName: 'Finans',
  webDir: 'out',
  server: {
    androidScheme: 'https'
  },
  plugins: {
    SplashScreen: {
      launchShowDuration: 2000,
      backgroundColor: "#111827",
      showSpinner: false
    },
    StatusBar: {
      style: 'dark',
      backgroundColor: "#111827"
    }
  }
};

export default config;
