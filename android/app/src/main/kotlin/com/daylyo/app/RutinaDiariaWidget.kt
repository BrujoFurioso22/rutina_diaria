package com.daylyo.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews

/**
 * Widget provider para mostrar la racha y próxima rutina en la pantalla de inicio.
 */
class RutinaDiariaWidget : AppWidgetProvider() {
    
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        // Se llama cuando el primer widget se agrega
    }

    override fun onDisabled(context: Context) {
        // Se llama cuando el último widget se elimina
    }

    companion object {
        private const val PREFS_NAME = "group.com.rutinadiaria.widgets"
        
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            // Obtener datos del widget usando SharedPreferences (compartido con Flutter)
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val streakDays = prefs.getInt("streak_days", 0)
            val nextRoutine = prefs.getString("next_routine", "") ?: ""
            val nextRoutineTime = prefs.getString("next_routine_time", "") ?: ""

            // Crear las vistas remotas
            val views = RemoteViews(context.packageName, R.layout.widget_rutina_diaria)

            // Actualizar el texto de la racha
            views.setTextViewText(R.id.widget_streak_text, "$streakDays")
            views.setTextViewText(R.id.widget_streak_label, if (streakDays == 1) "día" else "días")

            // Actualizar la próxima rutina
            if (nextRoutine.isNotEmpty()) {
                views.setTextViewText(R.id.widget_next_routine_text, nextRoutine)
                views.setTextViewText(R.id.widget_next_routine_time, if (nextRoutineTime.isNotEmpty()) "a las $nextRoutineTime" else "")
                views.setViewVisibility(R.id.widget_next_routine_container, android.view.View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_next_routine_container, android.view.View.GONE)
            }

            // Intent para abrir la app al tocar el widget
            val intent = android.content.Intent(context, MainActivity::class.java)
            val pendingIntent = android.app.PendingIntent.getActivity(
                context, 0, intent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

            // Actualizar el widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

