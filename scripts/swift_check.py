# -*- coding: utf-8 -*-
"""Swift 源码静态检查：括号平衡 + 类型可见性。

用独立文件而不是内联命令，避免 PowerShell here-string 吃掉反斜杠。
"""
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else "."

STR_RE = re.compile(r'"(?:[^"\\]|\\.)*"', re.S)
LINE_COMMENT = re.compile(r'//[^\n]*')
BLOCK_COMMENT = re.compile(r'/\*.*?\*/', re.S)


def strip(src: str) -> str:
    s = BLOCK_COMMENT.sub(' ', src)
    s = LINE_COMMENT.sub(' ', s)
    s = STR_RE.sub('""', s)
    return s


def check_balance(paths):
    bad = 0
    for p in paths:
        with open(p, encoding='utf-8') as f:
            t = strip(f.read())
        for a, b, name in (('{', '}', '花括号'), ('(', ')', '圆括号'), ('[', ']', '方括号')):
            if t.count(a) != t.count(b):
                print('  FAIL %-52s %s %d vs %d'
                      % (os.path.relpath(p, ROOT), name, t.count(a), t.count(b)))
                bad += 1
    return bad


def decls(paths):
    names = set()
    for p in paths:
        with open(p, encoding='utf-8') as f:
            s = f.read()
        for m in re.finditer(r'\b(?:struct|enum|class|protocol|actor)\s+(\w+)', s):
            names.add(m.group(1))
        # extension Foo: Bar  也算
        for m in re.finditer(r'\bextension\s+(\w+)', s):
            names.add(m.group(1))
    return names


def used(paths):
    names = set()
    for p in paths:
        with open(p, encoding='utf-8') as f:
            s = strip(f.read())
        for m in re.finditer(r'\b([A-Z][A-Za-z0-9]{2,})\b', s):
            names.add(m.group(1))
    return names


SYSTEM = set("""
SwiftUI Foundation WidgetKit ActivityKit AppIntents Combine CoreData
CGFloat Double String Int Bool Date Color View Text Button VStack HStack ZStack
Spacer Circle Capsule Rectangle RoundedRectangle GeometryReader ForEach Group
ScrollView NavigationStack ToolbarItem GridItem LazyVGrid Timeline TimelineEntry
TimelineProvider StaticConfiguration Widget WidgetBundle WidgetConfiguration
Context Environment EnvironmentObject State StateObject Published ObservableObject
Identifiable Codable UUID Calendar DateFormatter DateComponents JSONDecoder JSONEncoder
UserDefaults WidgetCenter TextField DispatchQueue Animation LinearGradient RadialGradient
Locale Bundle Array Optional Result Void Never Set Dictionary Binding Toggle
AppShortcut AppShortcutsProvider IntentResult IntentDescription LocalizedStringResource
DynamicIsland DynamicIslandExpandedRegion ActivityConfiguration ActivityViewContext
Activity ActivityAuthorizationInfo ActivityAttributes Gauge Timer UIApplication URL
Divider Image Task MainActor Scenario LA Context
Sendable Equatable Hashable CaseIterable ViewBuilder
""".split())


def main():
    files = []
    for d, _, fs in os.walk(ROOT):
        if '.git' in d:
            continue
        for f in fs:
            if f.endswith('.swift'):
                files.append(os.path.join(d, f))

    print('=== 括号平衡（%d 个 Swift 文件）===' % len(files))
    bad = check_balance(files)
    print('  全部平衡' if bad == 0 else '  有 %d 处不平衡' % bad)

    shared = [p for p in files if os.sep + 'Shared' + os.sep in p]
    app = [p for p in files if os.sep + 'BudgetAssistant' + os.sep in p]
    wid = [p for p in files if os.sep + 'BudgetWidget' + os.sep in p]

    for label, paths in (('主 App (Shared+App)', shared + app),
                         ('小组件 (Shared+Widget)', shared + wid)):
        d = decls(paths)
        u = used(paths)
        unknown = sorted(x for x in u if x not in d and x not in SYSTEM)
        print('\n=== %s ===' % label)
        print('  声明: %s' % ', '.join(sorted(d)))
        if unknown:
            print('  未声明（需人工确认是否系统类型）:')
            for x in unknown[:40]:
                print('     - %s' % x)
        else:
            print('  无未声明标识符')
    return 0 if bad == 0 else 1


if __name__ == '__main__':
    sys.exit(main())
