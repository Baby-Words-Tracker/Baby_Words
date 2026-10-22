import 'package:home_widget_generator/home_widget_generator.dart';

@HomeWidget(
  name: 'Greeting',
  android: HomeWidgetAndroidConfiguration(),
  iOS: HomeWidgetIOSConfiguration(
<<<<<<< Updated upstream
    groupId: 'group.com.example.app',
=======
    groupId: 'group.com.example.app', // Ensure this matches your package App Group ID
>>>>>>> Stashed changes
  ),
  widget: HWColumn(
    crossAxisAlignment: HWCrossAxisAlignment.start,
    children: [
      HWText.fixed(
        'Tracking Profile:',
        style: HWRoleTextStyle(role: HWTextStyleRole.caption),
      ),
      HWText(
        HWString('name', defaultValue: 'Baby'),
        style: HWRoleTextStyle(
          role: HWTextStyleRole.title,
          fontWeight: HWFontWeight.bold,
        ),
      ),
<<<<<<< Updated upstream
      HWSizedBox(height: 8),
=======
      // Clean text block with no trailing container/spacing blocks required
>>>>>>> Stashed changes
      HWText.fixed(
        'Total Words:',
        style: HWRoleTextStyle(role: HWTextStyleRole.caption),
      ),
      HWText(
<<<<<<< Updated upstream
        HWString('wordsCount', defaultValue: '0'),
=======
        HWString('wordsCount', defaultValue: '0'), 
>>>>>>> Stashed changes
        style: HWRoleTextStyle(
          role: HWTextStyleRole.headline,
          fontWeight: HWFontWeight.bold,
        ),
      ),
    ],
  ),
)
<<<<<<< Updated upstream
class Greeting {}
=======
class Greeting {}
>>>>>>> Stashed changes
