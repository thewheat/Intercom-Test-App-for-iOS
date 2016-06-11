# Test Intercom App for iOS

- Uses Intercom's iOS SDK https://github.com/intercom/intercom-ios to easily test the SDK functionality
- Enables testing all features of the mobile SDK without needing any server side changes (everything is self contained in the app)
- Several things this app does is not meant to be done in production, e.g.
   - Client side secure mode hash generation. The secret key should be contained on your server and be kept a secret


## Usage
- Fill in settings page with all necessary data (at minimum the App ID and SDK API Key)
- Settings needed would be in Intercom: https://app.intercom.io/a/apps/_/settings/ios
- Save and close the app if you make any changes to the App ID / SDK API Key
- Reopen app (if necessary) and specify user details and login
- To verify you have logged in, select "Show Conversations" (from the page / menu). It should show you the conversation list (if there is an error it will say "Unable to load conversations")
- Details of the app are logged (using `NSLog()`) and viewable via app output

## Installation for development
- Ensure you have [CocoaPods](https://cocoapods.org/) installed
- In a terminal go into the root folder where the `Podfile` is located and run `pod install`
- open "Intercom Test App.xcworkspace"


## Screenshots
**Login Page**

![login](/screenshots/login.png)

**Attributes & Events**

![attributes-events](/screenshots/attributes-events.png)

**Misc**

![misc](/screenshots/misc.png)

**Settings**

![settings](/screenshots/settings.png)
