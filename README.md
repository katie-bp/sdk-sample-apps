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

## Simple Start
Install xcode form the app store

Run this with xcode closed:

swift package-registry set --global --scope keyless https://swift.cloudsmith.io/keyless/partners/
swift package-registry login https://swift.cloudsmith.io/keyless/partners/ --token 99FffDQOoqb5e8oR

Open JourneyModuleSample (under iOS/swiftui-journey-module) in xcode, change the simualtor to be "My Mac (Designed for iPad)", press the play (run) button on the top right of the left side bar. 
Once running, click the Journey Flow button, and enter the journey name (RecognizeEnrollment), then start journey to go through the flow.

To set this up against a local env, update ViewModels/JourneyViewModel serverUrl etc to point to your environment. 
Make sure you add the server api key and recognize api key to the default keystore, use the aliases pingone-recognize-server-api-key and pingone-recognize-api-key respectively for them. 
Use the postman collection here to get set up: [Recognize Collection](https://github.com/katie-barrett-powell_pingcorp/postman-collections/blob/master/PingOne%20Recognize.postman_collection.json)
