# MMN_v3
Passive auditory MMN with deviant duration  

Sequence of std and dev sounds, with at least two std between 1 dev.
Sounds are two 5ms white noise click (with 2.5ms ramping on/off) with SOA of [200 100 150 250 300]ms for [std dev1 dev2 dev3 dev4] respectively.

The sounds are created before the task start, and require the ramp_sound function.

mkTimeKeeperSpeak allows to check the timing in the results obtained.

RESULT folder is where the expMat and other variable are saved.

There is two version of the task, one for the lab and one for the train.
For the lab, there is one code for the 32 EEG device and an other for the 64 EEG.
