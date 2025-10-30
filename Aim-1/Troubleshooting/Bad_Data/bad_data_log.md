# Delsys & EMG missing gait cycles in one trial
SS13: `struct.SHAM1.SSV.POST.Trials.trial2` missing field `GaitCycles`

SS13: POST joint angles are swapped in trial 3 of TOL30 SSV. Probably a sensor fell off and was put back on incorrectly? See `POST.png`
    NOTE: Don't think a sensor fell off, because FV is after SSV. Maybe GaitRite is incorrect? Need to check it!

To filter EMG data:
1. NEED TO DE-MEAN THE SIGNAL
    2. Then bandpass, then rectify the signal, then low-pass to get the envelope.
Can also run a THRESHOLD FILTER (4 std. dev. from mean) AFTER rectifying, before lowpass