// ccctl: Control Center style controls for SketchyBar, for what macOS has no CLI for.
// sketchybarrc builds it into ~/.cache/sketchybar/ccctl, embedding ccctl-Info.plist
// so macOS can ask for Bluetooth access on its behalf.
//
// macOS 27 keeps AirPods listening modes and Focus behind Apple-only entitlements,
// so those aren't here.
import Foundation
import CoreAudio
import CoreGraphics
import AppKit
import IOBluetooth

func fail(_ msg: String) -> Never {
    FileHandle.standardError.write(("ccctl: " + msg + "\n").data(using: .utf8)!)
    exit(1)
}

func sym<T>(_ lib: String, _ name: String, _: T.Type) -> T {
    guard let h = dlopen(lib, RTLD_NOW), let p = dlsym(h, name) else { fail("\(name) not available") }
    return unsafeBitCast(p, to: T.self)
}

// Read a private scalar getter through KVC (boxes the result).
func kv(_ o: NSObject, _ key: String) -> Int { (o.value(forKey: key) as? NSNumber)?.intValue ?? 0 }

// MARK: brightness (DisplayServices)

// Apple displays (built-in, Studio Display, Pro Display XDR) dim through
// DisplayServices. Third-party monitors need DDC, so they list without a level.
let ds = "/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices"

func onlineDisplays() -> [CGDirectDisplayID] {
    var ids = [CGDirectDisplayID](repeating: 0, count: 16), n: UInt32 = 0
    CGGetOnlineDisplayList(16, &ids, &n)
    return Array(ids.prefix(Int(n)))
}

func readBrightness(_ id: CGDirectDisplayID) -> Int? {
    let get = sym(ds, "DisplayServicesGetBrightness", (@convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32).self)
    var b: Float = 0
    return get(id, &b) == 0 ? Int((b * 100).rounded()) : nil
}

// One line per display: id, name, brightness 0-100 or "-" when it can't be dimmed
func displays() {
    var names: [CGDirectDisplayID: String] = [:]
    for screen in NSScreen.screens {
        if let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID {
            names[id] = screen.localizedName
        }
    }
    for id in onlineDisplays() {
        let name = names[id] ?? (CGDisplayIsBuiltin(id) != 0 ? "Built-in Display" : "Display")
        print([String(id), name, readBrightness(id).map(String.init) ?? "-"].joined(separator: "\t"))
    }
}

func brightness(_ args: [String]) {
    guard let first = args.first, let id = CGDirectDisplayID(first), onlineDisplays().contains(id) else {
        fail("usage: ccctl brightness <display id> [0-100] (ids from ccctl displays)")
    }
    if args.count > 1 {
        guard let v = Float(args[1]), (0...100).contains(v) else { fail("brightness must be 0-100") }
        let set = sym(ds, "DisplayServicesSetBrightness", (@convention(c) (CGDirectDisplayID, Float) -> Int32).self)
        if set(id, v / 100) != 0 { fail("this display can't be dimmed from here") }
    } else {
        guard let level = readBrightness(id) else { fail("this display doesn't report its brightness") }
        print(level)
    }
}

// MARK: audio outputs (CoreAudio)

func addr(_ sel: AudioObjectPropertySelector, _ scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal) -> AudioObjectPropertyAddress {
    AudioObjectPropertyAddress(mSelector: sel, mScope: scope, mElement: kAudioObjectPropertyElementMain)
}

func prop(_ obj: AudioObjectID, _ sel: AudioObjectPropertySelector) -> UInt32 {
    var a = addr(sel), v: UInt32 = 0, size = UInt32(MemoryLayout<UInt32>.size)
    AudioObjectGetPropertyData(obj, &a, 0, nil, &size, &v)
    return v
}

func cfString(_ obj: AudioObjectID, _ sel: AudioObjectPropertySelector) -> String {
    var a = addr(sel), s: Unmanaged<CFString>?, size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
    guard AudioObjectGetPropertyData(obj, &a, 0, nil, &size, &s) == noErr, let s else { return "" }
    return s.takeRetainedValue() as String
}

func outputDevices() -> [AudioObjectID] {
    let sys = AudioObjectID(kAudioObjectSystemObject)
    var a = addr(kAudioHardwarePropertyDevices), size: UInt32 = 0
    AudioObjectGetPropertyDataSize(sys, &a, 0, nil, &size)
    var ids = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
    AudioObjectGetPropertyData(sys, &a, 0, nil, &size, &ids)
    return ids.filter {
        var sa = addr(kAudioDevicePropertyStreams, kAudioObjectPropertyScopeOutput), n: UInt32 = 0
        return AudioObjectGetPropertyDataSize($0, &sa, 0, nil, &n) == noErr && n > 0
    }
}

func transport(_ t: UInt32) -> String {
    switch t {
    case kAudioDeviceTransportTypeBuiltIn: return "builtin"
    case kAudioDeviceTransportTypeBluetooth, kAudioDeviceTransportTypeBluetoothLE: return "bluetooth"
    case kAudioDeviceTransportTypeAirPlay: return "airplay"
    case kAudioDeviceTransportTypeUSB: return "usb"
    default: return "other"
    }
}

func outputs() {
    let def = prop(AudioObjectID(kAudioObjectSystemObject), kAudioHardwarePropertyDefaultOutputDevice)
    for d in outputDevices() {
        let name = cfString(d, kAudioObjectPropertyName), uid = cfString(d, kAudioDevicePropertyDeviceUID)
        print([name, uid, d == def ? "1" : "0", transport(prop(d, kAudioDevicePropertyTransportType))].joined(separator: "\t"))
    }
}

func setOutput(_ uid: String) {
    guard let d = outputDevices().first(where: { cfString($0, kAudioDevicePropertyDeviceUID) == uid }) else { fail("no output device with uid \(uid)") }
    for sel in [kAudioHardwarePropertyDefaultOutputDevice, kAudioHardwarePropertyDefaultSystemOutputDevice] {
        var a = addr(sel), id = d
        let err = AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject), &a, 0, nil, UInt32(MemoryLayout<AudioObjectID>.size), &id)
        if err != noErr { fail("set default output failed (\(err))") }
    }
}

// MARK: airpods (IOBluetooth private selectors)

func airpods() {
    for d in (IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice]) ?? [] {
        // Apple vendor ID 0x004C and major class Audio/Video.
        guard kv(d, "vendorID") == 0x4C, d.deviceClassMajor == 0x04 else { continue }
        let name = d.value(forKey: "displayName") as? String ?? d.name ?? "?"
        let pct = { (key: String) -> String in kv(d, key) == 0 ? "-" : String(kv(d, key)) }
        var battery = "-"
        if d.isConnected() {
            let lrc = ["batteryPercentLeft", "batteryPercentRight", "batteryPercentCase"].map(pct)
            battery = lrc.contains { $0 != "-" } ? lrc.joined(separator: "/") : pct("batteryPercentSingle")
        }
        let addr = (d.addressString ?? "").replacingOccurrences(of: "-", with: ":").uppercased()
        print([name, addr, d.isConnected() ? "1" : "0", battery].joined(separator: "\t"))
    }
}

// MARK: bluetooth power and connecting (IOBluetooth)

let iobt = "/System/Library/Frameworks/IOBluetooth.framework/IOBluetooth"

func bluetooth(_ args: [String]) {
    let get = sym(iobt, "IOBluetoothPreferenceGetControllerPowerState", (@convention(c) () -> Int32).self)
    guard let want = args.first else { print(get() != 0 ? "on" : "off"); return }
    let set = sym(iobt, "IOBluetoothPreferenceSetControllerPowerState", (@convention(c) (Int32) -> Void).self)
    switch want {
    case "on": set(1)
    case "off": set(0)
    case "toggle": set(get() != 0 ? 0 : 1)
    default: fail("bluetooth must be on|off|toggle")
    }
}

func connect(_ address: String) {
    guard let d = IOBluetoothDevice(addressString: address) else { fail("no device \(address)") }
    if d.openConnection() != kIOReturnSuccess { fail("could not connect to \(address)") }
}

// MARK: airdrop (com.apple.sharingd DiscoverableMode)

let airdropModes = ["off": "Off", "contacts": "Contacts Only", "everyone": "Everyone"]

func airdrop(_ args: [String]) {
    let key = "DiscoverableMode" as CFString, app = "com.apple.sharingd" as CFString
    guard let want = args.first else {
        let cur = CFPreferencesCopyAppValue(key, app) as? String ?? "Contacts Only"
        print(airdropModes.first { $0.value == cur }?.key ?? "contacts")
        return
    }
    guard let v = airdropModes[want] else { fail("airdrop mode must be off|contacts|everyone") }
    CFPreferencesSetAppValue(key, v as CFString, app)
    CFPreferencesAppSynchronize(app)
    // sharingd only reads the mode at launch; launchd restarts it right away.
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
    p.arguments = ["sharingd"]
    try? p.run()
    p.waitUntilExit()
}

// MARK: media (MediaRemote)

// MediaRemote only answers platform binaries for now-playing info since macOS 15.4,
// so ask /usr/bin/perl through Apple's PerlObjCBridge.
let nowPlayingPerl = #"""
use PerlObjCBridge;
@NSBundle::ISA = @NSObject::ISA = @MRNowPlayingRequest::ISA = ('PerlObjCBridge');
NSBundle->bundleWithPath_('/System/Library/PrivateFrameworks/MediaRemote.framework')->load;
sub str { my $o = shift; return '' unless $o && $$o; my $t = $o->UTF8String; $t =~ s/[\t\n]/ /g; return $t; }
my $item = MRNowPlayingRequest->localNowPlayingItem;
exit 0 unless $item && $$item;
my $info = $item->nowPlayingInfo;
exit 0 unless $info && $$info;
my $title = str($info->objectForKey_('kMRMediaRemoteNowPlayingInfoTitle'));
exit 0 if $title eq '';
my $artist = str($info->objectForKey_('kMRMediaRemoteNowPlayingInfoArtist'));
my $path = MRNowPlayingRequest->localNowPlayingPlayerPath;
my $client = ($path && $$path) ? $path->client : undef;
my $bundle = ($client && $$client) ? str($client->bundleIdentifier) : '';
print join("\t", $title, $artist, $bundle, MRNowPlayingRequest->localIsPlaying ? 1 : 0), "\n";
"""#

func nowPlaying() {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
    p.arguments = ["-e", nowPlayingPerl]
    do { try p.run() } catch { fail("cannot run /usr/bin/perl") }
    p.waitUntilExit()
    if p.terminationStatus != 0 { exit(p.terminationStatus) }
}

func media(_ args: [String]) {
    let cmds: [String: UInt32] = ["play": 0, "pause": 1, "toggle": 2, "next": 4, "previous": 5]
    guard let a = args.first, let c = cmds[a] else { fail("media command must be play|pause|toggle|next|previous") }
    let send = sym("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", "MRMediaRemoteSendCommand",
                   (@convention(c) (UInt32, CFDictionary?) -> Bool).self)
    if !send(c, nil) { fail("MRMediaRemoteSendCommand failed") }
    // The command is delivered asynchronously; give it a moment before exiting.
    RunLoop.main.run(until: Date().addingTimeInterval(0.3))
}

// MARK: main

// TCC charges Bluetooth access to the responsible process. Re-run once with responsibility
// disclaimed so ccctl (which embeds NSBluetoothAlwaysUsageDescription) is asked, not sketchybar.
func disclaimAndRerun() {
    guard getenv("CCCTL_DISCLAIMED") == nil else { return }
    setenv("CCCTL_DISCLAIMED", "1", 1)
    typealias Disclaim = @convention(c) (UnsafeMutablePointer<posix_spawnattr_t?>, Int32) -> Int32
    guard let f = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "responsibility_spawnattrs_setdisclaim") else { return }
    var attr: posix_spawnattr_t?
    posix_spawnattr_init(&attr)
    _ = unsafeBitCast(f, to: Disclaim.self)(&attr, 1)
    var pid: pid_t = 0, status: Int32 = 0
    guard let exe = Bundle.main.executablePath,
          posix_spawn(&pid, exe, nil, &attr, CommandLine.unsafeArgv, environ) == 0 else { return }
    waitpid(pid, &status, 0)
    exit((status & 0x7f) == 0 ? (status >> 8) & 0xff : 1)
}

let args = Array(CommandLine.arguments.dropFirst())
switch args.first {
case "displays": displays()
case "brightness": brightness(Array(args.dropFirst()))
case "outputs": outputs()
case "output" where args.count == 2: setOutput(args[1])
case "airpods":
    disclaimAndRerun()
    airpods()
case "bluetooth":
    disclaimAndRerun()
    bluetooth(Array(args.dropFirst()))
case "connect" where args.count == 2:
    disclaimAndRerun()
    connect(args[1])
case "airdrop": airdrop(Array(args.dropFirst()))
case "nowplaying": nowPlaying()
case "media": media(Array(args.dropFirst()))
default:
    fail("usage: ccctl displays | brightness <display id> [0-100] | outputs | output <uid> | airpods | bluetooth [on|off|toggle] | connect <addr> | airdrop [off|contacts|everyone] | nowplaying | media play|pause|toggle|next|previous")
}
