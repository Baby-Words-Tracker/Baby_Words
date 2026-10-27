import 'package:home_widget_generator/home_widget_generator.dart';

@HomeWidget(
  name: 'AddWordAction',
  widgetUrl: 'babytracker://add_entry_page',
  android: HomeWidgetAndroidConfiguration(),
  iOS: HomeWidgetIOSConfiguration(
    groupId: 'group.com.example.app',
    supportedFamilies: [HWWidgetFamily.systemSmall],
  ),
  widget: HWColumn(
    crossAxisAlignment: HWCrossAxisAlignment.start,
    children: [
      HWText.fixed(
        '＋ Quick Log',
        style: HWRoleTextStyle(role: HWTextStyleRole.caption),
      ),
      HWText.fixed(
        'Add New Baby Word',
        style: HWRoleTextStyle(
          role: HWTextStyleRole.title,
          fontWeight: HWFontWeight.bold,
        ),
      ),
    ],
  ),
)
class AddWordAction {}
