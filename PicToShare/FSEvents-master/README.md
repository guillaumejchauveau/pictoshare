EonilFSEvents
=============================
Eonil
2018 Maintenance.
2019 Maintenance.

[![Build Status](https://api.travis-ci.org/eonil/FSEvents.svg)](https://travis-ci.org/eonil/FSEvents)

It's possible to use FSEvents directly in Swift, but it still involves
many boilerplate works and subtle conversions.

This library provides mostly-faithful wrapper around FSEvents feature tailored
for Swift 5.



Quickstart
-------------
Import.

    import EonilFSEvents

Start.

    try EonilFSEvents.startWatching( 
        paths: ["/"],
        for: ObjectIdentifier(self),
        with: { event in print(event) })

Stop.

    EonilFSEvents.stopWatching(for: ObjectIdentifier(self))



Using Full Features
-----------------------
Make a `EonilFSEventStream`, schedule it to a GCD queue, and start.

    let s = try EonilFSEventStream(pathsToWatch: paths,
        sinceWhen: .now,
        latency: 0,
        flags: [],
        handler: handler)
    s.setDispatchQueue(DispatchQueue.main)
    try s.start()

After use, deinitialize by stop, invalidate(unschedule).

    s.stop()
    s.invalidate()

As soon as the last strong reference gets removed,
the stream will be destroyed.



Caveats
----------
In the Xcode, AppKit apps are configured to use Sandbox by default.
Sandboxed apps cannot access files out of its container.
Therefore, it could look like it cannot receive file system events
out of the container. To receive file system events out of
container, you should turn off sandboxing.

At this point, `xcodebuild` fails on dependency resolution for packages.
I don't know why. It seems Xcode have some issues with it.
To work around, just set `SYMROOT` explicitly.
See `test.zsh` how to set it.



Credits & License
------------------------
Copyright(c) 2018 Hoon H., Eonil.
All rights reserved.
Use of this library is granted under "MIT License".
