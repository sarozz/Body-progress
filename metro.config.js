const { getDefaultConfig } = require('expo/metro-config');

const config = getDefaultConfig(__dirname);

// expo-sqlite WASM support for web; harmless on native.
config.resolver.assetExts.push('wasm');
// Drizzle migrations are bundled as plain JSON.
config.resolver.sourceExts.push('sql');

module.exports = config;
