import os
import re

def find_orphaned_files(root_dir):
    all_dart_files = []
    imported_files = set()
    
    # 1. Collect all dart files
    for dirpath, dirnames, filenames in os.walk(root_dir):
        for file in filenames:
            if file.endswith('.dart'):
                all_dart_files.append(os.path.join(dirpath, file))
                
    # 2. Extract import statements
    import_pattern = re.compile(r"import\s+['\"]([^'\"]+)['\"]")
    for file_path in all_dart_files:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
            imports = import_pattern.findall(content)
            for imp in imports:
                if 'package:' not in imp and 'dart:' not in imp:
                    # resolve relative path
                    # we don't have to be perfect, just getting the basename is usually enough for a heuristics check
                    basename = os.path.basename(imp)
                    imported_files.add(basename)

    # 3. Find files never imported
    orphaned = []
    for f in all_dart_files:
        basename = os.path.basename(f)
        if basename not in imported_files and basename != 'main.dart':
            orphaned.append(f)
            
    print("Potentially Orphaned Files:")
    for o in orphaned:
        print(o)

if __name__ == '__main__':
    find_orphaned_files('lib')
