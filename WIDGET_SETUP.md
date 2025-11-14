# Guía para Configurar Widgets

## Android

Los archivos del widget ya están creados. Para que funcionen:

1. **Compila la app**:

   ```bash
   flutter build apk
   ```

2. **Instala la app** en tu dispositivo Android

3. **Agrega el widget**:

   - Mantén presionado en la pantalla de inicio
   - Selecciona "Widgets"
   - Busca "Mi Rutina Diaria"
   - Arrastra el widget a tu pantalla de inicio

4. **El widget mostrará**:
   - Tu racha actual de días
   - La próxima rutina programada (si hay una)
   - La hora de la próxima rutina

## iOS

Para iOS, necesitas crear un Widget Extension manualmente en Xcode:

1. **Abre el proyecto en Xcode**:

   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Crea el Widget Extension**:

   - File → New → Target
   - Selecciona "Widget Extension"
   - Nombre: `RutinaDiariaWidget`
   - Language: Swift
   - Include Configuration Intent: No

3. **Configura el App Group**:

   - Selecciona el target del Widget Extension
   - Ve a "Signing & Capabilities"
   - Agrega "App Groups"
   - Crea/Selecciona: `group.com.rutinadiaria.widgets`
   - Haz lo mismo para el target principal de la app

4. **Implementa el widget** (en el archivo generado):

   ```swift
   import WidgetKit
   import SwiftUI

   struct RutinaDiariaWidget: Widget {
       let kind: String = "RutinaDiariaWidget"

       var body: some WidgetConfiguration {
           StaticConfiguration(kind: kind, provider: Provider()) { entry in
               RutinaDiariaWidgetEntryView(entry: entry)
           }
           .configurationDisplayName("Mi Rutina Diaria")
           .description("Muestra tu racha y próxima rutina")
           .supportedFamilies([.systemSmall, .systemMedium])
       }
   }

   struct Provider: TimelineProvider {
       func placeholder(in context: Context) -> SimpleEntry {
           SimpleEntry(date: Date(), streakDays: 0, nextRoutine: nil, nextRoutineTime: nil)
       }

       func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
           let entry = SimpleEntry(
               date: Date(),
               streakDays: UserDefaults(suiteName: "group.com.rutinadiaria.widgets")?.integer(forKey: "streak_days") ?? 0,
               nextRoutine: UserDefaults(suiteName: "group.com.rutinadiaria.widgets")?.string(forKey: "next_routine"),
               nextRoutineTime: UserDefaults(suiteName: "group.com.rutinadiaria.widgets")?.string(forKey: "next_routine_time")
           )
           completion(entry)
       }

       func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
           let entry = SimpleEntry(
               date: Date(),
               streakDays: UserDefaults(suiteName: "group.com.rutinadiaria.widgets")?.integer(forKey: "streak_days") ?? 0,
               nextRoutine: UserDefaults(suiteName: "group.com.rutinadiaria.widgets")?.string(forKey: "next_routine"),
               nextRoutineTime: UserDefaults(suiteName: "group.com.rutinadiaria.widgets")?.string(forKey: "next_routine_time")
           )
           let timeline = Timeline(entries: [entry], policy: .atEnd)
           completion(timeline)
       }
   }

   struct SimpleEntry: TimelineEntry {
       let date: Date
       let streakDays: Int
       let nextRoutine: String?
       let nextRoutineTime: String?
   }

   struct RutinaDiariaWidgetEntryView: View {
       var entry: Provider.Entry

       var body: some View {
           VStack(spacing: 8) {
               Text("Mi Rutina Diaria")
                   .font(.caption)
                   .foregroundColor(.purple)

               HStack {
                   Text("\(entry.streakDays)")
                       .font(.system(size: 32, weight: .bold))
                       .foregroundColor(.purple)
                   VStack(alignment: .leading) {
                       Text(entry.streakDays == 1 ? "día" : "días")
                           .font(.caption)
                           .foregroundColor(.purple)
                       Text("🔥")
                   }
               }

               if let routine = entry.nextRoutine {
                   VStack(spacing: 4) {
                       Text("Próxima rutina:")
                           .font(.caption2)
                           .foregroundColor(.gray)
                       Text(routine)
                           .font(.subheadline)
                           .fontWeight(.semibold)
                           .lineLimit(1)
                       if let time = entry.nextRoutineTime {
                           Text("a las \(time)")
                               .font(.caption2)
                               .foregroundColor(.gray)
                       }
                   }
               }
           }
           .padding()
           .background(Color(red: 0.96, green: 0.95, blue: 1.0))
       }
   }
   ```

5. **Compila y ejecuta** desde Xcode

## Notas

- El widget se actualiza automáticamente cuando completas una rutina
- Los datos se comparten entre la app y el widget usando SharedPreferences (Android) o UserDefaults (iOS)
- El App Group ID debe ser el mismo en ambos: `group.com.rutinadiaria.widgets`
