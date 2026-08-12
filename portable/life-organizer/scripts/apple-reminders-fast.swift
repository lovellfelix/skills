#!/usr/bin/env swift
// Fast Apple Reminders query using EventKit (native API, no AppleScript overhead)
// Usage: swift apple-reminders-fast.swift [--json] <command>
// Commands:
//   overdue | today | all | list <name> | scheduled | flagged
//   add <list> <title> [due] [notes] [priority] [location]
//   update <list> <old_title> [new_title] [due] [notes] [priority] [location]
//   complete <list> <title>
//   rename <old_name> <new_name>
//   search <query>
//   search-tag <tag>
//   add-tags <list> <title> <tags>

import EventKit
import Foundation
import MapKit

// MARK: - Date Formatting Helpers

func formatDate(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    return f.string(from: date)
}

func formatDue(_ comps: DateComponents?) -> String {
    guard let comps else { return "" }
    guard let date = Calendar.current.date(from: comps) else { return "" }
    
    // If no time component, just return date
    if comps.hour == nil && comps.minute == nil {
        return formatDate(date)
    }
    
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.timeZone = TimeZone.current
    f.dateFormat = "yyyy-MM-dd HH:mm"
    return f.string(from: date)
}

// MARK: - JSON Output

func toJson(_ items: [[String: Any]]) {
    do {
        let data = try JSONSerialization.data(withJSONObject: items, options: [])
        if let s = String(data: data, encoding: .utf8) {
            print(s)
        } else {
            print("[]")
        }
    } catch {
        print("[]")
    }
}

// MARK: - Metadata Parsing

func normalizeTag(_ raw: String) -> String? {
    var t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    if t.hasPrefix("#") { t.removeFirst() }
    t = t.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !t.isEmpty else { return nil }
    // Keep tags simple and compatible with Reminders UI.
    let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-"))
    if t.unicodeScalars.allSatisfy({ allowed.contains($0) }) {
        return t
    }
    return nil
}

func tagsFromString(_ raw: String) -> [String] {
    // Accept comma-separated or whitespace-separated tags.
    // Examples: "family,weekend" or "family weekend" or "#family #weekend"
    let replaced = raw.replacingOccurrences(of: ",", with: " ")
    return replaced
        .split(whereSeparator: { $0.isWhitespace })
        .compactMap { normalizeTag(String($0)) }
}

func tagsToHashtags(_ tags: [String]) -> String {
    let uniq = Array(Set(tags)).sorted()
    if uniq.isEmpty { return "" }
    return uniq.map { "#" + $0 }.joined(separator: " ")
}

func extractHashtags(from text: String) -> [String] {
    let regex = try! NSRegularExpression(pattern: "(?:^|\\s)#([A-Za-z0-9_-]+)\\b", options: [])
    let ns = text as NSString
    let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: ns.length))
    return matches.compactMap { m in
        let r = m.range(at: 1)
        if r.location == NSNotFound { return nil }
        return normalizeTag(ns.substring(with: r))
    }
}

func stripHashtags(from text: String) -> String {
    let regex = try! NSRegularExpression(pattern: "(?:^|\\s)#[A-Za-z0-9_-]+\\b", options: [])
    let range = NSRange(text.startIndex..., in: text)
    let stripped = regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
    return stripped.trimmingCharacters(in: .whitespacesAndNewlines)
}

/// Extract metadata from notes field.
///
/// Back-compat:
/// - Reads legacy `[location:...]` and `[tags:...]` blocks.
/// - Reads native tags from hashtags (`#tag`) in the notes.
///
/// Returned `cleanNotes` strips these markers.
func extractMetadata(from notes: String?) -> (location: String?, tags: String?, cleanNotes: String) {
    guard let notes = notes, !notes.isEmpty else {
        return (nil, nil, "")
    }

    var cleanNotes = notes
    var location: String?
    var tagSet = Set<String>()

    // Legacy location: [location:Office]
    let locationRegex = try! NSRegularExpression(pattern: "\\[location:([^\\]]+)\\]", options: [])
    if let match = locationRegex.firstMatch(in: notes, options: [], range: NSRange(notes.startIndex..., in: notes)) {
        if let range = Range(match.range(at: 1), in: notes) {
            location = String(notes[range]).trimmingCharacters(in: .whitespaces)
        }
        cleanNotes = locationRegex.stringByReplacingMatches(in: cleanNotes, options: [], range: NSRange(cleanNotes.startIndex..., in: cleanNotes), withTemplate: "")
    }

    // Legacy tags: [tags:work,urgent]
    let tagsRegex = try! NSRegularExpression(pattern: "\\[tags:([^\\]]+)\\]", options: [])
    if let match = tagsRegex.firstMatch(in: notes, options: [], range: NSRange(notes.startIndex..., in: notes)) {
        if let range = Range(match.range(at: 1), in: notes) {
            let csv = String(notes[range])
            for t in tagsFromString(csv) { tagSet.insert(t) }
        }
        cleanNotes = tagsRegex.stringByReplacingMatches(in: cleanNotes, options: [], range: NSRange(cleanNotes.startIndex..., in: cleanNotes), withTemplate: "")
    }

    // Native tags via hashtags
    for t in extractHashtags(from: notes) { tagSet.insert(t) }

    // Remove hashtags from cleanNotes (so UI tags don't pollute the note text we display)
    cleanNotes = stripHashtags(from: cleanNotes)
    cleanNotes = cleanNotes.trimmingCharacters(in: .whitespacesAndNewlines)

    let tags = tagSet.isEmpty ? nil : Array(tagSet).sorted().joined(separator: ",")
    return (location, tags, cleanNotes)
}

/// Merge new metadata with existing metadata
/// - Parameters:
///   - oldNotes: Existing notes with metadata
///   - newNotes: New notes content (without metadata)
///   - newLocation: New location (nil = keep existing, "" = remove, value = set new)
///   - newTags: New tags (nil = keep existing, "" = remove, value = set new)
///   - clearLocation: Explicitly clear location
///   - clearTags: Explicitly clear tags
func mergeMetadata(oldNotes: String?, newNotes: String?, newTags: String? = nil, clearTags: Bool = false) -> String {
    let (_, existingTags, existingCleanNotes) = extractMetadata(from: oldNotes)

    let finalTagsCsv: String? = {
        if clearTags { return nil }
        if let t = newTags {
            return t.isEmpty ? nil : t
        }
        return existingTags
    }()

    // Start from provided notes or existing clean notes.
    var base = newNotes ?? existingCleanNotes
    // Strip any metadata from base (legacy blocks + hashtags).
    let (_, tagsFromBase, cleanBase) = extractMetadata(from: base)
    base = cleanBase

    // If newNotes included hashtags, treat them as requested tags unless explicit newTags provided.
    let mergedCsv: String? = {
        if let explicit = finalTagsCsv {
            return explicit
        }
        return tagsFromBase
    }()

    var result = base.trimmingCharacters(in: .whitespacesAndNewlines)
    if let csv = mergedCsv {
        let tags = tagsFromString(csv)
        let hashtags = tagsToHashtags(tags)
        if !hashtags.isEmpty {
            if !result.isEmpty { result += "\n" }
            result += hashtags
        }
    }

    return result.trimmingCharacters(in: .whitespacesAndNewlines)
}

// MARK: - Native Location Reminders

func currentLocationAlarm(_ reminder: EKReminder) -> EKAlarm? {
    return reminder.alarms?.first(where: { $0.structuredLocation != nil })
}

func reminderLocationTitle(_ reminder: EKReminder) -> String? {
    return currentLocationAlarm(reminder)?.structuredLocation?.title
}

func removeLocationAlarms(_ reminder: EKReminder) {
    guard let alarms = reminder.alarms, !alarms.isEmpty else { return }
    let keep = alarms.filter { $0.structuredLocation == nil }
    reminder.alarms = keep
}


func geocode(_ query: String, timeoutSeconds: TimeInterval = 8) -> CLLocation? {
    let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
    if q.isEmpty { return nil }

    // MapKit search avoids deprecated CLGeocoder warnings on newer macOS.
    let req = MKLocalSearch.Request()
    req.naturalLanguageQuery = q
    // Large default region (continental US) as a bias; results still include full placemark.
    req.region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
        span: MKCoordinateSpan(latitudeDelta: 60, longitudeDelta: 80)
    )

    let search = MKLocalSearch(request: req)
    let sem = DispatchSemaphore(value: 0)
    var out: CLLocation?
    search.start { response, _ in
        if let item = response?.mapItems.first {
            if #available(macOS 26.0, *) {
                out = item.location
            } else {
                if let l = item.placemark.location {
                    out = l
                } else {
                    let c = item.placemark.coordinate
                    out = CLLocation(latitude: c.latitude, longitude: c.longitude)
                }
            }
        }
        sem.signal()
    }
    _ = sem.wait(timeout: .now() + timeoutSeconds)
    return out
}

func setNativeLocation(_ reminder: EKReminder, locationTitle: String) {
    let title = locationTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !title.isEmpty else { return }

    // Replace any existing location alarms.
    removeLocationAlarms(reminder)

    let loc = EKStructuredLocation(title: title)
    if let cl = geocode(title) {
        loc.geoLocation = cl
    }
    loc.radius = 200

    let alarm = EKAlarm()
    alarm.structuredLocation = loc
    alarm.proximity = .enter

    var alarms = reminder.alarms ?? []
    alarms.append(alarm)
    reminder.alarms = alarms
}

func resolvedLocation(for reminder: EKReminder) -> String? {
    if let t = reminderLocationTitle(reminder), !t.isEmpty {
        return t
    }
    let (loc, _, _) = extractMetadata(from: reminder.notes)
    return loc
}

// MARK: - Date Parsing

func parseDueDate(_ str: String) -> Date? {
    if str.isEmpty || str == "none" || str == "clear" {
        return nil
    }
    
    // Try "YYYY-MM-DD HH:MM" format first
    let fullFormatter = DateFormatter()
    fullFormatter.locale = Locale(identifier: "en_US_POSIX")
    fullFormatter.timeZone = TimeZone.current
    fullFormatter.dateFormat = "yyyy-MM-dd HH:mm"
    if let date = fullFormatter.date(from: str) {
        return date
    }
    
    // Try "YYYY-MM-DD" format (date only)
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.timeZone = TimeZone.current
    dateFormatter.dateFormat = "yyyy-MM-dd"
    if let date = dateFormatter.date(from: str) {
        return date
    }
    
    return nil
}

func makeDateComponents(_ date: Date) -> DateComponents {
    let cal = Calendar.current
    let hasTime = cal.component(.hour, from: date) != 0 || cal.component(.minute, from: date) != 0
    
    if hasTime {
        return cal.dateComponents([.year, .month, .day, .hour, .minute], from: date)
    } else {
        return cal.dateComponents([.year, .month, .day], from: date)
    }
}

// MARK: - Calendar Helpers

func findCalendar(_ name: String, in calendars: [EKCalendar]) -> EKCalendar? {
    return calendars.first { $0.title.lowercased() == name.lowercased() }
}

func reminderListCandidates(for requested: String) -> [String] {
    let name = requested.trimmingCharacters(in: .whitespacesAndNewlines)
    if name.caseInsensitiveCompare("Personal") == .orderedSame {
        // Back-compat: earlier configs used a "Personal" reminders list name.
        return [name, "My Tasks", "Reminders"]
    }
    return [name]
}

func resolveReminderCalendar(_ requested: String, in calendars: [EKCalendar]) -> EKCalendar? {
    for candidate in reminderListCandidates(for: requested) {
        if let cal = findCalendar(candidate, in: calendars) {
            return cal
        }
    }
    return nil
}

// MARK: - Reminder Formatting

func formatReminder(_ reminder: EKReminder, wantJson: Bool) -> String {
    if wantJson {
        var dict: [String: Any] = [
            "title": reminder.title ?? "",
            "list": reminder.calendar?.title ?? "",
            "completed": reminder.isCompleted
        ]
        let due = formatDue(reminder.dueDateComponents)
        if !due.isEmpty {
            dict["due"] = due
        }
        
        // Notes + native tags (hashtags)
        let (_, tags, cleanNotes) = extractMetadata(from: reminder.notes)
        if !cleanNotes.isEmpty {
            dict["notes"] = cleanNotes
        }
        if let location = resolvedLocation(for: reminder), !location.isEmpty {
            dict["location"] = location
        }
        if let tags = tags, !tags.isEmpty {
            dict["tags"] = tags
        }
        
        if reminder.priority > 0 {
            dict["priority"] = reminder.priority
        }
        
        if let data = try? JSONSerialization.data(withJSONObject: dict, options: []),
           let json = String(data: data, encoding: .utf8) {
            return json
        }
        return "{}"
    } else {
        var parts: [String] = []
        parts.append("- \(reminder.title ?? "(no title)")")
        let due = formatDue(reminder.dueDateComponents)
        if !due.isEmpty {
            parts.append("due: \(due)")
        }
        
        // Extract and display metadata
        let (_, tags, cleanNotes) = extractMetadata(from: reminder.notes)
        if !cleanNotes.isEmpty {
            parts.append("notes: \(cleanNotes)")
        }
        if let location = resolvedLocation(for: reminder), !location.isEmpty {
            parts.append("location: \(location)")
        }
        if let tags = tags, !tags.isEmpty {
            parts.append("tags: \(tags)")
        }
        
        if reminder.priority > 0 {
            parts.append("priority: \(reminder.priority)")
        }
        parts.append("[\(reminder.calendar?.title ?? "unknown")]")
        return parts.joined(separator: " | ")
    }
}

// MARK: - Command Handlers

func handleList(_ listName: String, store: EKEventStore, calendars: [EKCalendar], wantJson: Bool) {
    guard let cal = resolveReminderCalendar(listName, in: calendars) else {
        print("List not found: \(listName)")
        exit(1)
    }
    
    let predicate = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: [cal])
    var results: [EKReminder] = []
    let sem = DispatchSemaphore(value: 0)
    
    store.fetchReminders(matching: predicate) { reminders in
        if let reminders = reminders {
            results = reminders.sorted { ($0.dueDateComponents?.date ?? Date.distantFuture) < ($1.dueDateComponents?.date ?? Date.distantFuture) }
        }
        sem.signal()
    }
    sem.wait()
    
    if wantJson {
        let items = results.map { r -> [String: Any] in
            var dict: [String: Any] = ["title": r.title ?? "", "list": r.calendar?.title ?? ""]
            let due = formatDue(r.dueDateComponents)
            if !due.isEmpty { dict["due"] = due }
            
            let (_, tags, cleanNotes) = extractMetadata(from: r.notes)
            if !cleanNotes.isEmpty { dict["notes"] = cleanNotes }
            if let location = resolvedLocation(for: r), !location.isEmpty { dict["location"] = location }
            if let tags = tags, !tags.isEmpty { dict["tags"] = tags }
            if r.priority > 0 { dict["priority"] = r.priority }
            return dict
        }
        toJson(items)
    } else {
        for r in results {
            print(formatReminder(r, wantJson: false))
        }
    }
}

func handleAll(store: EKEventStore, calendars: [EKCalendar], wantJson: Bool) {
    let predicate = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: calendars)
    var results: [EKReminder] = []
    let sem = DispatchSemaphore(value: 0)
    
    store.fetchReminders(matching: predicate) { reminders in
        if let reminders = reminders {
            results = reminders.sorted { ($0.dueDateComponents?.date ?? Date.distantFuture) < ($1.dueDateComponents?.date ?? Date.distantFuture) }
        }
        sem.signal()
    }
    sem.wait()
    
    if wantJson {
        let items = results.map { r -> [String: Any] in
            var dict: [String: Any] = ["title": r.title ?? "", "list": r.calendar?.title ?? ""]
            let due = formatDue(r.dueDateComponents)
            if !due.isEmpty { dict["due"] = due }
            
            let (_, tags, cleanNotes) = extractMetadata(from: r.notes)
            if !cleanNotes.isEmpty { dict["notes"] = cleanNotes }
            if let location = resolvedLocation(for: r), !location.isEmpty { dict["location"] = location }
            if let tags = tags, !tags.isEmpty { dict["tags"] = tags }
            if r.priority > 0 { dict["priority"] = r.priority }
            return dict
        }
        toJson(items)
    } else {
        for r in results {
            print(formatReminder(r, wantJson: false))
        }
    }
}

func handleOverdue(store: EKEventStore, calendars: [EKCalendar], wantJson: Bool) {
    let now = Date()
    let predicate = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: now, calendars: calendars)
    var results: [EKReminder] = []
    let sem = DispatchSemaphore(value: 0)
    
    store.fetchReminders(matching: predicate) { reminders in
        if let reminders = reminders {
            results = reminders.filter {
                guard let dueDate = $0.dueDateComponents?.date else { return false }
                return dueDate < now
            }.sorted { ($0.dueDateComponents?.date ?? Date.distantPast) < ($1.dueDateComponents?.date ?? Date.distantPast) }
        }
        sem.signal()
    }
    sem.wait()
    
    if wantJson {
        let items = results.map { r -> [String: Any] in
            var dict: [String: Any] = ["title": r.title ?? "", "list": r.calendar?.title ?? ""]
            let due = formatDue(r.dueDateComponents)
            if !due.isEmpty { dict["due"] = due }
            
            let (_, tags, cleanNotes) = extractMetadata(from: r.notes)
            if !cleanNotes.isEmpty { dict["notes"] = cleanNotes }
            if let location = resolvedLocation(for: r), !location.isEmpty { dict["location"] = location }
            if let tags = tags, !tags.isEmpty { dict["tags"] = tags }
            if r.priority > 0 { dict["priority"] = r.priority }
            return dict
        }
        toJson(items)
    } else {
        for r in results {
            print(formatReminder(r, wantJson: false))
        }
    }
}

func handleToday(store: EKEventStore, calendars: [EKCalendar], wantJson: Bool) {
    let cal = Calendar.current
    let today = cal.startOfDay(for: Date())
    let tomorrow = cal.date(byAdding: .day, value: 1, to: today)!
    
    let predicate = store.predicateForIncompleteReminders(withDueDateStarting: today, ending: tomorrow, calendars: calendars)
    var results: [EKReminder] = []
    let sem = DispatchSemaphore(value: 0)
    
    store.fetchReminders(matching: predicate) { reminders in
        if let reminders = reminders {
            results = reminders.sorted { ($0.dueDateComponents?.date ?? Date.distantFuture) < ($1.dueDateComponents?.date ?? Date.distantFuture) }
        }
        sem.signal()
    }
    sem.wait()
    
    if wantJson {
        let items = results.map { r -> [String: Any] in
            var dict: [String: Any] = ["title": r.title ?? "", "list": r.calendar?.title ?? ""]
            let due = formatDue(r.dueDateComponents)
            if !due.isEmpty { dict["due"] = due }
            
            let (_, tags, cleanNotes) = extractMetadata(from: r.notes)
            if !cleanNotes.isEmpty { dict["notes"] = cleanNotes }
            if let location = resolvedLocation(for: r), !location.isEmpty { dict["location"] = location }
            if let tags = tags, !tags.isEmpty { dict["tags"] = tags }
            if r.priority > 0 { dict["priority"] = r.priority }
            return dict
        }
        toJson(items)
    } else {
        for r in results {
            print(formatReminder(r, wantJson: false))
        }
    }
}

func handleScheduled(store: EKEventStore, calendars: [EKCalendar], wantJson: Bool) {
    let predicate = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: calendars)
    var results: [EKReminder] = []
    let sem = DispatchSemaphore(value: 0)
    
    store.fetchReminders(matching: predicate) { reminders in
        if let reminders = reminders {
            results = reminders.filter { $0.dueDateComponents != nil }.sorted { ($0.dueDateComponents?.date ?? Date.distantFuture) < ($1.dueDateComponents?.date ?? Date.distantFuture) }
        }
        sem.signal()
    }
    sem.wait()
    
    if wantJson {
        let items = results.map { r -> [String: Any] in
            var dict: [String: Any] = ["title": r.title ?? "", "list": r.calendar?.title ?? ""]
            let due = formatDue(r.dueDateComponents)
            if !due.isEmpty { dict["due"] = due }
            
            let (_, tags, cleanNotes) = extractMetadata(from: r.notes)
            if !cleanNotes.isEmpty { dict["notes"] = cleanNotes }
            if let location = resolvedLocation(for: r), !location.isEmpty { dict["location"] = location }
            if let tags = tags, !tags.isEmpty { dict["tags"] = tags }
            if r.priority > 0 { dict["priority"] = r.priority }
            return dict
        }
        toJson(items)
    } else {
        for r in results {
            print(formatReminder(r, wantJson: false))
        }
    }
}

func handleFlagged(store: EKEventStore, calendars: [EKCalendar], wantJson: Bool) {
    let predicate = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: calendars)
    var results: [EKReminder] = []
    let sem = DispatchSemaphore(value: 0)
    
    store.fetchReminders(matching: predicate) { reminders in
        if let reminders = reminders {
            results = reminders.filter { $0.priority >= 1 && $0.priority <= 4 }.sorted { $0.priority < $1.priority }
        }
        sem.signal()
    }
    sem.wait()
    
    if wantJson {
        let items = results.map { r -> [String: Any] in
            var dict: [String: Any] = ["title": r.title ?? "", "list": r.calendar?.title ?? ""]
            let due = formatDue(r.dueDateComponents)
            if !due.isEmpty { dict["due"] = due }
            
            let (_, tags, cleanNotes) = extractMetadata(from: r.notes)
            if !cleanNotes.isEmpty { dict["notes"] = cleanNotes }
            if let location = resolvedLocation(for: r), !location.isEmpty { dict["location"] = location }
            if let tags = tags, !tags.isEmpty { dict["tags"] = tags }
            if r.priority > 0 { dict["priority"] = r.priority }
            return dict
        }
        toJson(items)
    } else {
        for r in results {
            print(formatReminder(r, wantJson: false))
        }
    }
}

func handleAdd(_ listName: String, title: String, dueStr: String, notesStr: String, priorityStr: String, locationStr: String, tagsStr: String, store: EKEventStore, calendars: [EKCalendar]) {
    guard let cal = resolveReminderCalendar(listName, in: calendars) else {
        print("List not found: \(listName)")
        exit(1)
    }
    
    let reminder = EKReminder(eventStore: store)
    reminder.calendar = cal
    reminder.title = title
    
    // Parse and set due date
    if !dueStr.isEmpty {
        if let due = parseDueDate(dueStr) {
            reminder.dueDateComponents = makeDateComponents(due)
        } else {
            print("(error: invalid due date: \(dueStr); expected 'YYYY-MM-DD' or 'YYYY-MM-DD HH:MM' or 'none')")
            exit(1)
        }
    }
    
    // Notes + tags
    let (locFromNotes, tagsFromNotes, cleanNotes) = extractMetadata(from: notesStr)
    let explicitTags = tagsStr.isEmpty ? nil : tagsStr
    let mergedNotes = mergeMetadata(oldNotes: nil, newNotes: cleanNotes.isEmpty ? nil : cleanNotes, newTags: explicitTags ?? tagsFromNotes)
    if !mergedNotes.isEmpty {
        reminder.notes = mergedNotes
    }

    // Native location reminder (uses geocoding when possible)
    let loc = !locationStr.isEmpty ? locationStr : (locFromNotes ?? "")
    if !loc.isEmpty {
        setNativeLocation(reminder, locationTitle: loc)
    }
    
    // Set priority
    if !priorityStr.isEmpty {
        guard let p = Int(priorityStr), p >= 0, p <= 9 else {
            print("(error: invalid priority: \(priorityStr); expected 0-9)")
            exit(1)
        }
        reminder.priority = p
    }
    
    do {
        try store.save(reminder, commit: true)
        print("Reminder added: \(title)")
    } catch {
        print("(error: could not add reminder: \(error))")
        exit(1)
    }
}

/// Update an existing reminder
/// - Parameters:
///   - listName: The list containing the reminder
///   - oldTitle: Current title of the reminder to update
///   - newTitle: New title (empty = keep existing)
///   - dueStr: New due date ("none"/"clear" = remove, empty = keep existing, date = set new)
///   - notesStr: New notes (empty = keep existing, merges metadata)
///   - priorityStr: New priority (empty = keep existing)
///   - locationStr: New location (empty = keep existing, "none"/"clear" = remove)
func handleUpdate(_ listName: String, oldTitle: String, newTitle: String, dueStr: String, notesStr: String, priorityStr: String, locationStr: String, tagsStr: String, store: EKEventStore, calendars: [EKCalendar]) {
    // Step 1: Find the calendar
    guard let cal = resolveReminderCalendar(listName, in: calendars) else {
        print("(error: list not found: \(listName))")
        exit(1)
    }
    
    // Step 2: Fetch the existing reminder by old title
    let predicate = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: [cal])
    var target: EKReminder?
    let sem = DispatchSemaphore(value: 0)
    
    store.fetchReminders(matching: predicate) { reminders in
        if let reminders = reminders {
            // Find exact match by title (case-insensitive)
            target = reminders.first { $0.title?.lowercased() == oldTitle.lowercased() }
        }
        sem.signal()
    }
    sem.wait()
    
    guard let reminder = target else {
        print("(error: reminder not found: \(oldTitle) in list \(listName))")
        exit(1)
    }
    
    // Step 3: Parse existing metadata from notes (for reference, though we merge later)
    let (_, _, _) = extractMetadata(from: reminder.notes)
    
    // Step 4: Parse new metadata from notesStr (if provided)
    var newLocation: String? = nil
    var newTags: String? = nil
    var cleanNewNotes: String? = nil
    
    if !notesStr.isEmpty {
        let (loc, tags, clean) = extractMetadata(from: notesStr)
        newLocation = loc
        newTags = tags
        cleanNewNotes = clean.isEmpty ? nil : clean
    }

    // Step 4b: Handle explicit tags parameter
    var clearTags = false
    if !tagsStr.isEmpty {
        if tagsStr == "none" || tagsStr == "clear" {
            clearTags = true
            newTags = ""
        } else {
            newTags = tagsStr
        }
    }
    
    // Step 4a: Handle explicit location parameter
    var clearLocation = false
    if !locationStr.isEmpty {
        if locationStr == "none" || locationStr == "clear" {
            clearLocation = true
            newLocation = nil
        } else {
            newLocation = locationStr
        }
    }
    
    // Step 5: Update title if provided
    if !newTitle.isEmpty {
        reminder.title = newTitle
    }
    
    // Step 6: Update due date
    if !dueStr.isEmpty {
        if dueStr == "none" || dueStr == "clear" {
            reminder.dueDateComponents = nil
        } else if let due = parseDueDate(dueStr) {
            reminder.dueDateComponents = makeDateComponents(due)
        } else {
            print("(error: invalid due date: \(dueStr); expected 'YYYY-MM-DD' or 'YYYY-MM-DD HH:MM' or 'none')")
            exit(1)
        }
    }
    
    // Step 7: Update notes/tags (native tags are hashtags in notes)
    if !notesStr.isEmpty || !tagsStr.isEmpty {
        reminder.notes = mergeMetadata(oldNotes: reminder.notes, newNotes: cleanNewNotes, newTags: newTags, clearTags: clearTags)
    }

    // Step 7a: Update native location alarm
    if !locationStr.isEmpty || (!notesStr.isEmpty && newLocation != nil) {
        if clearLocation {
            removeLocationAlarms(reminder)
        } else if let loc = newLocation, !loc.isEmpty {
            setNativeLocation(reminder, locationTitle: loc)
        }
    }
    
    // Step 8: Update priority if provided
    if !priorityStr.isEmpty {
        guard let p = Int(priorityStr), p >= 0, p <= 9 else {
            print("(error: invalid priority: \(priorityStr); expected 0-9)")
            exit(1)
        }
        reminder.priority = p
    }
    
    // Step 9: Save the updated reminder (no duplicate creation)
    do {
        try store.save(reminder, commit: true)
        print("Reminder updated: \(oldTitle)")
    } catch {
        print("(error: could not update reminder: \(error))")
        exit(1)
    }
}

/// Bulk update ALL incomplete reminders in a list.
///
/// - dueStr: empty = keep, "none"/"clear" = remove, otherwise set.
/// - notesStr: empty = keep (unless locationStr set/cleared), otherwise merge into notes.
/// - locationStr: empty = keep, "none"/"clear" = remove, otherwise set.
func handleBulkUpdate(_ listName: String, dueStr: String, notesStr: String, priorityStr: String, locationStr: String, tagsStr: String, store: EKEventStore, calendars: [EKCalendar], wantJson: Bool) {
    guard let cal = resolveReminderCalendar(listName, in: calendars) else {
        print("(error: list not found: \(listName))")
        exit(1)
    }

    let predicate = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: [cal])
    var results: [EKReminder] = []
    let sem = DispatchSemaphore(value: 0)
    store.fetchReminders(matching: predicate) { reminders in
        results = reminders ?? []
        sem.signal()
    }
    sem.wait()

    if results.isEmpty {
        if wantJson {
            let out: [String: Any] = ["ok": true, "updated": 0, "list": cal.title]
            let data = try! JSONSerialization.data(withJSONObject: out, options: [])
            FileHandle.standardOutput.write(data)
            FileHandle.standardOutput.write("\n".data(using: .utf8)!)
        } else {
            print("(no incomplete reminders in list: \(cal.title))")
        }
        return
    }

    var updated = 0

    for reminder in results {
        var changed = false

        // Due date update
        if !dueStr.isEmpty {
            if dueStr == "none" || dueStr == "clear" {
                if reminder.dueDateComponents != nil {
                    reminder.dueDateComponents = nil
                    changed = true
                }
            } else if let due = parseDueDate(dueStr) {
                reminder.dueDateComponents = makeDateComponents(due)
                changed = true
            } else {
                print("(error: invalid due date: \(dueStr); expected 'YYYY-MM-DD' or 'YYYY-MM-DD HH:MM' or 'none')")
                exit(1)
            }
        }

        // Notes/location/tags update
        var newLocation: String? = nil
        var newTags: String? = nil
        var cleanNewNotes: String? = nil
        if !notesStr.isEmpty {
            let (loc, tags, clean) = extractMetadata(from: notesStr)
            newLocation = loc
            newTags = tags
            cleanNewNotes = clean.isEmpty ? nil : clean
        }

        var clearTags = false
        if !tagsStr.isEmpty {
            if tagsStr == "none" || tagsStr == "clear" {
                clearTags = true
                newTags = ""
            } else {
                newTags = tagsStr
            }
        }

        var clearLocation = false
        if !locationStr.isEmpty {
            if locationStr == "none" || locationStr == "clear" {
                clearLocation = true
                newLocation = nil
            } else {
                newLocation = locationStr
            }
        }

        // Notes/tags
        if !notesStr.isEmpty || !tagsStr.isEmpty {
            let merged = mergeMetadata(oldNotes: reminder.notes, newNotes: cleanNewNotes, newTags: newTags, clearTags: clearTags)
            if merged != (reminder.notes ?? "") {
                reminder.notes = merged
                changed = true
            }
        }

        // Native location
        if !locationStr.isEmpty || (!notesStr.isEmpty && newLocation != nil) {
            if clearLocation {
                if reminderLocationTitle(reminder) != nil {
                    removeLocationAlarms(reminder)
                    changed = true
                }
            } else if let loc = newLocation, !loc.isEmpty {
                let before = reminderLocationTitle(reminder)
                setNativeLocation(reminder, locationTitle: loc)
                if before != loc {
                    changed = true
                }
            }
        }

        // Priority update
        if !priorityStr.isEmpty {
            if let p = Int(priorityStr), p >= 0, p <= 9 {
                if reminder.priority != p {
                    reminder.priority = p
                    changed = true
                }
            } else {
                print("(error: invalid priority: \(priorityStr); expected 0-9)")
                exit(1)
            }
        }

        guard changed else { continue }
        do {
            try store.save(reminder, commit: true)
            updated += 1
        } catch {
            print("(error: could not bulk update reminder: \(error))")
            exit(1)
        }
    }

    if wantJson {
        let out: [String: Any] = ["ok": true, "updated": updated, "list": cal.title]
        let data = try! JSONSerialization.data(withJSONObject: out, options: [])
        FileHandle.standardOutput.write(data)
        FileHandle.standardOutput.write("\n".data(using: .utf8)!)
    } else {
        print("Bulk updated: \(updated) reminders in \(cal.title)")
    }
}

/// Convert legacy note metadata to native tags/locations.
/// - `[tags:...]` -> hashtags in notes
/// - `[location:...]` -> native location alarm (if not already set)
func handleNormalize(_ listName: String, store: EKEventStore, calendars: [EKCalendar], wantJson: Bool) {
    guard let cal = resolveReminderCalendar(listName, in: calendars) else {
        print("(error: list not found: \(listName))")
        exit(1)
    }

    let predicate = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: [cal])
    var reminders: [EKReminder] = []
    let sem = DispatchSemaphore(value: 0)
    store.fetchReminders(matching: predicate) { rs in
        reminders = rs ?? []
        sem.signal()
    }
    sem.wait()

    var updated = 0
    for r in reminders {
        let (legacyLoc, legacyTags, cleanNotes) = extractMetadata(from: r.notes)
        let normalizedNotes = mergeMetadata(oldNotes: nil, newNotes: cleanNotes.isEmpty ? nil : cleanNotes, newTags: legacyTags)

        var changed = false
        if normalizedNotes != (r.notes ?? "") {
            r.notes = normalizedNotes.isEmpty ? nil : normalizedNotes
            changed = true
        }

        if reminderLocationTitle(r) == nil, let loc = legacyLoc, !loc.isEmpty {
            setNativeLocation(r, locationTitle: loc)
            changed = true
        }

        guard changed else { continue }
        do {
            try store.save(r, commit: true)
            updated += 1
        } catch {
            print("(error: could not normalize reminder: \(error))")
            exit(1)
        }
    }

    if wantJson {
        let out: [String: Any] = ["ok": true, "updated": updated, "list": cal.title]
        let data = try! JSONSerialization.data(withJSONObject: out, options: [])
        FileHandle.standardOutput.write(data)
        FileHandle.standardOutput.write("\n".data(using: .utf8)!)
    } else {
        print("Normalized: \(updated) reminders in \(cal.title)")
    }
}

/// Remove native tags (hashtags) and legacy `[tags:...]` blocks from notes.
///
/// This does not delete the reminder; it only cleans the notes field.
func handleStripTags(_ listName: String, title: String?, store: EKEventStore, calendars: [EKCalendar], wantJson: Bool) {
    guard let cal = resolveReminderCalendar(listName, in: calendars) else {
        print("(error: list not found: \(listName))")
        exit(1)
    }

    let predicate = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: [cal])
    var reminders: [EKReminder] = []
    let sem = DispatchSemaphore(value: 0)
    store.fetchReminders(matching: predicate) { rs in
        reminders = rs ?? []
        sem.signal()
    }
    sem.wait()

    if let t = title, !t.isEmpty {
        reminders = reminders.filter { ($0.title ?? "").lowercased() == t.lowercased() }
    }

    var updated = 0
    for r in reminders {
        let (_, _, cleanNotes) = extractMetadata(from: r.notes)
        let newNotes = cleanNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        let old = (r.notes ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if newNotes == old { continue }
        r.notes = newNotes.isEmpty ? nil : newNotes
        do {
            try store.save(r, commit: true)
            updated += 1
        } catch {
            print("(error: could not strip tags: \(error))")
            exit(1)
        }
    }

    if wantJson {
        let out: [String: Any] = ["ok": true, "updated": updated, "list": cal.title]
        let data = try! JSONSerialization.data(withJSONObject: out, options: [])
        FileHandle.standardOutput.write(data)
        FileHandle.standardOutput.write("\n".data(using: .utf8)!)
    } else {
        if let t = title, !t.isEmpty {
            print("Stripped tags: \(updated) reminders in \(cal.title) (title match: \(t))")
        } else {
            print("Stripped tags: \(updated) reminders in \(cal.title)")
        }
    }
}

func handleComplete(_ listName: String, title: String, store: EKEventStore, calendars: [EKCalendar]) {
    guard let cal = resolveReminderCalendar(listName, in: calendars) else {
        print("List not found: \(listName)")
        exit(1)
    }
    
    let predicate = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: [cal])
    var target: EKReminder?
    let sem = DispatchSemaphore(value: 0)
    
    store.fetchReminders(matching: predicate) { reminders in
        if let reminders = reminders {
            target = reminders.first { $0.title?.lowercased() == title.lowercased() }
        }
        sem.signal()
    }
    sem.wait()
    
    guard let reminder = target else {
        print("Reminder not found: \(title)")
        exit(1)
    }
    
    reminder.isCompleted = true
    
    do {
        try store.save(reminder, commit: true)
        print("Reminder completed: \(title)")
    } catch {
        print("(error: could not complete reminder: \(error))")
        exit(1)
    }
}

func handleRename(_ oldName: String, newName: String, store: EKEventStore, calendars: [EKCalendar]) {
    guard let cal = resolveReminderCalendar(oldName, in: calendars) else {
        print("List not found: \(oldName)")
        exit(1)
    }
    
    // Check if new name already exists
    if let _ = findCalendar(newName, in: calendars) {
        print("(error: list '\(newName)' already exists)")
        exit(1)
    }
    
    cal.title = newName
    do {
        try store.saveCalendar(cal, commit: true)
        print("List renamed: '\(oldName)' → '\(newName)'")
    } catch {
        print("(error: could not rename list: \(error))")
        exit(1)
    }
}

func handleSearch(_ query: String, store: EKEventStore, calendars: [EKCalendar], wantJson: Bool) {
    let predicate = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: calendars)
    var results: [EKReminder] = []
    let sem = DispatchSemaphore(value: 0)
    
    store.fetchReminders(matching: predicate) { reminders in
        if let reminders = reminders {
            let lowerQuery = query.lowercased()
            results = reminders.filter { ($0.title ?? "").lowercased().contains(lowerQuery) }
                .sorted { ($0.dueDateComponents?.date ?? Date.distantFuture) < ($1.dueDateComponents?.date ?? Date.distantFuture) }
        }
        sem.signal()
    }
    sem.wait()
    
    if wantJson {
        let items = results.map { r -> [String: Any] in
            var dict: [String: Any] = ["title": r.title ?? "", "list": r.calendar?.title ?? ""]
            let due = formatDue(r.dueDateComponents)
            if !due.isEmpty { dict["due"] = due }
            
            let (_, tags, cleanNotes) = extractMetadata(from: r.notes)
            if !cleanNotes.isEmpty { dict["notes"] = cleanNotes }
            if let location = resolvedLocation(for: r), !location.isEmpty { dict["location"] = location }
            if let tags = tags, !tags.isEmpty { dict["tags"] = tags }
            if r.priority > 0 { dict["priority"] = r.priority }
            return dict
        }
        toJson(items)
    } else {
        for r in results {
            print(formatReminder(r, wantJson: false))
        }
    }
}

func handleSearchTag(_ tag: String, store: EKEventStore, calendars: [EKCalendar], wantJson: Bool) {
    let predicate = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: calendars)
    var results: [EKReminder] = []
    let sem = DispatchSemaphore(value: 0)
    
    store.fetchReminders(matching: predicate) { reminders in
        if let reminders = reminders {
            results = reminders.filter { reminder in
                guard let notes = reminder.notes else { return false }
                let (_, tags, _) = extractMetadata(from: notes)
                guard let tags = tags else { return false }
                let tagList = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
                return tagList.contains(tag.lowercased())
            }.sorted { ($0.dueDateComponents?.date ?? Date.distantFuture) < ($1.dueDateComponents?.date ?? Date.distantFuture) }
        }
        sem.signal()
    }
    sem.wait()
    
    if wantJson {
        let items = results.map { r -> [String: Any] in
            var dict: [String: Any] = ["title": r.title ?? "", "list": r.calendar?.title ?? ""]
            let due = formatDue(r.dueDateComponents)
            if !due.isEmpty { dict["due"] = due }
            
            let (_, tags, cleanNotes) = extractMetadata(from: r.notes)
            if !cleanNotes.isEmpty { dict["notes"] = cleanNotes }
            if let location = resolvedLocation(for: r), !location.isEmpty { dict["location"] = location }
            if let tags = tags, !tags.isEmpty { dict["tags"] = tags }
            if r.priority > 0 { dict["priority"] = r.priority }
            return dict
        }
        toJson(items)
    } else {
        for r in results {
            print(formatReminder(r, wantJson: false))
        }
    }
}

func handleAddTags(_ listName: String, title: String, tags: String, store: EKEventStore, calendars: [EKCalendar]) {
    guard let cal = resolveReminderCalendar(listName, in: calendars) else {
        print("List not found: \(listName)")
        exit(1)
    }
    
    let reminder = EKReminder(eventStore: store)
    reminder.calendar = cal
    reminder.title = title
    let note = mergeMetadata(oldNotes: nil, newNotes: nil, newTags: tags)
    if !note.isEmpty { reminder.notes = note }
    
    do {
        try store.save(reminder, commit: true)
        print("Reminder with tags added: \(title)")
    } catch {
        print("(error: could not add reminder: \(error))")
        exit(1)
    }
}

// MARK: - Main Entry Point

let store = EKEventStore()
let sem = DispatchSemaphore(value: 0)

// Use the newer API if available (macOS 14+), fall back to old API
if #available(macOS 14.0, *) {
    store.requestFullAccessToReminders { granted, error in
        if !granted {
            print("(error: access to Reminders denied)")
            exit(1)
        }
        sem.signal()
    }
} else {
    store.requestAccess(to: .reminder) { granted, error in
        if !granted {
            print("(error: access to Reminders denied)")
            exit(1)
        }
        sem.signal()
    }
}
sem.wait()

let calendars = store.calendars(for: .reminder)

// Parse arguments
var args = CommandLine.arguments
args.removeFirst() // Remove script name

var wantJson = false
if let jsonIdx = args.firstIndex(of: "--json") {
    wantJson = true
    args.remove(at: jsonIdx)
}

guard args.count > 0 else {
    print("Usage: apple-reminders-fast.swift [--json] <overdue|today|all|list <name>|scheduled|flagged|add|update|bulk-update|normalize|strip-tags|complete|rename|search|search-tag|add-tags>")
    exit(1)
}

let command = args[0]

switch command {
case "overdue":
    handleOverdue(store: store, calendars: calendars, wantJson: wantJson)
    
case "today":
    handleToday(store: store, calendars: calendars, wantJson: wantJson)
    
case "all":
    handleAll(store: store, calendars: calendars, wantJson: wantJson)
    
case "scheduled":
    handleScheduled(store: store, calendars: calendars, wantJson: wantJson)
    
case "flagged":
    handleFlagged(store: store, calendars: calendars, wantJson: wantJson)
    
case "list":
    guard args.count > 1 else {
        print("Usage: list <name>")
        exit(1)
    }
    handleList(args[1], store: store, calendars: calendars, wantJson: wantJson)
    
case "add":
    guard args.count >= 3 else {
        print("Usage: add <list> <title> [due] [notes] [priority] [location] [tags]")
        exit(1)
    }
    let listName = args[1]
    let title = args[2]
    let dueStr = args.count > 3 ? args[3] : ""
    let notesStr = args.count > 4 ? args[4] : ""
    let priorityStr = args.count > 5 ? args[5] : ""
    let locationStr = args.count > 6 ? args[6] : ""
    let tagsStr = args.count > 7 ? args[7] : ""
    handleAdd(listName, title: title, dueStr: dueStr, notesStr: notesStr, priorityStr: priorityStr, locationStr: locationStr, tagsStr: tagsStr, store: store, calendars: calendars)
    
case "update":
    guard args.count >= 3 else {
        print("Usage: update <list> <old_title> [new_title] [due] [notes] [priority] [location] [tags]")
        exit(1)
    }
    let listName = args[1]
    let oldTitle = args[2]
    let newTitle = args.count > 3 ? args[3] : ""
    let dueStr = args.count > 4 ? args[4] : ""
    let notesStr = args.count > 5 ? args[5] : ""
    let priorityStr = args.count > 6 ? args[6] : ""
    let locationStr = args.count > 7 ? args[7] : ""
    let tagsStr = args.count > 8 ? args[8] : ""
    handleUpdate(listName, oldTitle: oldTitle, newTitle: newTitle, dueStr: dueStr, notesStr: notesStr, priorityStr: priorityStr, locationStr: locationStr, tagsStr: tagsStr, store: store, calendars: calendars)

case "bulk-update":
    guard args.count >= 2 else {
        print("Usage: bulk-update <list> [due] [notes] [priority] [location] [tags]")
        exit(1)
    }
    let listName = args[1]
    let dueStr = args.count > 2 ? args[2] : ""
    let notesStr = args.count > 3 ? args[3] : ""
    let priorityStr = args.count > 4 ? args[4] : ""
    let locationStr = args.count > 5 ? args[5] : ""
    let tagsStr = args.count > 6 ? args[6] : ""
    handleBulkUpdate(listName, dueStr: dueStr, notesStr: notesStr, priorityStr: priorityStr, locationStr: locationStr, tagsStr: tagsStr, store: store, calendars: calendars, wantJson: wantJson)

case "normalize":
    guard args.count >= 2 else {
        print("Usage: normalize <list>")
        exit(1)
    }
    handleNormalize(args[1], store: store, calendars: calendars, wantJson: wantJson)

case "strip-tags":
    guard args.count >= 2 else {
        print("Usage: strip-tags <list> [title]")
        exit(1)
    }
    let listName = args[1]
    let title = args.count > 2 ? args[2] : nil
    handleStripTags(listName, title: title, store: store, calendars: calendars, wantJson: wantJson)
    
case "complete":
    guard args.count >= 3 else {
        print("Usage: complete <list> <title>")
        exit(1)
    }
    handleComplete(args[1], title: args[2], store: store, calendars: calendars)
    
case "rename":
    guard args.count >= 3 else {
        print("Usage: rename <old_name> <new_name>")
        exit(1)
    }
    handleRename(args[1], newName: args[2], store: store, calendars: calendars)
    
case "search":
    guard args.count >= 2 else {
        print("Usage: search <query>")
        exit(1)
    }
    handleSearch(args[1], store: store, calendars: calendars, wantJson: wantJson)
    
case "search-tag":
    guard args.count >= 2 else {
        print("Usage: search-tag <tag>")
        exit(1)
    }
    handleSearchTag(args[1], store: store, calendars: calendars, wantJson: wantJson)

    
case "add-tags":
    guard args.count >= 4 else {
        print("Usage: add-tags <list> <title> <tags>")
        exit(1)
    }
    handleAddTags(args[1], title: args[2], tags: args[3], store: store, calendars: calendars)
    
default:
    print("Unknown command: \(command)")
    print("Usage: apple-reminders-fast.swift [--json] <overdue|today|all|list <name>|scheduled|flagged|add|update|bulk-update|normalize|strip-tags|complete|rename|search|search-tag|add-tags>")
    exit(1)
}
