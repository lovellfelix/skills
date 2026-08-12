import EventKit
import Foundation

struct CalendarEvent: Codable {
  var id: String
  var calendar: String
  var start: String
  var end: String
  var title: String
  var location: String
  var notes: String
}

func eprint(_ message: String) {
  FileHandle.standardError.write((message + "\n").data(using: .utf8)!)
}

func usage() -> Never {
  eprint("Usage: apple-calendar-fast.swift [--json] <command> [args]")
  eprint("Commands:")
  eprint("  today")
  eprint("  tomorrow")
  eprint("  week")
  eprint("  range <YYYY-MM-DD> <YYYY-MM-DD>")
  eprint("  search <query>")
  eprint("  calendars")
  eprint("  add <calendar> <title> <YYYY-MM-DD HH:MM> <YYYY-MM-DD HH:MM> [location] [notes]")
  eprint("  delete <event_id>")
  eprint("  dedupe <title> <YYYY-MM-DD HH:MM> <YYYY-MM-DD HH:MM> [keep_calendar]")
  exit(2)
}

let args = Array(CommandLine.arguments.dropFirst())
var wantJson = false
var filtered: [String] = []
for a in args {
  if a == "--json" { wantJson = true }
  else { filtered.append(a) }
}

guard let command = filtered.first else { usage() }

let store = EKEventStore()
let sem = DispatchSemaphore(value: 0)
var granted = false
var accessError: Error?
if #available(macOS 14.0, *) {
  store.requestFullAccessToEvents { ok, err in
    granted = ok
    accessError = err
    sem.signal()
  }
} else {
  store.requestAccess(to: .event) { ok, err in
    granted = ok
    accessError = err
    sem.signal()
  }
}
_ = sem.wait(timeout: .now() + 10)

if !granted {
  eprint("(error: calendar access not granted)")
  if let accessError {
    eprint(String(describing: accessError))
  }
  exit(1)
}

let cal = Calendar.current
let now = Date()

let fmt = DateFormatter()
fmt.locale = Locale(identifier: "en_US_POSIX")
fmt.timeZone = TimeZone.current
fmt.dateFormat = "yyyy-MM-dd HH:mm"

func parseDateTime(_ s: String) -> Date? {
  fmt.date(from: s)
}

func startOfDay(_ d: Date) -> Date { cal.startOfDay(for: d) }

func parseDay(_ s: String) -> Date? {
  let df = DateFormatter()
  df.locale = Locale(identifier: "en_US_POSIX")
  df.timeZone = TimeZone.current
  df.dateFormat = "yyyy-MM-dd"
  return df.date(from: s).map { startOfDay($0) }
}

func fetchEvents(start: Date, end: Date) -> [EKEvent] {
  let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
  return store.events(matching: predicate)
}

func render(events: [EKEvent]) {
  let mapped: [CalendarEvent] = events
    .sorted(by: { $0.startDate < $1.startDate })
    .map { e in
      CalendarEvent(
        id: e.eventIdentifier ?? "",
        calendar: e.calendar.title,
        start: fmt.string(from: e.startDate),
        end: fmt.string(from: e.endDate),
        title: e.title ?? "",
        location: e.location ?? "",
        notes: e.notes ?? ""
      )
    }

  if wantJson {
    let enc = JSONEncoder()
    enc.outputFormatting = []
    let data = try! enc.encode(mapped)
    FileHandle.standardOutput.write(data)
    FileHandle.standardOutput.write("\n".data(using: .utf8)!)
  } else {
    for e in mapped {
      // TSV
      print([e.calendar, e.start, e.end, e.title, e.location, e.notes].joined(separator: "\t"))
    }
  }
}

switch command {
case "today":
  let start = startOfDay(now)
  let end = cal.date(byAdding: .day, value: 1, to: start)!
  render(events: fetchEvents(start: start, end: end))

case "tomorrow":
  let start = cal.date(byAdding: .day, value: 1, to: startOfDay(now))!
  let end = cal.date(byAdding: .day, value: 1, to: start)!
  render(events: fetchEvents(start: start, end: end))

case "week":
  let start = startOfDay(now)
  let end = cal.date(byAdding: .day, value: 7, to: start)!
  render(events: fetchEvents(start: start, end: end))

case "range":
  guard filtered.count >= 3 else { usage() }
  guard let start = parseDay(filtered[1]), let endStart = parseDay(filtered[2]) else {
    eprint("(error: invalid date; expected YYYY-MM-DD)")
    exit(1)
  }
  let end = cal.date(byAdding: .day, value: 1, to: endStart)!
  render(events: fetchEvents(start: start, end: end))

case "search":
  guard filtered.count >= 2 else { usage() }
  let q = filtered.dropFirst().joined(separator: " ").lowercased()
  let start = startOfDay(now)
  let end = cal.date(byAdding: .day, value: 90, to: start)!
  let evts = fetchEvents(start: start, end: end).filter { ($0.title ?? "").lowercased().contains(q) }
  render(events: evts)

case "calendars":
  let calendars = store.calendars(for: .event)
  if wantJson {
    func typeString(_ t: EKCalendarType) -> String {
      switch t {
      case .local: return "local"
      case .calDAV: return "caldav"
      case .exchange: return "exchange"
      case .subscription: return "subscription"
      case .birthday: return "birthday"
      @unknown default: return "unknown"
      }
    }

    let objs: [[String: Any]] = calendars
      .sorted(by: { $0.title < $1.title })
      .map { c in
        [
          "title": c.title,
          "identifier": c.calendarIdentifier,
          "source": c.source.title,
          "type": typeString(c.type),
          "modifiable": c.allowsContentModifications,
        ]
      }

    let data = try! JSONSerialization.data(withJSONObject: objs, options: [])
    FileHandle.standardOutput.write(data)
    FileHandle.standardOutput.write("\n".data(using: .utf8)!)
  } else {
    for c in calendars.map({ $0.title }).sorted() { print(c) }
  }

case "add":
  guard filtered.count >= 5 else { usage() }
  let calendarName = filtered[1]
  let title = filtered[2]
  let startStr = filtered[3]
  let endStr = filtered[4]
  let location = filtered.count >= 6 ? filtered[5] : ""
  let notes = filtered.count >= 7 ? filtered[6] : ""

  guard let start = parseDateTime(startStr), let end = parseDateTime(endStr) else {
    eprint("(error: invalid datetime; expected 'YYYY-MM-DD HH:MM')")
    exit(1)
  }

  let calendars = store.calendars(for: .event)
  guard let target = calendars.first(where: { $0.title == calendarName }) else {
    eprint("(error: calendar not found: \(calendarName))")
    exit(1)
  }

  guard target.allowsContentModifications else {
    eprint("(error: calendar is read-only: \(calendarName))")
    exit(1)
  }

  let event = EKEvent(eventStore: store)
  event.calendar = target
  event.title = title
  event.startDate = start
  event.endDate = end
  if !location.isEmpty { event.location = location }
  if !notes.isEmpty { event.notes = notes }

  do {
    try store.save(event, span: .thisEvent, commit: true)
  } catch {
    eprint("(error: failed to save event)")
    eprint(String(describing: error))
    exit(1)
  }

  if let id = event.eventIdentifier {
    // Verify the store can immediately see it.
    if store.event(withIdentifier: id) == nil {
      eprint("(error: event save did not persist)")
      exit(1)
    }
  }

  if wantJson {
    let out: [String: Any] = [
      "ok": true,
      "id": event.eventIdentifier ?? "",
      "calendar": calendarName,
      "title": title,
      "start": startStr,
      "end": endStr,
      "location": location,
      "notes": notes,
    ]
    let data = try! JSONSerialization.data(withJSONObject: out, options: [])
    FileHandle.standardOutput.write(data)
    FileHandle.standardOutput.write("\n".data(using: .utf8)!)
  } else {
    print("Event created: \(title)")
    if !location.isEmpty {
      print("Location: \(location)")
    }
  }

case "delete":
  guard filtered.count >= 2 else { usage() }
  let id = filtered[1]
  guard let event = store.event(withIdentifier: id) else {
    eprint("(error: event not found)")
    exit(1)
  }
  do {
    try store.remove(event, span: .thisEvent, commit: true)
  } catch {
    eprint("(error: failed to delete event)")
    eprint(String(describing: error))
    exit(1)
  }
  if wantJson {
    let out: [String: Any] = ["ok": true, "deleted": id]
    let data = try! JSONSerialization.data(withJSONObject: out, options: [])
    FileHandle.standardOutput.write(data)
    FileHandle.standardOutput.write("\n".data(using: .utf8)!)
  } else {
    print("Event deleted")
  }

case "dedupe":
  guard filtered.count >= 4 else { usage() }
  let title = filtered[1]
  let startStr = filtered[2]
  let endStr = filtered[3]
  let keepCalendar = filtered.count >= 5 ? filtered[4] : ""

  guard let start = parseDateTime(startStr), let end = parseDateTime(endStr) else {
    eprint("(error: invalid datetime; expected 'YYYY-MM-DD HH:MM')")
    exit(1)
  }

  let candidates = fetchEvents(start: start, end: end).filter { e in
    (e.title ?? "") == title && e.startDate == start && e.endDate == end
  }

  if candidates.count <= 1 {
    if wantJson {
      let out: [String: Any] = ["ok": true, "kept": candidates.count, "deleted": 0]
      let data = try! JSONSerialization.data(withJSONObject: out, options: [])
      FileHandle.standardOutput.write(data)
      FileHandle.standardOutput.write("\n".data(using: .utf8)!)
    } else {
      print("No duplicates")
    }
    exit(0)
  }

  let sorted = candidates.sorted(by: { $0.calendar.title < $1.calendar.title })
  let keep: EKEvent
  if !keepCalendar.isEmpty, let chosen = sorted.first(where: { $0.calendar.title == keepCalendar }) {
    keep = chosen
  } else {
    keep = sorted[0]
  }

  var deletedIds: [String] = []
  for e in sorted {
    if e.eventIdentifier == keep.eventIdentifier { continue }
    do {
      try store.remove(e, span: .thisEvent, commit: true)
      if let id = e.eventIdentifier { deletedIds.append(id) }
    } catch {
      // If the object vanished between fetch and delete, treat as already deleted.
      let ns = error as NSError
      if ns.domain == "EKCADErrorDomain" && ns.code == 1010 {
        continue
      }
      eprint("(error: failed to delete duplicate)")
      eprint(String(describing: error))
      exit(1)
    }
  }

  if wantJson {
    let out: [String: Any] = [
      "ok": true,
      "kept_calendar": keep.calendar.title,
      "kept_id": keep.eventIdentifier ?? "",
      "deleted_count": deletedIds.count,
      "deleted_ids": deletedIds,
    ]
    let data = try! JSONSerialization.data(withJSONObject: out, options: [])
    FileHandle.standardOutput.write(data)
    FileHandle.standardOutput.write("\n".data(using: .utf8)!)
  } else {
    print("Deleted duplicates: \(deletedIds.count)")
  }

default:
  usage()
}
