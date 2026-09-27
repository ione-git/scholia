#!/usr/bin/env python3
import hashlib
import io
import struct
import zipfile
import zlib
from pathlib import Path
from xml.sax.saxutils import escape

OUTPUT = Path(__file__).resolve().parent.parent / "Fixtures"
MODIFIED = "2026-01-01T00:00:00Z"

KAFKA = [
    "Als Gregor Samsa eines Morgens aus unruhigen Träumen erwachte, fand er sich in seinem Bett zu einem "
    "ungeheueren Ungeziefer verwandelt. Er lag auf seinem panzerartig harten Rücken und sah, wenn er den Kopf "
    "ein wenig hob, seinen gewölbten, braunen, von bogenförmigen Versteifungen geteilten Bauch, auf dessen Höhe "
    "sich die Bettdecke, zum gänzlichen Niedergleiten bereit, kaum noch erhalten konnte. Seine vielen, im "
    "Vergleich zu seinem sonstigen Umfang kläglich dünnen Beine flimmerten ihm hilflos vor den Augen.",
    "»Was ist mit mir geschehen?«, dachte er. Es war kein Traum. Sein Zimmer, ein richtiges, nur etwas zu "
    "kleines Menschenzimmer, lag ruhig zwischen den vier wohlbekannten Wänden. Über dem Tisch, auf dem eine "
    "auseinandergepackte Musterkollektion von Tuchwaren ausgebreitet war – Samsa war Reisender –, hing das "
    "Bild, das er vor kurzem aus einer illustrierten Zeitschrift ausgeschnitten und in einem hübschen, "
    "vergoldeten Rahmen untergebracht hatte. Es stellte eine Dame dar, die, mit einem Pelzhut und einer "
    "Pelzboa versehen, aufrecht dasaß und einen schweren Pelzmuff, in dem ihr ganzer Unterarm verschwunden "
    "war, dem Beschauer entgegenhob.",
    "Gregors Blick richtete sich dann zum Fenster, und das trübe Wetter – man hörte Regentropfen auf das "
    "Fensterblech aufschlagen – machte ihn ganz melancholisch. »Wie wäre es, wenn ich noch ein wenig "
    "weiterschliefe und alle Narrheiten vergäße«, dachte er, aber das war gänzlich undurchführbar, denn er war "
    "gewöhnt, auf der rechten Seite zu schlafen, konnte sich aber in seinem gegenwärtigen Zustand nicht in "
    "diese Lage bringen.",
]

FRENCH = [
    "Le matin, la ville se réveille lentement. Les boulangers ouvrent leurs portes, et l'odeur du pain chaud "
    "remplit la rue. Une vieille dame traverse la place avec son panier, salue le marchand de journaux et "
    "s'assoit sur un banc près de la fontaine.",
    "Claire regarde tout cela depuis sa fenêtre. Elle tient une tasse de café entre ses mains et pense au "
    "voyage qu'elle prépare depuis des mois. Demain, elle prendra le train pour la mer, et elle ne sait pas "
    "encore quand elle reviendra.",
    "Dans la cuisine, la radio annonce le temps de la journée : un ciel clair, un peu de vent, quelques nuages "
    "le soir. Claire sourit. Elle aime les jours simples, les rues calmes et les livres qu'on lit lentement, "
    "une page après l'autre.",
]

ARABIC = [
    "في الصباح تستيقظ المدينة ببطء. يفتح الخبازون أبواب محلاتهم، وتملأ رائحة الخبز الساخن الشارع. تعبر سيدة "
    "عجوز الساحة وهي تحمل سلتها، وتلقي التحية على بائع الصحف، ثم تجلس على مقعد قريب من النافورة.",
    "تنظر سلمى إلى كل ذلك من نافذتها. تمسك بين يديها فنجان قهوة، وتفكر في الرحلة التي تستعد لها منذ أشهر. "
    "غدًا ستركب القطار إلى البحر، ولا تعرف بعد متى ستعود.",
    "في المطبخ يعلن المذياع حالة الطقس لهذا اليوم: سماء صافية، وقليل من الريح، وبعض الغيوم في المساء. تبتسم "
    "سلمى. إنها تحب الأيام البسيطة والشوارع الهادئة والكتب التي تُقرأ ببطء، صفحة بعد صفحة.",
]

ENGLISH = [
    "This book has a cover and only the metadata that every EPUB must declare: an identifier, a title, a "
    "language and a modification date. It has no author.",
]

VERSE = (
    "<p>Über allen Gipfeln<br/>Ist Ruh,<br/>In allen Wipfeln<br/>Spürest du<br/>Kaum einen Hauch;</p>\n"
    "<div>Die Vögelein schweigen im Walde.</div><div>Warte nur, balde</div><div>Ruhest du auch.</div>\n"
)

CONTAINER = """<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
"""

ENCRYPTION = """<?xml version="1.0" encoding="UTF-8"?>
<encryption xmlns="urn:oasis:names:tc:opendocument:xmlns:container"
    xmlns:enc="http://www.w3.org/2001/04/xmlenc#" xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
  <enc:EncryptedData>
    <enc:EncryptionMethod Algorithm="http://www.w3.org/2001/04/xmlenc#aes128-cbc"/>
    <ds:KeyInfo>
      <ds:KeyName>scholia-fixture</ds:KeyName>
    </ds:KeyInfo>
    <enc:CipherData>
      <enc:CipherReference URI="OEBPS/chapter-1.xhtml"/>
    </enc:CipherData>
  </enc:EncryptedData>
</encryption>
"""

FONT_ENCRYPTION = """<?xml version="1.0" encoding="UTF-8"?>
<encryption xmlns="urn:oasis:names:tc:opendocument:xmlns:container"
    xmlns:enc="http://www.w3.org/2001/04/xmlenc#">
  <enc:EncryptedData>
    <enc:EncryptionMethod Algorithm="http://www.idpf.org/2008/embedding"/>
    <enc:CipherData>
      <enc:CipherReference URI="OEBPS/font.otf"/>
    </enc:CipherData>
  </enc:EncryptedData>
</encryption>
"""


def png_chunk(kind, data):
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))


def png(width, height, background, band):
    plain = b"\x00" + bytes(background) * width
    striped = b"\x00" + bytes(band) * width
    rows = b"".join(striped if height * 6 // 10 <= y < height * 3 // 4 else plain for y in range(height))
    header = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    return (
        b"\x89PNG\r\n\x1a\n"
        + png_chunk(b"IHDR", header)
        + png_chunk(b"IDAT", zlib.compress(rows, 9))
        + png_chunk(b"IEND", b"")
    )


def xhtml(language, title, body):
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" xml:lang="{language}" lang="{language}">
<head>
<title>{escape(title)}</title>
</head>
<body>
{body}
</body>
</html>
"""


def prose(paragraphs):
    return "\n".join(f"<p>{escape(paragraph)}</p>" for paragraph in paragraphs)


def section(title, body, attributes=""):
    return f'<section epub:type="chapter"{attributes}>\n<h1>{escape(title)}</h1>\n{body}\n</section>'


def chapter(language, title, body, attributes=""):
    return xhtml(language, title, section(title, body, attributes))


def anchored_chapters(language, title, chapters, first=1):
    sections = (
        section(heading, body, f' id="chapter-{index}"') for index, (heading, body) in enumerate(chapters, first)
    )
    return xhtml(language, title, "\n".join(sections))


def nav(language, title, entries):
    items = "\n".join(f'<li><a href="{href}">{escape(heading)}</a></li>' for heading, href in entries)
    return xhtml(language, title, f'<nav epub:type="toc" id="toc">\n<ol>\n{items}\n</ol>\n</nav>')


def package(identifier, title, language, creator, documents, cover):
    metadata = [
        f'<dc:identifier id="book-id">{identifier}</dc:identifier>',
        f"<dc:title>{escape(title)}</dc:title>",
        f"<dc:language>{language}</dc:language>",
    ]
    if creator:
        metadata.append(f"<dc:creator>{escape(creator)}</dc:creator>")
    metadata.append(f'<meta property="dcterms:modified">{MODIFIED}</meta>')
    manifest = ['<item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>']
    if cover:
        metadata.append('<meta name="cover" content="cover"/>')
        manifest.append('<item id="cover" href="cover.png" media-type="image/png" properties="cover-image"/>')
    spine = []
    for index in range(1, documents + 1):
        manifest.append(f'<item id="chapter-{index}" href="chapter-{index}.xhtml" media-type="application/xhtml+xml"/>')
        spine.append(f'<itemref idref="chapter-{index}"/>')
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="book-id" xml:lang="{language}">
<metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
{chr(10).join(metadata)}
</metadata>
<manifest>
{chr(10).join(manifest)}
</manifest>
<spine>
{chr(10).join(spine)}
</spine>
</package>
"""


def epub(identifier, title, language, creator, chapters, cover, in_one_file=False, anchored=False, files=None):
    if files:
        documents = []
        hrefs = []
        first = 1
        for number, count in enumerate(files, 1):
            group = chapters[first - 1 : first - 1 + count]
            if count == 1:
                documents.append(chapter(language, *group[0]))
                hrefs.append(f"chapter-{number}.xhtml")
            else:
                documents.append(anchored_chapters(language, title, group, first))
                hrefs.extend(f"chapter-{number}.xhtml#chapter-{index}" for index in range(first, first + count))
            first += count
    elif in_one_file:
        documents = [anchored_chapters(language, title, chapters)]
        hrefs = [f"chapter-1.xhtml#chapter-{index}" for index in range(1, len(chapters) + 1)]
    elif anchored:
        documents = [
            chapter(language, heading, body, f' id="chapter-{index}"')
            for index, (heading, body) in enumerate(chapters, 1)
        ]
        hrefs = [f"chapter-{index}.xhtml#chapter-{index}" for index in range(1, len(chapters) + 1)]
    else:
        documents = [chapter(language, heading, body) for heading, body in chapters]
        hrefs = [f"chapter-{index}.xhtml" for index in range(1, len(chapters) + 1)]
    files = {
        "META-INF/container.xml": CONTAINER.encode(),
        "OEBPS/content.opf": package(identifier, title, language, creator, len(documents), cover).encode(),
        "OEBPS/nav.xhtml": nav(language, title, [(heading, href) for (heading, _), href in zip(chapters, hrefs)]).encode(),
    }
    for index, document in enumerate(documents, 1):
        files[f"OEBPS/chapter-{index}.xhtml"] = document.encode()
    if cover:
        files["OEBPS/cover.png"] = cover
    return files


def archive(files):
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, "w") as book:
        for name, data in [("mimetype", b"application/epub+zip")] + list(files.items()):
            info = zipfile.ZipInfo(name, (1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_STORED if name == "mimetype" else zipfile.ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            book.writestr(info, data)
    return buffer.getvalue()


def zip64(data):
    end = len(data) - 22
    count, size, offset = struct.unpack("<HII", data[end + 10 : end + 20])
    record = struct.pack("<IQHHIIQQQQ", 0x06064B50, 44, 45, 45, 0, 0, count, count, size, offset)
    locator = struct.pack("<IIQI", 0x07064B50, 0, end, 1)
    classic = struct.pack("<IHHHHIIH", 0x06054B50, 0, 0, 0xFFFF, 0xFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0)
    return data[:end] + record + locator + classic


def main():
    german_cover = png(600, 900, (47, 74, 58), (96, 128, 108))
    minimal_cover = png(600, 900, (140, 59, 46), (196, 110, 92))
    german = epub(
        "urn:scholia:fixture:german",
        "Die Verwandlung",
        "de",
        "Franz Kafka",
        [
            ("Erster Teil", prose(KAFKA * 10)),
            ("Zweiter Teil", VERSE + prose(KAFKA * 10)),
            ("Dritter Teil", prose(KAFKA * 10)),
        ],
        german_cover,
    )
    french = epub(
        "urn:scholia:fixture:french-no-cover",
        "Un matin en ville",
        "fr",
        "Scholia",
        [("Premier chapitre", prose(FRENCH * 6)), ("Deuxième chapitre", prose(FRENCH * 6))],
        None,
        in_one_file=True,
    )
    french_sections = epub(
        "urn:scholia:fixture:french-sections",
        "Un soir en ville",
        "fr",
        "Scholia",
        [
            ("Premier chapitre", prose(FRENCH * 2)),
            ("Deuxième chapitre", prose(FRENCH * 2)),
            ("Troisième chapitre", prose(FRENCH * 2)),
        ],
        None,
        files=[1, 2],
    )
    french_split = epub(
        "urn:scholia:fixture:french-split",
        "Trois matins",
        "fr",
        "Scholia",
        [
            ("Premier matin", prose(FRENCH * 4)),
            ("Deuxième matin", prose(FRENCH * 4)),
            ("Troisième matin", prose(FRENCH * 4)),
        ],
        None,
        files=[1, 2],
    )
    arabic = epub(
        "urn:scholia:fixture:arabic",
        "صباح في المدينة",
        "ar",
        "Scholia",
        [
            ("الفصل الأول", prose(ARABIC * 4)),
            ("الفصل الثاني", prose(ARABIC * 4)),
            ("الفصل الثالث", prose(ARABIC * 4)),
        ],
        None,
        anchored=True,
    )
    minimal = archive(
        epub(
            "urn:scholia:fixture:minimal-metadata",
            "Minimal",
            "en",
            None,
            [("Chapter One", prose(ENGLISH))],
            minimal_cover,
        )
    )
    drm = epub("urn:scholia:fixture:drm", "Encrypted", "de", "Franz Kafka", [("Erster Teil", prose(KAFKA))], None)
    drm["META-INF/encryption.xml"] = ENCRYPTION.encode()
    drm["OEBPS/chapter-1.xhtml"] = hashlib.shake_256(drm["OEBPS/chapter-1.xhtml"]).digest(
        len(drm["OEBPS/chapter-1.xhtml"])
    )
    large = epub("urn:scholia:fixture:zip64", "ZIP64", "de", "Franz Kafka", [("Erster Teil", prose(KAFKA))], None)
    font = epub(
        "urn:scholia:fixture:font-obfuscation",
        "Obfuscated Font",
        "de",
        "Franz Kafka",
        [("Erster Teil", prose(KAFKA))],
        None,
    )
    font["META-INF/encryption.xml"] = FONT_ENCRYPTION.encode()
    font["OEBPS/content.opf"] = font["OEBPS/content.opf"].replace(
        b"<manifest>\n", b'<manifest>\n<item id="font" href="font.otf" media-type="font/otf"/>\n'
    )
    font["OEBPS/font.otf"] = hashlib.shake_256(b"scholia-font").digest(2048)
    books = {
        "german.epub": archive(german),
        "french-no-cover.epub": archive(french),
        "french-sections.epub": archive(french_sections),
        "french-split.epub": archive(french_split),
        "arabic.epub": archive(arabic),
        "minimal-metadata.epub": minimal,
        "corrupted.epub": minimal[: len(minimal) // 2],
        "drm.epub": archive(drm),
        "german-cover.png": german_cover,
        "minimal-metadata-cover.png": minimal_cover,
        "zip64.epub": zip64(archive(large)),
        "font-obfuscation.epub": archive(font),
    }
    OUTPUT.mkdir(exist_ok=True)
    for name, data in books.items():
        (OUTPUT / name).write_bytes(data)


if __name__ == "__main__":
    main()
