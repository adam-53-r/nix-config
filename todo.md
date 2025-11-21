# To-Do List
1. Fix boot snapshot
    Snapper snapshots the root subvolume at each boot, problem is that it snapshots the root subvolume after its wiped and regenerated, thus useless.
    The idea is to snapshot the root subvolume BEFORE it gets wiped at boot so you can recover wiped data afterwards that you maybe forgot to save in a persistance path.
