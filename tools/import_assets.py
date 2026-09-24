"""Importa gli sprite dai pacchetti CC0 "Superpowers Asset Packs" (Pixel-boy,
Sparklin Labs) e li adatta a Quietville: ritaglia, ricolora (robot in metallo
con l'occhio rosso, cane bianco e nero, protagonista con la camicia rossa) e
salva tutto in assets/.

Uso (serve Python 3 con Pillow: pip install pillow):
    git clone https://github.com/sparklinlabs/superpowers-asset-packs /tmp/sap
    python3 tools/import_assets.py /tmp/sap

I PNG risultanti sono già nel repository: questo script serve solo se si
vogliono rigenerare o cambiare le scelte.
"""
import os
import sys

from PIL import Image

PACK = sys.argv[1] if len(sys.argv) > 1 else "/tmp/sap"
OUT = os.path.join(os.path.dirname(__file__), "..", "assets")

NINJA = os.path.join(PACK, "ninja-adventure")
MEDIEVAL = os.path.join(PACK, "medieval-fantasy")
SHOOTER = os.path.join(PACK, "top-down-shooter")
TILESET = os.path.join(NINJA, "background-elements", "tileset.png")
MED_TILESET = os.path.join(MEDIEVAL, "background-elements", "0-tileset.png")


def hexcol(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def load(path):
    return Image.open(path).convert("RGBA")


def save(img, name):
    path = os.path.join(OUT, name)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print("  ", name, img.size)


def recolor(img, mapping):
    """Sostituisce i colori esatti: mapping = {"#vecchio": "#nuovo"}."""
    table = {hexcol(k): hexcol(v) for k, v in mapping.items()}
    out = img.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a and (r, g, b) in table:
                px[x, y] = table[(r, g, b)] + (a,)
    return out


def flash(img):
    """Sagoma tutta bianca: si usa per il lampo quando un personaggio è colpito."""
    out = img.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            if px[x, y][3]:
                px[x, y] = (255, 255, 255, px[x, y][3])
    return out


def tile(src, col, row, w=1, h=1, size=16):
    return src.crop((col * size, row * size, (col + w) * size, (row + h) * size))


def trim(img):
    box = img.getbbox()
    return img.crop(box) if box else img


def character(src, name, mapping=None):
    img = load(src)
    if mapping:
        img = recolor(img, mapping)
    save(img, "characters/%s.png" % name)
    save(flash(img), "characters/%s_flash.png" % name)


def main():
    print("Personaggi")
    # Protagonista: capelli castani, camicia rossa.
    character(os.path.join(NINJA, "characters", "6.png"), "player", {
        "#c03a24": "#6e4424", "#972c26": "#4a2c18",      # capelli
        "#367c98": "#a8302a", "#2e3939": "#5e1814",      # camicia a quadri
    })
    # Abitanti.
    character(os.path.join(NINJA, "characters", "4.png"), "edda", {
        "#91578b": "#8e8e9a", "#d3a2ce": "#dcdce4",      # capelli grigi
    })
    character(os.path.join(NINJA, "characters", "3.png"), "gus")
    character(os.path.join(NINJA, "characters", "13.png"), "tobia")
    # Il cane: da cagnolino arancione a border collie bianco e nero.
    character(os.path.join(NINJA, "characters", "dog.png"), "dog", {
        "#ec6930": "#1e1e26", "#982e29": "#0e0e12", "#f49b61": "#f0ece0",
    })

    print("Robot")
    metal = {"light": "#c8d0dc", "mid": "#8a93a6", "base": "#5a6272", "dark": "#3b4252", "deep": "#242933"}
    # Servitore Domestico: il cavaliere in armatura diventa un androide.
    servant = recolor(load(os.path.join(NINJA, "characters", "18.png")), {
        "#7fa2ad": metal["mid"], "#537079": metal["base"], "#5c4394": metal["dark"],
        "#341e53": metal["deep"], "#e3f1f5": metal["light"], "#ba4e25": metal["deep"], "#9e1e21": metal["deep"],
    })
    # Visore rosso: nei fotogrammi frontali (prima colonna) la fessura scura
    # dell'elmo, cioè i pixel neri con metallo a destra e a sinistra, diventa rossa.
    px = servant.load()
    black = hexcol("#020202")
    for fy in range(0, servant.height, 16):
        for y in range(fy + 3, fy + 10):
            for x in range(3, 13):
                if px[x, y][:3] == black and px[x - 1, y][3] and px[x + 1, y][3] \
                        and px[x - 1, y][:3] != black and px[x + 1, y][:3] != black:
                    px[x, y] = hexcol("#ff2a2a") + (255,)
    save(servant, "characters/servitore.png")
    save(flash(servant), "characters/servitore_flash.png")
    # Drone Sondaggio: l'occhio fluttuante diventa un drone di metallo.
    character(os.path.join(NINJA, "monsters", "17.png"), "drone", {
        "#13dba0": metal["base"], "#318d72": metal["dark"], "#b6f9e6": metal["light"],
        "#fe965c": "#ff2a2a", "#fd6a37": "#c01818", "#fcdbb1": "#ffb0b0",
    })
    # Segugio: il granchio ciclope diventa un quadrupede meccanico.
    hound = load(os.path.join(NINJA, "monsters", "1.png"))
    px = hound.load()
    eye = {hexcol("#d89f83"), hexcol("#fcdbb1")}
    pupils = set()
    for y in range(hound.height):
        for x in range(hound.width):
            if px[x, y][:3] == hexcol("#ed2727"):
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < hound.width and 0 <= ny < hound.height and px[nx, ny][:3] in eye:
                        pupils.add((x, y))
    hound = recolor(hound, {
        "#ed2727": metal["base"], "#9a2459": metal["dark"], "#fd6a37": metal["mid"],
        "#d89f83": metal["light"], "#fcdbb1": "#e8eef4",
    })
    px = hound.load()
    for x, y in pupils:
        px[x, y] = hexcol("#ff2a2a") + (255,)
    save(hound, "characters/segugio.png")
    save(flash(hound), "characters/segugio_flash.png")

    print("Terreno e decorazioni")
    t = load(TILESET)
    m = load(MED_TILESET)
    save(tile(t, 22, 11), "tiles/grass_a.png")
    save(tile(t, 23, 11), "tiles/grass_b.png")
    decor = {
        "tree_round": tile(t, 0, 10, 2, 2),
        "pine": tile(t, 6, 10, 2, 2),
        "tree_big": tile(t, 11, 8, 2, 2),
        "rock": tile(t, 12, 10, 2, 2),
        "rock_small": tile(t, 17, 10),
        "bush": tile(t, 0, 6),
        "fern": tile(t, 13, 8),
        "flower": tile(t, 1, 8),
        "flowers": tile(t, 2, 8),
        "tuft": tile(t, 0, 5),
        "weed": tile(t, 0, 8),
        "stump": tile(t, 6, 18, 2, 2),
        "barrel": tile(t, 4, 8),
        "cross": tile(t, 8, 7),
        "pit": tile(t, 1, 7),
        "gate": tile(m, 13, 8, 2, 3),
        "palisade": tile(m, 13, 8, 2, 1),
        "farmhouse": tile(t, 0, 0, 4, 3),
        "cottage": tile(t, 8, 0, 4, 3),
    }
    for name, img in decor.items():
        save(trim(img), "decor/%s.png" % name)
    for src, name in (("7", "house_a"), ("9", "house_b"), ("16", "chapel"), ("4", "well"), ("19", "dead_tree"), ("20", "pine_small")):
        save(trim(load(os.path.join(MEDIEVAL, "background-elements", src + ".png"))), "decor/%s.png" % name)

    print("Effetti")
    save(load(os.path.join(SHOOTER, "effects", "explosion.png")), "fx/explosion.png")
    save(load(os.path.join(NINJA, "fx", "18.png")), "fx/smoke.png")
    save(load(os.path.join(SHOOTER, "weapons", "shoot", "6.png")), "fx/bullet.png")


# Suoni e musiche scelti (stessi pacchetti CC0): nome in assets/audio -> file originale.
AUDIO = {
    "shoot": "western-fps-2d/sounds/gun-1.ogg",
    "no_ammo": "western-fps-2d/sounds/no-ammo.ogg",
    "hit_1": "western-fps-2d/sounds/impact-1.ogg",
    "hit_2": "western-fps-2d/sounds/impact-2.ogg",
    "explosion_1": "top-down-shooter/sounds/explosion-1.wav",
    "explosion_2": "top-down-shooter/sounds/explosion-2.wav",
    "explosion_3": "top-down-shooter/sounds/explosion-3.wav",
    "glass_1": "western-fps-2d/sounds/glass-breaking-1.ogg",
    "glass_2": "western-fps-2d/sounds/glass-breaking-2.ogg",
    "whoosh": "medieval-fantasy/sounds/woosh-1.wav",
    "crumble": "top-down-shooter/sounds/shoot-destroy.wav",
    "hammer": "top-down-shooter/sounds/window-hit-1.wav",
    "scrap_1": "ninja-adventure/sounds/gold-1.ogg",
    "scrap_2": "ninja-adventure/sounds/gold-2.ogg",
    "drone_shot": "top-down-shooter/sounds/shoot-3.wav",
    "zap": "top-down-shooter/sounds/cure.wav",
    "hurt": "top-down-shooter/sounds/death.wav",
    "gate": "ninja-adventure/sounds/alert.ogg",
    "wave": "top-down-shooter/sounds/alert.wav",
    "robot_voice_1": "medieval-fantasy/sounds/monster-1.wav",
    "robot_voice_2": "medieval-fantasy/sounds/monster-2.wav",
    "raven_1": "western-fps-2d/sounds/raven-1.ogg",
    "raven_2": "western-fps-2d/sounds/raven-2.ogg",
    "victory": "medieval-fantasy/sounds/victory-1.wav",
    "defeat": "ninja-adventure/sounds/game-over.ogg",
    "ambience": "medieval-fantasy/sounds/forest-ambience.wav",
    "music_calm": "western-fps-2d/musics/theme-1.ogg",
    "music_siege": "top-down-shooter/music/theme-1.ogg",
}


def copy_audio():
    import shutil
    print("Audio")
    os.makedirs(os.path.join(OUT, "audio"), exist_ok=True)
    for name, src in AUDIO.items():
        ext = os.path.splitext(src)[1]
        shutil.copy(os.path.join(PACK, src), os.path.join(OUT, "audio", name + ext))
        print("  ", "audio/" + name + ext)


if __name__ == "__main__":
    main()
    copy_audio()
