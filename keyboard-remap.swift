// Listedeki harici klavyeler her bağlandığında sağ Cmd'yi Option'a çevirir (Windows AltGr alışkanlığı: sağ Cmd + 7 = {).
// Sol Cmd ve Option olduğu gibi kalır. MacBook'un kendi klavyesi etkilenmez.
import Foundation
import IOKit

struct Keyboard {
    let name: String
    let vendorID: Int
    let productID: Int
    var matching: String { "{\"VendorID\":\(vendorID),\"ProductID\":\(productID)}" }
}

let keyboards = [
    Keyboard(name: "NuPhy Air75 V2", vendorID: 0x19F5, productID: 0x3246),
    Keyboard(name: "MX Keys S", vendorID: 0x046D, productID: 0xB378),
]
// 0x7000000E7 = sağ Cmd (Right GUI)  -> 0x7000000E6 = sağ Option (Right Alt)
let mapping = "{\"UserKeyMapping\":[{\"HIDKeyboardModifierMappingSrc\":0x7000000E7,\"HIDKeyboardModifierMappingDst\":0x7000000E6}]}"

setvbuf(stdout, nil, _IOLBF, 0)

func log(_ msg: String) {
    print("\(ISO8601DateFormatter().string(from: Date())) \(msg)")
}

func hidutil(_ args: [String]) -> String {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/hidutil")
    p.arguments = args
    let pipe = Pipe()
    p.standardOutput = pipe
    p.standardError = FileHandle.nullDevice
    guard (try? p.run()) != nil else { return "" }
    let out = pipe.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    return String(decoding: out, as: UTF8.self)
}

// Klavye yeni bağlandığında HID servisi biraz gecikmeli oluşur; eşleme oturana kadar tekrar dene.
func applyMapping(_ kb: Keyboard, attempt: Int = 1) {
    _ = hidutil(["property", "--matching", kb.matching, "--set", mapping])
    let current = hidutil(["property", "--matching", kb.matching, "--get", "UserKeyMapping"])
    if current.contains("HIDKeyboardModifierMappingSrc") && !current.contains("(null)") {
        log("\(kb.name): eşleme uygulandı (deneme \(attempt))")
    } else if attempt < 20 {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { applyMapping(kb, attempt: attempt + 1) }
    } else {
        log("\(kb.name): eşleme uygulanamadı")
    }
}

func drain(_ iterator: io_iterator_t) -> Bool {
    var found = false
    var service = IOIteratorNext(iterator)
    while service != 0 {
        found = true
        IOObjectRelease(service)
        service = IOIteratorNext(iterator)
    }
    return found
}

let port = IONotificationPortCreate(kIOMainPortDefault)!
CFRunLoopAddSource(CFRunLoopGetMain(), IONotificationPortGetRunLoopSource(port).takeUnretainedValue(), .defaultMode)

log("İzleyici başladı")
var iterators: [io_iterator_t] = []
for (index, kb) in keyboards.enumerated() {
    let dict = IOServiceMatching("IOHIDDevice") as NSMutableDictionary
    dict["IOPropertyMatch"] = ["VendorID": kb.vendorID, "ProductID": kb.productID]
    var iterator: io_iterator_t = 0
    // Geri çağırma C fonksiyonu olduğu için klavyenin sırası refCon ile taşınır.
    IOServiceAddMatchingNotification(port, kIOFirstMatchNotification, dict, { refCon, it in
        let kb = keyboards[Int(bitPattern: refCon) - 1]
        if drain(it) {
            log("\(kb.name) bağlandı")
            applyMapping(kb)
        }
    }, UnsafeMutableRawPointer(bitPattern: index + 1), &iterator)
    iterators.append(iterator)
    if drain(iterator) { applyMapping(kb) }
}
CFRunLoopRun()
