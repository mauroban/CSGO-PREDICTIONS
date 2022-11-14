from datetime import datetime
import itertools


all_maps = ['Inferno', 'Mirage', 'Overpass', 'Dust2', 'Ancient', 'Vertigo', 'Nuke']
for i in itertools.combinations(all_maps, 3):
    print(i)