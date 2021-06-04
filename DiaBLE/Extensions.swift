import Foundation
import CryptoKit


extension Data {
    var hex: String { self.reduce("", { $0 + String(format: "%02x", $1)}) }
    var string: String { String(decoding: self, as: UTF8.self) }
    var hexAddress: String { String(self.reduce("", { $0 + $1.hex + ":"}).dropLast(1)) }
    var sha1: String { Insecure.SHA1.hash(data: self).makeIterator().reduce("", { $0 + String(format: "%02x", $1)}) }

    func hexDump(header: String = "", address: Int = -1, startingBlock: Int = -1, escaping: Bool = false) -> String {
        var offset = startIndex
        var offsetEnd = offset
        var str = (header.isEmpty || escaping == true) ? "" : "\(header)\n"
        while offset < endIndex {
            _ = formIndex(&offsetEnd, offsetBy: 8, limitedBy: endIndex)
            if address != -1 { str += (address + offset).hex + " "}
            if startingBlock != -1 { str += "#\(((startingBlock + offset) / 8).hex) " }
            if address != -1 || startingBlock != -1 { str += " " }
            str += "\(self[offset ..< offsetEnd].reduce("", { $0 + $1.hex + " "}))"
            str += String(repeating: "   ", count: 8 - distance(from: offset, to: offsetEnd))
            str += "\(self[offset ..< offsetEnd].reduce(" ", { $0 + ((isprint(Int32($1)) != 0) ? String(Unicode.Scalar($1)) : "." ) }))\n"
            _ = formIndex(&offset, offsetBy: 8, limitedBy: endIndex)
        }
        str.removeLast()
        if escaping {
            return str.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "\\n")
        }
        return str
    }

    var crc16: UInt16 {
        var crc: UInt32 = 0xffff
        for byte in self {
            for i in 0...7 {
                crc <<= 1
                if ((crc >> 16) & 1) ^ (UInt32(byte >> i) & 1) == 1 {
                    crc ^= 0x1021
                }
            }
        }
        return UInt16(crc & 0xffff)
    }

}


extension UInt8 {
    var hex: String { String(format: "%.2X", self) }
}


extension UInt16 {
    init(_ high: UInt8, _ low: UInt8) {
        self = UInt16(high) << 8 + UInt16(low)
    }

    /// init from bytes[low...high]
    init(_ bytes: [UInt8]) {
        self = UInt16(bytes[bytes.startIndex + 1]) << 8 + UInt16(bytes[bytes.startIndex])
    }

    /// init from data[low...high]
    init(_ data: Data) {
        self = UInt16(data[data.startIndex + 1]) << 8 + UInt16(data[data.startIndex])
    }

    var hex: String { String(format: "%04x", self) }
}


extension String {
    var base64: String? { self.data(using: .utf8)?.base64EncodedString() }
    var base64Data: Data? { Data(base64Encoded: self) }
    var sha1: String { self.data(using: .ascii)!.sha1 }

    var bytes: [UInt8] {
        var bytes = [UInt8]()
        if !self.contains(" ") {
            var offset = self.startIndex
            while offset < self.endIndex {
                let hex = self[offset...index(after: offset)]
                bytes.append(UInt8(hex, radix: 16)!)
                formIndex(&offset, offsetBy: 2)
            }
        } else {
            /// Convert hexDump() output
            for line in self.split(separator: "\n") {
                let column = line.contains("  ") ? line.components(separatedBy: "  ")[1] : String(line)
                for hex in column.split(separator: " ").suffix(8) {
                    bytes.append(UInt8(hex, radix: 16)!)
                }
            }
        }
        return bytes
    }

    func matches(_ pattern: String) -> Bool {
        self.split(separator: " ").contains { substring in
            pattern.split(separator: " ").contains { substring.lowercased().contains($0.lowercased()) }
        }
    }
}


extension Double {
    var units: String {
        UserDefaults.standard.bool(forKey: "displayingMillimoles") ?
            String(format: "%.1f", self / 18.0182) : String(format: "%.0f", self)
    }
}


extension Int {
    var hex: String { String(format: "%.2x", self) }
    var units: String {
        UserDefaults.standard.bool(forKey: "displayingMillimoles") ?
            String(format: "%.1f", Double(self) / 18.0182) : String(self)
    }
    var formattedInterval: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: TimeInterval(self * 60))!
    }
    var shortFormattedInterval: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day]
        formatter.unitsStyle = .short
        let days = formatter.string(from: TimeInterval(self * 60))!
        formatter.allowedUnits = [.hour]
        formatter.unitsStyle = .abbreviated
        let hours = formatter.string(from: TimeInterval((self * 60) % 86400))!
        return "\(days) \(hours)"
    }
}


extension Date {
    var shortTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return formatter.string(from: self)
    }
    var shortDateTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM-dd HH:mm"
        return formatter.string(from: self)
    }
    var dateTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM-dd HH:mm:ss"
        return formatter.string(from: self)
    }
    var local: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withFullTime, .withDashSeparatorInDate, .withColonSeparatorInTime, .withSpaceBetweenDateAndTime, .withColonSeparatorInTimeZone]
        formatter.timeZone = TimeZone.current
        return formatter.string(from: self)
    }
}


protocol Logging {
    var main: MainDelegate! { get set }
}

extension Logging {
    func log(_ msg: String) {
        if main != nil { main.log(msg) }
    }
    func debugLog(_ msg: String) {
        if main != nil { main.debugLog(msg) }
    }
}
