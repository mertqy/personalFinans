import os
import re

root_dir = r"c:\Users\Mert\Desktop\personalfinans\personalFinans\lib"

pattern = re.compile(r'\.withValues\(alpha:\s*([0-9.]+)\)')

for root, dirs, files in os.walk(root_dir):
    for file in files:
        if file.endswith('.dart'):
            path = os.path.join(root, file)
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            new_content = pattern.sub(r'.withOpacity(\1)', content)
            
            if new_content != content:
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f"Updated: {path}")
