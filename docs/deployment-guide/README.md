# Deployment Docs

This app is designed to be deployed in the Apple App Store and the Google Play Store. This document outlines how to deploy to each platform, and common issues that may be encountered during this process. Before reading this document, please read the developer documentation (found in docs/development-guide/README.md) to ensure that you are able to run the program locally and test before attempting to deploy. 

## Preparing the Repository for Deployment

Before allowing any version of the repository to be deployed on any platform, please ensure that any debugging infrastructure hard-coded into the repository is removed. This is crucial for avoiding security vulnerabilities. `debugPrints` are fine to stay, as they will not show up in the final product for end users. 

In addition, please ensure that all URLs are up to date and usable. This app requires use of a qualtrics survey and DocuSign consent form that are required to use the app. While changes can be made to these external sites without the explicit URL changing, it’s best practice to double check them before deploying. Most of these links will be found in the onboarding section of the repository. 

Finally, ensure that your team has ample screenshots of the app in its current condition, and that you have some textual information about the app to use as marketing materials for your app on whichever app store you use. 

## Deployment to Apple App Store

Deploying to the App Store requires gaining access to an Apple Developer Account. Please ensure that this account is somehow tied to the sponsor (Lisa Hsin) or the LECS lab and not your personal account, failure to do so results in the app not being accessible to the sponsor after you leave the project. If the app is deployed with a personal account it may be impossible for future teams to retrieve the deployed app. This is crucial with providing a name for the app once it’s published. A previous team used a personal account to put the app on TestFlight and as a result, the name ‘Wordbuds’ is no longer available for use on our end. An apple developer account should be provided to you if you ask, if it is not, reach out to the professor immediately, as the process of obtaining an account can take almost an entire semester. 

Once an apple developer account is created and obtained, you’ll likely begin by placing the app onto TestFlight. [The TestFlight documentation can be found here](https://developer.apple.com/testflight/). 

## Android deployment

Android deployment, like Apple deployment, needs a developer account. The link detailing the [setup for a google play console can be found here](https://play.google.com/console/u/0/signup). Please note that this account costs $25, please reach out to the sponsor about possibly having a pre-existing account before paying this. Also like apple development, please use an account related to the LECS lab or to Lisa Hsin so that future teams are able to continue work on the project. 

## Additional Resources

[Android Deployment Documentation](https://developer.android.com/studio/publish/)  
[Apple Deployment Documentation](https://developer.apple.com/)
