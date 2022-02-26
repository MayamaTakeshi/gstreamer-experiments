using Gst;
using GLib;

void main (string[] args) {
    // Initializing GStreamer
    Gst.init (ref args);

    // Creating pipeline and elements
    var pipeline = new Pipeline ("test");
    dynamic Element src1 = ElementFactory.make ("audiotestsrc", "my_src1");
    dynamic Element src2 = ElementFactory.make ("audiotestsrc", "my_src2");
    var sink = ElementFactory.make ("autoaudiosink", "my_sink");

    var src = src1;

    // Adding elements to pipeline
    pipeline.add_many (src1, sink);
    pipeline.add(src2);
    pipeline.remove(src2);

    // Linking source to sink
    src.link (sink);
    src.unlink (sink);
    src.link (sink);

    // Setting waveform to square
    src1.set ("wave", 1);
    src2.set ("wave", 2);

    // Set pipeline state to PLAYING
    pipeline.set_state (State.PLAYING);

    GLib.Timeout.add(500, () => {
        stdout.printf("timeout p1\n");
        pipeline.set_state (State.READY);
        src.unlink(sink);
        pipeline.remove(src);
        if (src == src1) {
            src = src2;
        } else {
            src = src1;
        }
        pipeline.add(src);
        src.link(sink);

        pipeline.set_state (State.PLAYING);

        stdout.printf("timeout p2\n");
        return true;
    });

    // Creating and starting a GLib main loop

    MainLoop loop = new MainLoop (); 

    Bus bus = pipeline.get_bus ();
    bus.add_watch (1, (bus, message) => {
        switch (message.type) {
        case MessageType.ERROR:
            GLib.Error err;
            string debug;
            message.parse_error (out err, out debug);
            stdout.printf ("Error: %s\n", err.message);
            loop.quit ();
            break;
        case MessageType.EOS:
            stdout.printf ("end of stream\n");
            break;
        case MessageType.STATE_CHANGED:
            Gst.State oldstate;
            Gst.State newstate;
            Gst.State pending;
            message.parse_state_changed (out oldstate, out newstate,
                                         out pending);
            stdout.printf ("state changed: %s->%s:%s\n",
                           oldstate.to_string (), newstate.to_string (),
                           pending.to_string ());
            break;
        case MessageType.TAG:
            Gst.TagList tag_list;
            stdout.printf ("taglist found\n");
            message.parse_tag (out tag_list);
            break;
        default:
            break;
        }

        return true;
    });

    loop.run ();
}
