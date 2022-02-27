Make sure you have gstreamer and valac installed:
```
  apt install libgstreamer1.0-dev valac
```

Then build the app by doing:
```
make
```

Obs: you can igonre these warnings:
```
takeshi:dtmf_generation_and_detection$ make
valac -g --pkg gstreamer-1.0 test.vala
test.vala: In function ‘__lambda5_’:
test.vala:104:10: warning: assignment discards ‘const’ qualifier from pointer target type [-Wdiscarded-qualifiers]
             if(message.get_structure().get_name() != "GstMessageStateChanged") {
          ^
test.vala:105:11: warning: assignment discards ‘const’ qualifier from pointer target type [-Wdiscarded-qualifiers]
                 weak Gst.Structure s = message.get_structure();
           ^
takeshi:dtmf_generation_and_detection$
```

Obs: tests with RFC2833 are not working (only InBand digits are being detected)
