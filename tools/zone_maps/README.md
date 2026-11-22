# Zone map tools

Makes the zone maps (`ZONE*_MAP.png/.svg`, `ZONES_OVERVIEW.png/.svg`) and the heightmaps in `heightmaps/`.

- `zones.py`: the layout of each zone (terrain shapes, rivers with bed heights, roads, places, area numbers).
- `terrain.py`: the shape helpers (hills, ridges, cliffs, terraces, river carving).
- `render.py`: draws the maps and writes the heightmaps.

Run (needs Python with numpy, scipy, matplotlib, pillow):
    python render.py out
Then copy the files from `out/` to the project folder. The design notes are in `ZONES_DESIGN.md`.
