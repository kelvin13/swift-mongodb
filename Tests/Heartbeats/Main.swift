import Heartbeats
import Testing

@main 
enum Main:AsyncTests
{
    static
    func run(tests:inout Tests) async
    {
        let clock:ContinuousClock = .init()
        await tests.test(name: "drift")
        {
            let t0:ContinuousClock.Instant = clock.now

            let interval:Duration = .microseconds(5000)
            let tolerance:Duration = .microseconds(2500)
            let heartbeat:Heartbeat = .init(interval: interval)

            var count:Int = 1

            heartbeats:
            for try await _:Void in heartbeat
            {
                defer
                {
                    count += 1
                }
                switch count
                {
                case 1 ..< 400:
                    //  heartbeats should not skew over time
                    let center:Duration = interval * count
                    let expected:ClosedRange<Duration> =
                        center - tolerance ... 
                        center + tolerance
                    
                    $0.assert(expected ~=? t0.duration(to: .now),
                        name: count.description)
                case _:
                    break heartbeats
                }
            }

            let t1:ContinuousClock.Instant = clock.now
            $0.assert(.milliseconds(1995) ... .milliseconds(2005) ~=? t0.duration(to: t1),
                name: "elapsed-time")
        }

        await tests.test(name: "buffered")
        {
            let t0:ContinuousClock.Instant = clock.now
            let heartbeat:Heartbeat = .init(interval: .milliseconds(250))

            // heartbeat should be buffered
            try await Task.sleep(until: t0.advanced(by: .milliseconds(375)), clock: clock)

            $0.assert(.milliseconds(370) ... .milliseconds(380) ~=? t0.duration(to: .now),
                name: "sleep")

            var last:ContinuousClock.Instant = .now
            var count:Int = 1
            heartbeats:
            for try await _:Void in heartbeat
            {
                defer
                {
                    count += 1
                    last = .now
                }
                switch count
                {
                case 1:
                    // first heartbeat should be immediately available
                    $0.assert(.milliseconds(0) ... .milliseconds(5) ~=? last.duration(to: .now),
                        name: count.description)
                case 2:
                    // second heartbeat should appear on normal schedule (not delayed)
                    $0.assert(.milliseconds(495) ... .milliseconds(505) ~=? t0.duration(to: .now),
                        name: count.description)
                case _:
                    break heartbeats
                }
            }

            let t1:ContinuousClock.Instant = clock.now

            $0.assert(.milliseconds(745) ... .milliseconds(755) ~=? t0.duration(to: t1),
                name: "elapsed-time")
        }

        await tests.test(name: "skipped")
        {
            let t0:ContinuousClock.Instant = clock.now
            let heartbeat:Heartbeat = .init(interval: .milliseconds(100))

            var last:ContinuousClock.Instant = .now
            var count:Int = 1
            heartbeats:
            for try await _:Void in heartbeat
            {
                defer
                {
                    count += 1
                    last = .now
                }
                switch count
                {
                case 1:
                    /// only one heartbeat should be buffered
                    try await Task.sleep(until: t0.advanced(by: .milliseconds(350)),
                        clock: clock)
                    $0.assert(.milliseconds(345) ... .milliseconds(355) ~=? t0.duration(to: .now),
                        name: "sleep")
                
                case 2:
                    // second heartbeat should be immediately available
                    $0.assert(.milliseconds(0) ... .milliseconds(5) ~=? last.duration(to: .now),
                        name: count.description)
                case 3:
                    // third heartbeat should appear on normal schedule (not immediate, and not delayed)
                    $0.assert(.milliseconds(395) ... .milliseconds(405) ~=? t0.duration(to: .now),
                        name: count.description)
                case _:
                    break heartbeats
                }
            }

            let t1:ContinuousClock.Instant = clock.now

            $0.assert(.milliseconds(495) ... .milliseconds(505) ~=? t0.duration(to: t1),
                name: "elapsed-time")
        }

        await tests.test(name: "manual")
        {
            let t0:ContinuousClock.Instant = clock.now
            let heartbeat:Heartbeat = .init(interval: .milliseconds(100))
                heartbeat.heart.beat()

            Task<Void, Never>.init
            {
                try? await Task.sleep(until: t0.advanced(by: .milliseconds(150)), clock: clock)
                heartbeat.heart.beat()
            }
            Task<Void, Never>.init
            {
                try? await Task.sleep(until:  t0.advanced(by: .milliseconds(250)), clock: clock)
                heartbeat.heart.stop()
            }

            var last:ContinuousClock.Instant = .now
            var count:Int = 1
            heartbeats:
            for try await _:Void in heartbeat
            {
                defer
                {
                    count += 1
                    last = .now
                }
                switch count
                {
                case 1:
                    // first heartbeat should be immediately available
                    $0.assert(.milliseconds(0) ... .milliseconds(5) ~=? last.duration(to: .now),
                        name: count.description)
                
                case 2:
                    $0.assert(.milliseconds(95) ... .milliseconds(105) ~=? last.duration(to: .now),
                        name: count.description)
                case 3:
                    // manual heartbeat should appear immediately
                    $0.assert(.milliseconds(145) ... .milliseconds(155) ~=? t0.duration(to: .now),
                        name: count.description)
                case 4:
                    // fourth (automatic) heartbeat should appear on normal schedule
                    $0.assert(.milliseconds(195) ... .milliseconds(205) ~=? t0.duration(to: .now),
                        name: count.description)
                case _:
                    // we should never get here
                    $0.assert(false, name: "termination")
                }
            }

            let t1:ContinuousClock.Instant = clock.now

            $0.assert(.milliseconds(245) ... .milliseconds(255) ~=? t0.duration(to: t1),
                name: "elapsed-time")
        }
    }
}
