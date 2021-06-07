import 'dart:async';
import 'ext.dart';
import 'lab2.dart';

//符号表
List<LR0_Element> varTable = [];

List<LR0_Element> tempTable = [];

//nextinstr
int nextinstr = 100;

// 这个东西根本不需要，因为全在栈里
// class Code {
//   int instAddr;
//   String code;
// }

// List<Code> codes = [];

// 生成临时变量
int tempIndex = 1;
LR0_Element temp() {
  return LR0_Element('tmp${tempIndex++}', t: true);
}

//分配变量地址
int offset;
// 对应课件6-1 22页
// 需要增加空产生式，对文法进行改造，来判断语义动作的位置，使用该文法替换实验2 的文法
List<LR0> grammar3 = [
  LR0(
      left: LR0_Element('P'),
      right: [LR0_Element('M1'), LR0_Element('D'), LR0_Element('S')],
      sdtAction: () {
        // 每次有语句相关操作的时候都要做nextlist合并
        // nextlist主要针对goto来说的
        cStk.top(1)..extra['nextlist'] = pops.top(1).extra['nextlist'];
      }),
  LR0(left: LR0_Element('D'), right: [
    LR0_Element('L'),
    LR0_Element('id', t: true),
    LR0_Element(';', t: true),
    LR0_Element('M2'),
    LR0_Element('D')
  ]),
  LR0(left: LR0_Element('D'), right: []),
  LR0(
      left: LR0_Element('L'),
      right: [LR0_Element('int', t: true)],
      sdtAction: () {
        print(cStk.top(1).extra);
        cStk.top(1)
          ..extra['type'] = 'integer'
          ..extra['width'] = 4;
      }),
  LR0(left: LR0_Element('L'), right: [LR0_Element('float', t: true)]),
  LR0(
      left: LR0_Element('S'),
      right: [
        LR0_Element('id', t: true),
        LR0_Element('=', t: true),
        LR0_Element('E'),
        LR0_Element(';', t: true),
      ],
      sdtAction: () {
        cStk.top(1)
          ..extra['code'] = (pops.top(2).extra['code']
            ..add({
              's':
                  '${pops.top(4).extra["lexeme"]}:=${pops.top(2).extra["addr"]}',
              'instr': nextinstr
            }));
        nextinstr++;
      }),
  LR0(left: LR0_Element('S'), right: [
    LR0_Element('if', t: true),
    LR0_Element('(', t: true),
    LR0_Element('C'),
    LR0_Element(')', t: true),
    LR0_Element('M4'),
    LR0_Element('S')
  ]),
  LR0(
      left: LR0_Element('S'),
      right: [
        LR0_Element('if', t: true),
        LR0_Element('(', t: true),
        LR0_Element('C'),
        LR0_Element(')', t: true),
        LR0_Element('M5'),
        LR0_Element('S'),
        LR0_Element('M6'),
        LR0_Element('else', t: true),
        LR0_Element('M7'),
        LR0_Element('S')
      ],
      sdtAction: () {
        // 收集代码
        cStk.top(1)
          ..extra['code'] = ([]
            ..addAll(pops.top(8).extra['code'])
            ..addAll(pops.top(5).extra['code'])
            ..addAll(pops.top(4).extra['code'])
            ..addAll(pops.top(1).extra['code']));

        // 8 - C
        // 6 - M5
        // 给C的truelist回填M5保存的instr
        var codes = (cStk.top(1).extra['code'] as List);
        for (var i = 0; i < codes.length; i++) {
          if (pops.top(8).extra['truelist'].contains(codes[i]['instr'])) {
            // back patch
            codes[i]['s'] = codes[i]['s']
                .replaceFirst('_', "${pops.top(6).extra['instr']}");
          }
        }

        // 2 - M7
        // 给C的falselist回填M7保存的instr
        for (var i = 0; i < codes.length; i++) {
          if (pops.top(8).extra['falselist'].contains(codes[i]['instr'])) {
            // back patch
            codes[i]['s'] = codes[i]['s']
                .replaceFirst('_', "${pops.top(2).extra['instr']}");
          }
        }

        cStk.top(1).extra['nextlist'] = pops.top(4).extra['nextlist'];
      }),
  LR0(left: LR0_Element('S'), right: [
    LR0_Element('while', t: true),
    LR0_Element('(', t: true),
    LR0_Element('C'),
    LR0_Element(')', t: true),
    LR0_Element('S')
  ]),
  LR0(
      left: LR0_Element('S'),
      right: [
        LR0_Element('S'),
        //老师的文法可能不对
        // LR0_Element(';', t: true),
        LR0_Element('M3'),
        LR0_Element('S')
      ],
      sdtAction: () {
        // M3 回填到 S1的next里

        // S 和 S2 的nextlist合并

        // S的code合并
        // 按顺序压入，以便于排序
        print(cStk.top(1));
        cStk.top(1)
          ..extra['code'] = ([]
            ..addAll(pops.top(3).extra['code'] ?? [])
            ..addAll(pops.top(1).extra['code'] ?? []))
          ..extra['nextlist'] = pops.top(1).extra['nextlist'];

        var codes = (cStk.top(1).extra['code'] as List);
        // 给S1的nextlist回填M3保存的instr
        for (var i = 0; i < codes.length; i++) {
          if (pops.top(3).extra['nextlist']?.contains(codes[i]['instr']) ??
              false) {
            // back patch
            codes[i]['s'] = codes[i]['s']
                .replaceFirst('_', "${pops.top(2).extra['instr']}");
          }
        }
      }),
  LR0(
      left: LR0_Element('C'),
      right: [LR0_Element('E'), LR0_Element('>', t: true), LR0_Element('E')],
      sdtAction: () {
        // 每次生成code都必须使inst下标移位
        cStk.top(1)
          ..extra['code'] = [
            {
              's':
                  'if ${pops.top(1).extra["addr"]}>${pops.top(3).extra["addr"]} goto _',
              'instr': nextinstr
            },
            {'s': 'goto _', 'instr': nextinstr + 1}
          ]
          // 之后需要查表回填
          ..extra['truelist'] = [nextinstr]
          ..extra['falselist'] = [nextinstr + 1];
        nextinstr += 2;
      }),
  LR0(
      left: LR0_Element('C'),
      right: [LR0_Element('E'), LR0_Element('<', t: true), LR0_Element('E')]),
  LR0(
    left: LR0_Element('C'),
    right: [LR0_Element('E'), LR0_Element('==', t: true), LR0_Element('E')],
  ),
  LR0(
      left: LR0_Element('E'),
      right: [LR0_Element('E'), LR0_Element('+', t: true), LR0_Element('T')],
      sdtAction: () {
        var t = temp();
        tempTable.add(t);
        cStk.top(1)
          ..extra['code'] = [
            {
              's':
                  '${t}=${pops.top(3).extra["addr"]}+${pops.top(1).extra["addr"]}',
              'instr': nextinstr
            }
          ]
          ..extra['addr'] = t.s;
        nextinstr++;
      }),
  LR0(
      left: LR0_Element('E'),
      right: [LR0_Element('E'), LR0_Element('-', t: true), LR0_Element('T')],
      sdtAction: () {
        var t = temp();
        tempTable.add(t);
        cStk.top(1)
          ..extra['code'] = [
            {
              's':
                  '${t}=${pops.top(3).extra["addr"]}-${pops.top(1).extra["addr"]}',
              'instr': nextinstr
            }
          ]
          ..extra['addr'] = t.s;
        nextinstr++;
      }),
  LR0(
      left: LR0_Element('E'),
      right: [LR0_Element('T')],
      sdtAction: () {
        cStk.top(1)
          ..extra['addr'] = pops.top(1).extra['addr']
          ..extra['code'] = pops.top(1).extra['code'];
      }),
  LR0(
      left: LR0_Element('T'),
      right: [LR0_Element('F')],
      sdtAction: () {
        cStk.top(1)
          ..extra['addr'] = pops.top(1).extra['addr']
          ..extra['code'] = pops.top(1).extra['code'];
      }),
  LR0(
      left: LR0_Element('T'),
      right: [LR0_Element('T'), LR0_Element('*', t: true), LR0_Element('F')]),
  LR0(
      left: LR0_Element('T'),
      right: [LR0_Element('T'), LR0_Element('/', t: true), LR0_Element('F')]),
  LR0(left: LR0_Element('F'), right: [
    LR0_Element('(', t: true),
    LR0_Element('E'),
    LR0_Element(')', t: true)
  ]),
  LR0(
      left: LR0_Element('F'),
      right: [LR0_Element('id', t: true)],
      sdtAction: () {
        cStk.top(1)
          ..extra['addr'] = pops.top(1).extra['lexeme']
          ..extra['code'] = [];
      }),
  LR0(
      left: LR0_Element('F'),
      right: [LR0_Element('digits', t: true)],
      sdtAction: () {
        cStk.top(1)
          ..extra['addr'] = pops.top(1).extra['digits']
          ..extra['code'] = [];
      }),
  //some test case
  // LR0(left: LR0_Element('S'), right: [])

  // 下面的都是新加入的SDT相关动作
  // SDT的地方需要用到的回填技术，M是回填，N是 暂时无法确定的 nextlist合并
  LR0(
      left: LR0_Element('M1'),
      right: [],
      sdtAction: () {
        offset = 0;
      }),
  LR0(
      left: LR0_Element('M2'),
      right: [],
      sdtAction: () {
        print(cStk[cStk.length - 3]);
        varTable.add(cStk[cStk.length - 3]
          ..extra['type'] = cStk[cStk.length - 4].extra['type']
          ..extra['offset'] = offset);
        offset += cStk[cStk.length - 4].extra['width'];
      }),

  LR0(
      //专门用来记录当前地址的归约动作，可多次使用
      left: LR0_Element('M3'),
      right: [],
      sdtAction: () {
        // 这里只需要记录地址就可以了，后面会用到
        cStk.top(1)..extra['instr'] = nextinstr;
      }),
  LR0(left: LR0_Element('M4'), right: [], sdtAction: () {}),
  LR0(
      left: LR0_Element('M5'),
      right: [],
      sdtAction: () {
        cStk.top(1)..extra['instr'] = nextinstr;
      }),
  LR0(
      left: LR0_Element('M6'),
      right: [],
      sdtAction: () {
        cStk.top(1)
          ..extra['instr'] = nextinstr
          ..extra['code'] = [
            {'s': 'goto _', 'instr': nextinstr}
          ]
          ..extra['nextlist'] = [nextinstr];
        nextinstr++;
      }),
  LR0(
      left: LR0_Element('M7'),
      right: [],
      sdtAction: () {
        cStk.top(1)..extra['instr'] = nextinstr;
      }),
  LR0(left: LR0_Element('M8'), right: []),
  LR0(left: LR0_Element('M9'), right: [])
];

main(List<String> args) {
  main3Fun();
}
