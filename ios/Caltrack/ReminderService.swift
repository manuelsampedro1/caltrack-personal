import Foundation
import UserNotifications

enum ReminderService {
    static let identifier = "caltrack.daily.meal-reminder"

    static func scheduleDaily(hour: Int, minute: Int) async throws {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound])
        guard granted else { throw ReminderError.permissionDenied }
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "¿Te falta registrar algo?"
        content.body = "Una foto ahora mantiene completo el día y hace más útil tu tendencia."
        content.sound = .default

        var date = DateComponents()
        date.hour = hour
        date.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        try await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}

enum ReminderError: LocalizedError {
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .permissionDenied: "Las notificaciones están desactivadas para Caltrack. Puedes habilitarlas desde Ajustes del iPhone."
        }
    }
}
