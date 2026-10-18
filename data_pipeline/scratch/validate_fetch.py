import json
from pathlib import Path

data = json.loads(Path('data_pipeline/data/movies_raw.json').read_text(encoding='utf-8'))
ids = [m['id'] for m in data]
dupe_ids = [i for i in set(ids) if ids.count(i) > 1]

print(f"Films charges  : {len(data)}")
print(f"IDs uniques    : {len(set(ids))}")
print(f"IDs en double  : {len(dupe_ids)} -> {dupe_ids}")
print()

# Spot-check des films avec id potentiellement suspect
for m in data:
    if m['id'] in [98, 843, 146, 147, 269, 335, 422, 423]:
        seed_title = m['_seed']['title']
        print(f"  TMDb id={m['id']:6d} | TMDb title='{m['title']}' | seed='{seed_title}'")
