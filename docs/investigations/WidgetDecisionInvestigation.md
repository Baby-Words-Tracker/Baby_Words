# Flutter Home Screen Widget Decision:

As it turns out, flutter does not have the ability to run widgets outside of its main UI. Instead, we would have to use other packages, plugins, and/or platform frameworks. It appears that most developers use the home_widget package to help fulfill that requirement, as this package allows developers to interface with native code. However, using just the home_widget package requires a developer to write native device code for widgets, dividing the project across devices.

Thankfully, the creator of the home_widget package has also created the home_widget_generator and home_widget_cli packages. Both are required for widget generation.
* Home_widget_generator appears to write widgets similar to the way flutter writes apps, where we would be able to write widgets fully in dart.
* Home_widget_cli appears to help scaffold the generation process.

We are choosing to use these packages to follow along with the trend set by previous development iterations, where the flutter engine bypasses having to write native device code. Attached below are relevent links to this decision.

## Links

[Home_widget Documentation](https://docs.page/abausg/home_widget)

[Home_widget GitHub Repo](https://github.com/ABausG/home_widget/tree/main/docs).
