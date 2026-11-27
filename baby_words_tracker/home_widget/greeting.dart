import 'package:home_widget_generator/home_widget_generator.dart';

//Used to match widget colors to that of main application
const _widgetBackground = HWColor.themed(
  light: HWColor.fixed(0xFFFCEAE8),
  dark: HWColor.fixed(0xFF322827),
);

@HomeWidget(
  name: 'Greeting',
  android: HomeWidgetAndroidConfiguration(
    backgroundColor: _widgetBackground,
  ),
  iOS: HomeWidgetIOSConfiguration(
    groupId: 'group.com.example.app',
    backgroundColor: _widgetBackground,
  ),
  widget: HWColumn(
    crossAxisAlignment: HWCrossAxisAlignment.start,
    children: [
      HWText(
        HWString('name', defaultValue: 'Baby'),
        style: HWRoleTextStyle(
          role: HWTextStyleRole.title,
          fontWeight: HWFontWeight.bold,
        ),
      ),
      HWRow(
        children: [
          HWText(
            HWString('wordsCount', defaultValue: '0'),
            style: HWRoleTextStyle(
              role: HWTextStyleRole.headline,
              fontWeight: HWFontWeight.bold,
            ),
          ),
          HWText.fixed(
            ' words',
            style: HWRoleTextStyle(
              role: HWTextStyleRole.headline,
              fontWeight: HWFontWeight.bold,
            ),
          ),
        ],
      ),
    ],
  ),
)
class Greeting {}
