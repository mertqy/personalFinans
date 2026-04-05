import os
import re

def get_strings():
    strings = set()
    for root, _, files in os.walk('lib'):
        for f in files:
            if f.endswith('.dart'):
                with open(os.path.join(root, f), 'r', encoding='utf-8') as file:
                    content = file.read()
                    matches = re.findall(r\"'([^'\\]{4,50})'\", content)
                    matches.extend(re.findall(r'\"([^\\"\\]{4,50})\"', content))
                    for m in matches:
                        if m.isascii() and ' ' in m and not m.startswith('http') and not m.startswith('com.') and not m.startswith('asset'):
                            strings.add(m)
    for s in sorted(strings):
        print(s)

get_strings()
