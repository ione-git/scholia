#!/usr/bin/env python3
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "Design/design-system/project/tokens.json"
OUTPUT = ROOT / "Packages/DesignSystem/Sources/DesignSystem/GeneratedTokens.swift"


def camel(name):
    first, *rest = name.split("-")
    return first + "".join(part[:1].upper() + part[1:] for part in rest)


def number(value):
    value = round(float(str(value).removesuffix("px")), 4)
    return str(int(value)) if value.is_integer() else repr(value)


def ui_color(css):
    css = css.strip()
    if css.startswith("#"):
        return f"UIColor(rgb: 0x{css[1:].lower()}, opacity: 1)"
    match = re.fullmatch(r"rgba\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*([\d.]+)\s*\)", css)
    if not match:
        raise ValueError(f"unsupported colour {css!r}")
    red, green, blue = (int(match.group(index)) for index in range(1, 4))
    return f"UIColor(rgb: 0x{red:02x}{green:02x}{blue:02x}, opacity: {number(match.group(4))})"


def split_layers(css):
    layers, depth, current = [], 0, ""
    for character in css:
        depth += {"(": 1, ")": -1}.get(character, 0)
        if character == "," and depth == 0:
            layers.append(current.strip())
            current = ""
        else:
            current += character
    layers.append(current.strip())
    return layers


def shadow_layer(css):
    color = re.search(r"rgba\([^)]*\)|#[0-9a-fA-F]{6}", css).group(0)
    rest = css.replace(color, " ").split()
    is_inset = "inset" in rest
    lengths = [number(length) for length in rest if length != "inset"] + ["0", "0"]
    x, y, blur, spread = lengths[:4]
    kind = "inset" if is_inset else "drop"
    return f".{kind}(x: {x}, y: {y}, blur: {blur}, spread: {spread}, color: {ui_color(color)})"


def colors(tokens):
    lines = ["extension ColorToken {"]
    for token in tokens:
        value = token["value"]
        light, dark = (value["light"], value["dark"]) if isinstance(value, dict) else (value, value)
        lines += [
            f"    public static let {camel(token['name'])} = ColorToken(",
            f'        name: "{token["name"]}",',
            f"        light: {ui_color(light)},",
            f"        dark: {ui_color(dark)}",
            "    )",
        ]
    lines += list_of("ColorToken", "all", [f".{camel(token['name'])}" for token in tokens]) + ["}", ""]
    lines += ["extension ShapeStyle where Self == Color {"]
    lines += [
        f"    public static var {camel(token['name'])}: Color {{ ColorToken.{camel(token['name'])}.color }}"
        for token in tokens
    ]
    return lines + ["}"]


def text_styles(groups):
    lines, names = ["extension TextStyle {"], []
    for group in groups:
        for style in group["styles"]:
            size = float(style["fontSize"].removesuffix("px"))
            line_height = style["lineHeight"]
            if isinstance(line_height, str):
                line_height = number(line_height)
            else:
                line_height = number(size * line_height)
            tracking = number(size * float(style.get("letterSpacing", "0em").removesuffix("em")))
            text_indent = number(size * float(style.get("textIndent", "0em").removesuffix("em")))
            uppercase = "text-transform: uppercase" in style.get("usage", "")
            names.append(f".{camel(style['name'])}")
            lines += [
                f"    public static let {camel(style['name'])} = TextStyle(",
                f'        name: "{style["name"]}",',
                f"        family: .{group['family']},",
                f"        size: {number(size)},",
                f"        lineHeight: {line_height},",
                f"        weight: {style['fontWeight']},",
                f"        tracking: {tracking},",
                f"        textIndent: {text_indent},",
                f"        isUppercase: {'true' if uppercase else 'false'}",
                "    )",
            ]
    return lines + list_of("TextStyle", "all", names) + ["}"]


def reading_scale(scale):
    lines = ["extension ReadingSize {", "    public static let steps: [ReadingSize] = ["]
    for step in scale["steps"]:
        heights = step["lineHeight"]
        lines += [
            "        ReadingSize(",
            f"            fontSize: {number(step['fontSize'])},",
            f"            tightLineHeight: {number(heights['tight'])},",
            f"            normalLineHeight: {number(heights['normal'])},",
            f"            looseLineHeight: {number(heights['loose'])}",
            "        ),",
        ]
    return lines + ["    ]", "}"]


def numbers(categories):
    lines = ["extension CGFloat {"]
    for tokens in categories.values():
        lines += [
            f"    public static let {camel(token['name'])}: CGFloat = {number(token['value'])}" for token in tokens
        ]
    lines += ["}", "", "extension NumberToken {"]
    for category, tokens in categories.items():
        items = [f'NumberToken(name: "{token["name"]}", value: .{camel(token["name"])})' for token in tokens]
        lines += list_of("NumberToken", category, items)
    return lines + ["}"]


def shadows(tokens):
    lines = ["extension ShadowToken {"]
    for token in tokens:
        lines += [
            f"    public static let {camel(token['name'].removeprefix('shadow-'))} = ShadowToken(",
            f'        name: "{token["name"]}",',
            "        layers: [",
        ]
        lines += [f"            {shadow_layer(layer)}," for layer in split_layers(token["value"])]
        lines += ["        ]", "    )"]
    names = [f".{camel(token['name'].removeprefix('shadow-'))}" for token in tokens]
    return lines + list_of("ShadowToken", "all", names) + ["}"]


def list_of(type_name, name, items):
    return [f"    public static let {name}: [{type_name}] = ["] + [f"        {item}," for item in items] + ["    ]"]


def main():
    tokens = json.loads(SOURCE.read_text())
    sections = [
        colors(tokens["color"]["tokens"]),
        text_styles(tokens["type"]["groups"]),
        reading_scale(tokens["type"]["readingScale"]),
        numbers(
            {
                "spacing": tokens["spacing"]["tokens"],
                "radius": tokens["radius"]["tokens"],
                "effects": tokens["effects"]["tokens"],
            }
        ),
        shadows(tokens["shadow"]["tokens"]),
    ]
    lines = ["import SwiftUI", "import UIKit", ""]
    for section in sections:
        lines += section + [""]
    OUTPUT.write_text("\n".join(lines[:-1]) + "\n")


if __name__ == "__main__":
    main()
