import Foundation

private struct ToneEvent {
    let start: Double
    let duration: Double
    let frequencies: [Double]
    let amplitude: Double
}

private let sampleRate = 44_100

private func render(duration: Double, events: [ToneEvent]) -> [Int16] {
    let count = Int(duration * Double(sampleRate))
    var samples = Array(repeating: Float.zero, count: count)

    for event in events {
        let startSample = max(0, Int(event.start * Double(sampleRate)))
        let endSample = min(count, Int((event.start + event.duration) * Double(sampleRate)))
        guard startSample < endSample else { continue }

        for index in startSample..<endSample {
            let localTime = Double(index - startSample) / Double(sampleRate)
            let attack = min(1, localTime / 0.008)
            let release = min(1, (event.duration - localTime) / 0.045)
            let envelope = max(0, min(attack, release)) * exp(-localTime * 0.75)
            let phaseTime = Double(index) / Double(sampleRate)
            let tone = event.frequencies.enumerated().reduce(0.0) { partial, item in
                let harmonicWeight = item.offset == 0 ? 1.0 : 0.38
                return partial + sin(2 * .pi * item.element * phaseTime) * harmonicWeight
            } / max(1, Double(event.frequencies.count))
            samples[index] += Float(tone * event.amplitude * envelope)
        }
    }

    return samples.map { sample in
        let limited = max(-0.95, min(0.95, sample))
        return Int16(limited * Float(Int16.max))
    }
}

private func appendLittleEndian<T: FixedWidthInteger>(_ value: T, to data: inout Data) {
    var littleEndian = value.littleEndian
    withUnsafeBytes(of: &littleEndian) { data.append(contentsOf: $0) }
}

private func writeWave(samples: [Int16], to url: URL) throws {
    let channels: UInt16 = 1
    let bitsPerSample: UInt16 = 16
    let bytesPerSample = Int(bitsPerSample / 8)
    let dataSize = samples.count * bytesPerSample
    let byteRate = sampleRate * Int(channels) * bytesPerSample

    var data = Data()
    data.append(Data("RIFF".utf8))
    appendLittleEndian(UInt32(36 + dataSize), to: &data)
    data.append(Data("WAVE".utf8))
    data.append(Data("fmt ".utf8))
    appendLittleEndian(UInt32(16), to: &data)
    appendLittleEndian(UInt16(1), to: &data)
    appendLittleEndian(channels, to: &data)
    appendLittleEndian(UInt32(sampleRate), to: &data)
    appendLittleEndian(UInt32(byteRate), to: &data)
    appendLittleEndian(UInt16(Int(channels) * bytesPerSample), to: &data)
    appendLittleEndian(bitsPerSample, to: &data)
    data.append(Data("data".utf8))
    appendLittleEndian(UInt32(dataSize), to: &data)
    for sample in samples {
        appendLittleEndian(sample, to: &data)
    }
    try data.write(to: url, options: .atomic)
}

private let tick = ToneEvent(
    start: 0,
    duration: 0.22,
    frequencies: [740, 1_480],
    amplitude: 0.78
)

private let startEvents = [
    ToneEvent(start: 0, duration: 0.18, frequencies: [990, 1_485], amplitude: 0.82),
    ToneEvent(start: 0.22, duration: 0.58, frequencies: [1_320, 1_980], amplitude: 0.88)
]

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "DamSetApp/Resources")
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

private let countdownEvents = [
    tick,
    ToneEvent(start: 1, duration: tick.duration, frequencies: tick.frequencies, amplitude: tick.amplitude),
    ToneEvent(start: 2, duration: tick.duration, frequencies: tick.frequencies, amplitude: tick.amplitude)
] + startEvents.map {
    ToneEvent(
        start: $0.start + 3,
        duration: $0.duration,
        frequencies: $0.frequencies,
        amplitude: $0.amplitude
    )
}

try writeWave(
    samples: render(duration: 3.9, events: countdownEvents),
    to: outputDirectory.appendingPathComponent("RestCountdown.wav")
)
try writeWave(
    samples: render(duration: 0.32, events: [tick]),
    to: outputDirectory.appendingPathComponent("RestTick.wav")
)
try writeWave(
    samples: render(duration: 0.9, events: startEvents),
    to: outputDirectory.appendingPathComponent("RestStart.wav")
)
