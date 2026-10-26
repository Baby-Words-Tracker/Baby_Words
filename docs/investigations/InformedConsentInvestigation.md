# Requirements for Informed Consent
As this is an IRB Certified Research Project, we have to collect informed consent. So far, the 
protocol has been that DocuSign forms are sent to users before the app is used. We want a easily usable,
fully integrated way of collecting this data that hopefully does not require sending external messages or requiring 
direct contact between the lab and the user.

# Possible Options
The IRB only allows us to use one of two options: Docusign or REDCap. Each has their own 
benefits and drawbacks

# DocuSign
- A developer account with Docusign allows us to seamlessly integrate the informed consent form into the app
- Docusign is a paid service, however the LECS lab is currently able to use it through the University for free. Further investigation must be done (aka, a meeting with IT this week) to determine whether the same applies for a developer account

# REDCap
- Free to use
- Does not allow for seamless integration within the app, interacts with users via email 
- Not as well known and not widely used at UA
- Seperate mobile app download to be able to review data, not the most desirable option

# Possible Workarounds
Docusign is by far the preferred option on implementation, however in the case that we cannot acquire a
account paid for by the university, there are two main options for how informed consent can be collected:

1. We can still use docusign, and investigate a way to automatically send emails 
    - this approach is mildly unsafe, as there isn't a reliable way to ensure participants have filled out the form
    - this approach is likely more user-friendly, as docusign is a more commonly used software and therefore participants likely have more familiarity with it
2. We use REDCap and work with sending external emails. 
    - likley easier to manage determining completion rates, only drawback is not being able to integrate directly with the app and instead relying on email 