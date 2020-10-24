process.env.NODE_ENV = process.env.NODE_ENV || "development";

const environment = require("./environment");

// dotenv for exposing values for ngrok
const dotenv = require("dotenv");

dotenv.config({ path: ".env", silent: true });

const ngrokTunnel = process.env.ASSET_TUNNEL_URI;

// Webpack Dev Server (WDS) is usually 3035.
// Because we are accessing WDS through ngrok, everything is https.
// HTTPS is normally port 443.
// This also means that this config w/o more work is ngrok all the time.
environment.config.merge({
  devServer: {
    port: "443",
    public: ngrokTunnel,
  },
});

module.exports = environment.toWebpackConfig();
