Make sure you have gstreamer and valac installed:
```
  apt install libgstreamer1.0-dev valac
```

Then build the app by doing:
```
make
```


We are trying to add a watch to dtmfdetect bus but it fails:

```
takeshi:dtmf_generation_and_detection$ ./test

(test:145876): GStreamer-CRITICAL **: 17:21:59.531: gst_bus_create_watch: assertion 'bus->priv->poll != NULL' failed

(test:145876): GStreamer-CRITICAL **: 17:21:59.531: Creating bus watch failed
state changed: GST_STATE_NULL->GST_STATE_READY:GST_STATE_VOID_PENDING
```


Others are also getting into this issue:
    https://stackoverflow.com/questions/32248148/intercepting-bus-messages-in-gstreamer-plugin

