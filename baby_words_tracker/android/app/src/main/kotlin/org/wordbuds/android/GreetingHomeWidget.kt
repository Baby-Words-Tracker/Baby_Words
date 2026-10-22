// GENERATED CODE - DO NOT MODIFY BY HAND
//
// This is a placeholder Glance (Jetpack Compose) widget.
package org.wordbuds.android

import androidx.compose.runtime.Composable
import android.content.Context
import androidx.compose.ui.graphics.Color
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Box
import androidx.glance.layout.fillMaxSize
import androidx.glance.text.Text
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetPlugin
import androidx.glance.layout.Column
import androidx.glance.layout.Alignment
import androidx.glance.text.TextStyle
import androidx.glance.GlanceTheme
import androidx.compose.ui.unit.sp
import androidx.glance.text.FontWeight
import androidx.glance.layout.height
import androidx.compose.ui.unit.dp
import androidx.glance.layout.Spacer
import androidx.core.os.ConfigurationCompat
import java.util.Locale
import androidx.glance.color.ColorProvider
import androidx.glance.layout.padding
import androidx.glance.action.clickable
import androidx.glance.action.actionStartActivity

class GreetingHomeWidget : GlanceAppWidget() {
  override val stateDefinition = HomeWidgetGlanceStateDefinition()

  override suspend fun provideGlance(context: Context, id: GlanceId) {
    provideContent { WidgetContent(context, currentState()) }
  }

  override suspend fun providePreview(context: Context, widgetCategory: Int) {
    provideContent { WidgetContent(context, HomeWidgetGlanceState(HomeWidgetPlugin.getData(context))) }
  }

  fun previewFingerprint(context: Context): String {
    val hwLocales = hwCurrentLocales(context)
    val hwPreviewData =
        GreetingData.fromPreferences(HomeWidgetPlugin.getData(context))
    return listOf(
      "d7cdf27d",
      hwLocales.joinToString(","),
      hwPreviewData.toString(),
    ).joinToString("|")
  }

  @Composable
  private fun WidgetContent(context: Context, currentState: HomeWidgetGlanceState) {
    val prefs = currentState.preferences
    val widgetData = GreetingData.fromPreferences(prefs)
    GlanceTheme {
            Box(modifier = GlanceModifier.background(GlanceTheme.colors.widgetBackground).padding(16.dp).fillMaxSize().clickable(onClick = actionStartActivity<MainActivity>()), contentAlignment = Alignment.Center) {
                Column(horizontalAlignment = Alignment.Start) {
                    Text(text = "Tracking Profile:", style = TextStyle(color = GlanceTheme.colors.onSurface, fontSize = 12.sp, fontWeight = FontWeight.Normal))
                    Text(text = widgetData.name ?: "", style = TextStyle(color = GlanceTheme.colors.onSurface, fontSize = 22.sp, fontWeight = FontWeight.Bold))
                    Spacer(modifier = GlanceModifier.height(8.0.dp))
                    Text(text = "Total Words:", style = TextStyle(color = GlanceTheme.colors.onSurface, fontSize = 12.sp, fontWeight = FontWeight.Normal))
                    Text(text = widgetData.wordsCount ?: "", style = TextStyle(color = GlanceTheme.colors.onSurface, fontSize = 18.sp, fontWeight = FontWeight.Bold))
                }
            }
    }

  }
}

data class GreetingData(
    val name: String? = null,
    val wordsCount: String? = null,
) {
    companion object {
        private const val PREFERENCES_PREFIX = "home_widget.Greeting"

        fun fromPreferences(prefs: android.content.SharedPreferences): GreetingData {
            return GreetingData(
                name = prefs.getString("${PREFERENCES_PREFIX}.name", "Baby"),
                wordsCount = prefs.getString("${PREFERENCES_PREFIX}.wordsCount", "0"),
            )
        }
    }
}


private fun hwCurrentLocales(context: Context): List<String> {
    val configured = ConfigurationCompat
        .getLocales(context.resources.configuration)
    val tags = mutableListOf<String>()
    for (index in 0 until configured.size()) {
        val locale = configured[index] ?: continue
        val tag = locale.toLanguageTag()
        if (tag.isNotEmpty() && tag != "und") tags.add(tag)
    }
    if (tags.isEmpty()) {
        val fallback = Locale.getDefault().toLanguageTag()
        if (fallback.isNotEmpty() && fallback != "und") tags.add(fallback)
    }
    return tags
}
