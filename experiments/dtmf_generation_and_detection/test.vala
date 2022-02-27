using Gst;
using GLib;

dynamic Element createElement(string name, string id) {
    dynamic Element e = ElementFactory.make(name, id);

	if (e == null){
		stderr.printf("Couldn't create element name=%s id=%s\n", name, id);
        GLib.Process.exit(1);
	}

    return e;
}

void addToPipeline(Pipeline pipeline, Element e) {
    if(!pipeline.add(e)) {
        stderr.printf("Failed to add %s to pipeline\n", e.name);
        GLib.Process.exit(1);
    }
}

void linkElements(Element src, Element sink) {
    bool res = src.link (sink);
    if(! res) {
		stderr.printf("Couldn't link src=%s with sink=%s\n", src.name, sink.name);
        GLib.Process.exit(1);
    }
}

void main (string[] args) {
    // Initializing GStreamer
    Gst.init (ref args);

    // Creating pipeline and elements
    var pipeline = new Pipeline ("test");
    //dynamic Element filesrc  = createElement("filesrc", "filesrc");
    dynamic Element filesrc  = createElement("dtmfsrc", "dtmfsrc");
    dynamic Element decodebin = createElement ("decodebin", "decodebin");
    dynamic Element audioresample = createElement ("audioresample", "audioresample");
    dynamic Element audioconvert = createElement ("audioconvert", "audioconvert");
    dynamic Element dtmfdetect = createElement ("dtmfdetect", "dtmfdetect");
    var sink = createElement ("autoaudiosink", "my_sink");
    //var sink = createElement ("fakesink", "my_sink");

    // Adding elements to pipeline
    addToPipeline(pipeline, filesrc);
    addToPipeline(pipeline, decodebin);
    addToPipeline(pipeline, audioresample);
    addToPipeline(pipeline, audioconvert);
    addToPipeline(pipeline, dtmfdetect);
    addToPipeline(pipeline, sink);

    // Linking elements
    linkElements(filesrc, decodebin);

    decodebin.pad_added.connect((src, new_pad) => {
		Gst.Pad sink_pad = audioresample.get_static_pad ("sink");
		print ("Received new pad '%s' from '%s':\n", new_pad.name, src.name);

		// If our converter is already linked, we have nothing to do here:
		if (sink_pad.is_linked ()) {
			print ("  We are already linked. Ignoring.\n");
			return ;
		}

		// Check the new pad's type:
		Gst.Caps new_pad_caps = new_pad.query_caps (null);
		weak Gst.Structure new_pad_struct = new_pad_caps.get_structure(0);
		string new_pad_type = new_pad_struct.get_name ();
		if (!new_pad_type.has_prefix ("audio/x-raw")) {
			print ("  It has type '%s' which is not raw audio. Ignoring.\n", new_pad_type);
			return ;
		}

		// Attempt the link:
		Gst.PadLinkReturn ret = new_pad.link (sink_pad);
		if (ret != Gst.PadLinkReturn.OK) {
			print ("  Type is '%s' but link failed.\n", new_pad_type);
		} else {
			print ("  Link succeeded (type '%s').\n", new_pad_type);
		}
	});

    linkElements(audioresample, audioconvert);
    linkElements(audioconvert, dtmfdetect);
    linkElements(dtmfdetect, sink);

    filesrc.location = "./digits.wav";

    // Set pipeline state to PLAYING
    pipeline.set_state (State.PLAYING);

    // Creating and starting a GLib main loop

    MainLoop loop = new MainLoop (); 


    Bus bus = pipeline.get_bus ();
    bus.add_watch (1, (bus, message) => {
        var seqnum = message.get_seqnum();

        var src_obj = message.src;

        if (src_obj == dtmfdetect) {
            weak Gst.Structure s = message.get_structure();
            var name = s.get_name();
            if(name != "GstMessageStateChanged") {
                var type = s.get_value("type").strdup_contents();
                var number = s.get_value("number").strdup_contents();
                var method = s.get_value("method").strdup_contents();
                print("Got message #%u %s from dtmfdetect: type=%s number=%s method=%s\n", seqnum, name, type, number, method);
            }
        }

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

    var on_off = 0;
    var number = 0;

    GLib.Timeout.add(250, () => {
        //print("timeout\n");
        Gst.Structure s = new Gst.Structure.empty("dtmf-event");
        s.set_value("type", 1);
        s.set_value("number", number);
        s.set_value("volume", 25);

        if(on_off == 0) {
            s.set_value("start", true);
            on_off = 1;
        } else {
            s.set_value("start", false);
            number++;
            if(number> 15) {
                number = 0;
            }
            on_off = 0;
        }

        //stdout.printf("number=%u, on_off=%u\n", number, on_off);
        Gst.Event event = new Gst.Event.custom(Gst.EventType.CUSTOM_UPSTREAM, s.copy());
        pipeline.send_event(event);

        return true;
    });

    loop.run ();
}
