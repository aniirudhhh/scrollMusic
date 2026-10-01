import sys

def check_brackets(text):
    stack = []
    lines = text.split('\n')
    for i, line in enumerate(lines):
        for j, char in enumerate(line):
            if char in '([{':
                stack.append((char, i + 1, j + 1))
            elif char in ')]}':
                if not stack:
                    print(f"Extra closing bracket '{char}' at line {i+1}, col {j+1}")
                    return
                last_char, last_line, last_col = stack.pop()
                expected = {'(': ')', '[': ']', '{': '}'}[last_char]
                if char != expected:
                    print(f"Mismatched bracket at line {i+1}, col {j+1}: expected '{expected}' (from line {last_line}), got '{char}'")
                    return
    if stack:
        print("Unclosed brackets:")
        for char, line, col in stack:
            print(f"  '{char}' at line {line}, col {col}")
    else:
        print("All brackets matched perfectly!")

if __name__ == '__main__':
    with open(sys.argv[1], 'r', encoding='utf-8') as f:
        check_brackets(f.read())
