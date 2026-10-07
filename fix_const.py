import re

filepath = "lib/features/dashboard/presentation/screens/dashboard_screen.dart"
with open(filepath, "r", encoding="utf-8") as f:
    content = f.read()

# Replace `const Text(\n              ref.watch` with `Text(\n              ref.watch`
content = re.sub(r'const\s+Text\(\s*ref\.watch', r'Text(\n              ref.watch', content)
content = re.sub(r'const\s+Text\(ref\.watch', r'Text(ref.watch', content)

# Check if there are other consts like `const Row` wrapping the Text
# We might need a generic regex for `const\s+(Row|Column|Container|Center).*?ref\.watch` but that's too complex.
# Let's run a naive replacement of "const Text(ref.watch" first.

with open(filepath, "w", encoding="utf-8") as f:
    f.write(content)
