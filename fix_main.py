
file_path = r"c:\Users\brije\OneDrive\Pictures\Documents\J.A.R.V.I.S\JarvisAssistant\lib\main.dart"

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Keep lines 1-825 (indices 0-824)
new_lines = lines[:825]

# Append closing braces
new_lines.append("          ],\n")
new_lines.append("        );\n")
new_lines.append("      },\n")
new_lines.append("    );\n")
new_lines.append("  }\n")
new_lines.append("}\n")

with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print("File truncated and closed successfully.")
