import SwiftUI

struct EventCard: View {
    let event: Response.Event
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }
    
    private var startTime: String {
        timeFormatter.string(from: event.from)
    }
    
    private var endTime: String {
        timeFormatter.string(from: event.to)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title and Course Section
            VStack(alignment: .leading, spacing: 5) {
                Text(event.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.onSurface)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(event.courseName)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.onSurface.opacity(0.7))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer(minLength: 12)
            
            // Bottom section with details and time
            HStack(alignment: .center, spacing: 0) {
                // Left side - Location and Teacher
                HStack(spacing: 16) {
                    // Location
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 14))
                            .foregroundColor(.onSurface.opacity(0.7))
                        
                        Text(event.locations.first?.id.capitalized ?? NSLocalizedString("Unknown", comment: ""))
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.onSurface.opacity(0.7))
                            .lineLimit(1)
                    }
                    
                    // Teacher
                    HStack(spacing: 6) {
                        Image(systemName: "person")
                            .font(.system(size: 14))
                            .foregroundColor(.onSurface.opacity(0.7))
                        
                        Text(teacherDisplayName)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.onSurface.opacity(0.7))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Right side - Time chip
                TimeRangeChip(
                    startTime: startTime,
                    color: event.color,
                    endTime: endTime,
                    isSpecial: event.isSpecial
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
    
    private var teacherDisplayName: String {
        guard let teacher = event.teachers.first else {
            return NSLocalizedString("No teachers listed", comment: "")
        }
        
        let fullName = [teacher.firstName, teacher.lastName]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        
        if fullName.isEmpty {
            return NSLocalizedString("No teachers listed", comment: "")
        }
        
        let nameParts = fullName.trimmingCharacters(in: .whitespaces)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        
        guard let lastName = nameParts.last else { return fullName }
        
        let abbreviated: String
        switch nameParts.count {
        case 3...:
            // Abbreviate all except the last name
            let shortened = nameParts.dropLast().map { String($0.prefix(1)).uppercased() + "." }.joined(separator: " ")
            abbreviated = "\(shortened) \(lastName)"
            
        case 2:
            let (first, last) = (nameParts[0], nameParts[1])
            abbreviated = "\(first) \(last)"
            
        default:
            abbreviated = fullName
        }
        
        // Fallback if still too long
        if abbreviated.count > 20 {
            let shortened = nameParts.dropLast().map { String($0.prefix(1)).uppercased() + "." }.joined(separator: " ")
            return "\(shortened) \(lastName)"
        }
        
        return abbreviated
    }
}

struct TimeRangeChip: View {
    let startTime: String
    let color: Color
    let endTime: String
    let isSpecial: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            Text("\(startTime) - \(endTime)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(textColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(backgroundColor)
        .cornerRadius(8)
    }
    
    private var backgroundColor: Color {
        if isSpecial {
            return Color.red.opacity(0.12)
        } else {
            return textColor.opacity(0.12)
        }
    }
    
    private var textColor: Color {
        if isSpecial {
            return Color.red
        } else {
            return color
        }
    }
}
