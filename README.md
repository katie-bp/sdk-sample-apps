<p align="center">
  <a href="https://github.com/ForgeRock/sdk-sample-apps">
    <img src="https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg" alt="Ping Identity Logo">
  </a>
  <hr/>
</p>

## Samples

Ping provides these samples to help demonstrate SDK functionality/implementation. They are provided "as is" and are not official products of Ping and are not officially supported.

Our samples showcase functionality of our SDKs to get you up and running,
whether you are using PingOne Advanced Identity Cloud, PingAM,
OIDC (Redirect) Login, or PingOne DaVinci, we've got you covered.

Explore the many use cases
the Ping SDKs have to offer by referring to each respective SDK:

- [JavaScript](./javascript/)

- [iOS](./iOS/)

- [Android](./android/)

## Documentation

Detailed [documentation](https://docs.pingidentity.com/sdks) is provided, and includes topics such as:

- Tutorial walkthroughs for each server
- Integrating functionality such as PingOne Protect, WebAuthn, and more
- Code snippets
- API Reference documentation

## Requirements

JavaScript
- Please use a modern web browser like Chrome, Safari, or Firefox
- Node >= 18

iOS
- Latest Xcode

Android
- Latest Android Studio
- Java 17+
- Gradle 8.6+
- Android API level 23+

## Simple Start - iOS
Install xcode form the app store

Run this with xcode closed:

```
swift package-registry set --global --scope keyless https://swift.cloudsmith.io/keyless/partners/
swift package-registry login https://swift.cloudsmith.io/keyless/partners/ --token 99FffDQOoqb5e8oR
```

Open JourneyModuleSample (under iOS/swiftui-journey-module) in xcode, change the simualtor to be "My Mac (Designed for iPad)", press the play (run) button on the top right of the left side bar. 
Once running, click the Journey Flow button, and enter the journey name (RecognizeEnrollment), then start journey to go through the flow.

To set this up against a local env, update ViewModels/JourneyViewModel serverUrl etc to point to your environment. 
Make sure you add the server api key and recognize api key to the default keystore, use the aliases pingone-recognize-server-api-key and pingone-recognize-api-key respectively for them. 
Use the postman collection here to get set up: [Recognize Collection](https://github.com/katie-barrett-powell_pingcorp/postman-collections/blob/master/PingOne%20Recognize.postman_collection.json)

## Simple Start - Web App

Run this:

```
npm config set --location=global @keyless:registry=https://npm.cloudsmith.io/keyless/partners/
npm config set --location=global //npm.cloudsmith.io/keyless/partners/:_authToken=99FffDQOoqb5e8oR
```

Follow the following setup steps from the [README](./javascript/reactjs-todo/README.md).

## Requirements

1. An instance of Ping's Access Manager (AM), either within a Ping's Advanced Identity Cloud tenant, your own private installation or locally installed on your computer
2. Node >= 14.2.0 (recommended: install via [official package installer](https://nodejs.org/en/))
3. Knowledge of using the Terminal/Command Line
4. Ability to generate security certs (recommended: mkcert ([installation instructions here](https://github.com/FiloSottile/mkcert#installation))
5. This project "cloned" to your computer

### Configure Your `.env` File
Change the name of `.env.example` (in /javascript/reactjs-todo) to `.env` and replace with the following:

```
# SERVER_URL - AM URL for AIC or PingOne base URL with env ID for PingOne
SERVER_URL='https://openam-recognize-nodes.forgeblocks.com/am'
# SCOPE - OAuth2 scopes
# e.g. 'openid profile email address phone revoke' When using PingOne services `revoke` scope is required
SCOPE='openid profile email revoke'
# APP_URL - URL to use for the todo React app
APP_URL='https://localhost:8443'
# API_URL - URL to use for the todo API server
API_URL='http://localhost:9443'
# DEBUGGER_OFF - true | false
# Enable or disable debugger statements in the code
DEBUGGER_OFF='false'
# DEVELOPMENT - true | false
# Run webpack in development mode
DEVELOPMENT='false'
# JOURNEY_LOGIN - Name of AM journey for login
JOURNEY_LOGIN='RecognizeEnrollment'
# JOURNEY_REGISTER - Name of AM journey for registration
JOURNEY_REGISTER='RecognizeEnrollment'
# PORT - Port to run the React app on
PORT='8443'
# REALM_PATH - alpha | beta
# For AIC server type. Not used for PingOne.
REALM_PATH='alpha'
# REST_OAUTH_CLIENT - Confidential client ID for AIC or WebApp public client ID for PingOne
REST_OAUTH_CLIENT='restClient'
# REST_OAUTH_CLIENT - Confidential client secret for AIC. Not used for PingOne.
REST_OAUTH_SECRET='secret'
# WEB_OAUTH_CLIENT - Public client ID for AIC
WEB_OAUTH_CLIENT='webClient'
# CENTRALIZED_LOGIN - true | false
# Enable centralized login, redirects go to {APP_URL}/login?centralLogin=true
CENTRALIZED_LOGIN='false'
# SERVER_TYPE - AIC | PINGONE
SERVER_TYPE='AIC'
# WELLKNOWN_URL - AIC well-known URL or PingOne well-known URL with env ID
WELLKNOWN_URL='https://openam-recognize-nodes.forgeblocks.com/am/oauth2/alpha/.well-known/openid-configuration'
```

Also change the name of `.env.example` (in /javascript/todo-api) to `.env` and replace with the following:
```
# SERVER_TYPE - AIC | PINGONE
SERVER_TYPE='AIC'
# SERVER_URL - AM URL for AIC or PingOne base URL with env ID for PingOne
SERVER_URL='https://openam-recognize-nodes.forgeblocks.com/am'
# PORT - Port to run the API on
PORT='9443'
# REALM_PATH - alpha | beta
# For AIC server type. Not used for PingOne.
REALM_PATH='alpha'
# REST_OAUTH_CLIENT - Confidential client ID for AIC or WebApp public client ID for PingOne
REST_OAUTH_CLIENT='restClient'
# REST_OAUTH_SECRET - Confidential client secret for AIC. Not used for PingOne.
REST_OAUTH_SECRET='secret'
```

### Installing Dependencies and Run Build

**Run from root of repo**: since this sample app uses npm's workspaces, we recommend running the npm commands from the root of the repo.
```sh
npm install
```

### Run the Servers

Now, run the below commands to start the processes needed for building the application and running the servers for both client and API server:

```sh
# In one terminal window, run the following watch command from the javascript folder.
npm run start:reactjs-todo
```

Now, you should be able to visit `https://localhost:8443`, and test the journey.

**Note** currently broken, only the instructions screen of keyless enrollment loads before seeing an error.
