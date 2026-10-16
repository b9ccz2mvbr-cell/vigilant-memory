#!/usr/bin/env python3
"""从 project.yml 里移除桌面小组件（WidgetKit）target。

用途：第一次云端编译时先只验证主 App 能过，把
「代码能不能编译」和「小组件权限行不行」两件事分开排查。
验证通过后再跑完整版（带小组件）。

用法：
    python3 scripts/strip_widget.py project.yml

会就地改写 project.yml：删掉 BudgetWidget target，
以及主 App 里对它的 dependencies 引用。
"""
import re
import sys


def strip_widget(text: str) -> str:
    lines = text.split("\n")
    out = []
    i = 0
    while i < len(lines):
        line = lines[i]

        # 1) 主 App 里对小组件的依赖块
        #    dependencies:
        #      # 主 App 内嵌小组件扩展
        #      - target: BudgetWidget
        #        embed: true
        if re.match(r"^    dependencies:\s*$", line):
            # 往后看是否只包含 widget 这一个依赖
            j = i + 1
            block = []
            while j < len(lines) and (lines[j].startswith("      ") or lines[j].strip() == ""):
                block.append(lines[j])
                j += 1
            if any("BudgetWidget" in b for b in block):
                i = j
                continue

        # 2) 小组件 target 段：从它的注释标题一直到文件结束
        #    （project.yml 里 widget 是最后一个 target）
        if re.match(r"^  # -+ 小组件扩展 -+\s*$", line):
            i = len(lines)
            continue

        out.append(line)
        i += 1

    result = "\n".join(out)
    # 收掉结尾多余空行
    result = re.sub(r"\n{3,}", "\n\n", result).rstrip() + "\n"
    return result


def main() -> int:
    if len(sys.argv) < 2:
        print("用法: strip_widget.py <project.yml>", file=sys.stderr)
        return 2

    path = sys.argv[1]
    with open(path, encoding="utf-8") as f:
        original = f.read()

    if "BudgetWidget" not in original:
        print("project.yml 里没有 BudgetWidget，无需处理")
        return 0

    updated = strip_widget(original)

    if "BudgetWidget" in updated:
        left = [l for l in updated.split("\n") if "BudgetWidget" in l]
        print("警告：仍有残留引用：", file=sys.stderr)
        for l in left:
            print("  " + l, file=sys.stderr)
        return 1

    with open(path, "w", encoding="utf-8") as f:
        f.write(updated)

    print("已移除小组件 target，剩余内容：")
    print(updated)
    return 0


if __name__ == "__main__":
    sys.exit(main())
