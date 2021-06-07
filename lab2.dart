import 'dart:async';
import 'dart:collection';
import 'dart:io' as io;
import 'ext.dart';
import 'lab3.dart';
//实验2 ， SLR分析法

//单个lr0项，lr0产生式
//lr0 项集 List<LR0>
//项集族 List<List<LR0>>
//需要记录 . 的位置
class LR0 {
  LR0({this.left, this.right, this.dotPosition = 0, this.sdtAction});
  LR0_Element left;
  //右侧字符串的序列
  List<LR0_Element> right;
  Function sdtAction;
  //range : [0,right.length]
  int dotPosition = 0;

  //. 到了末尾，可以规约了
  bool get isEnd => dotPosition == right.length;

  @override
  String toString() {
    var s = left.toString() + '->';
    for (var i = 0; i < right.length * 2 + 1; i++) {
      var index = i ~/ 2;
      if (i % 2 == 0) {
        if (index == dotPosition) s += '.';
      } else {
        s += right[index].toString();
      }
    }
    return s;
  }

  List<LR0> closure() {
    //闭包的起点
    List<LR0> rt = [this.copy];
    var hasUpdate = true;
    while (hasUpdate) {
      hasUpdate = false;
      List<LR0> newElem = [];
      newElem.addAll(rt);
      rt.forEach((element) {
        if (!element.isEnd) {
          var next = element.dotNext;
          if (next.t) {
            //什么也不做
          }
          if (!next.t) {
            grammar
                .select(next.s)
                .map((e) => e.copy)
                .toList()
                .forEach((element) {
              hasUpdate += newElem.addAsSet(element);
            });
          }
        }
      });
      rt = newElem;
    }
    return rt;
  }

  LR0 get copy => LR0(
      left: this.left.copy,
      right: this.right.map((element) => element.copy).toList(),
      dotPosition: this.dotPosition);

  LR0 get normalize => this.copy..dotPosition = 0;

  bool equal(LR0 other) =>
      this.left.s == other.left.s &&
      this.right.length == other.right.length &&
      (() {
        for (var i = 0; i < this.right.length; i++) {
          if (!this.right[i].equal(other.right[i])) return false;
        }
        return true;
      })() &&
      this.dotPosition == other.dotPosition;

  bool get isEpsilon => right.length == 0;

  LR0_Element get dotNext => right[dotPosition];

  int get grammarIndex => (() {
        var toFind = this.normalize;
        for (var grammar_index = 0;
            grammar_index < grammar.length;
            grammar_index++) {
          if (grammar[grammar_index].normalize.equal(toFind)) {
            return grammar_index;
          }
        }
        return -1;
      })();
}

class LR0_Element {
  LR0_Element(this.s, {this.t = false, this.extra}) {
    this.extra = this.extra ?? {};
  }
  //是否终结符
  bool t;

  //content
  String s;

  //其他可能的属性
  Map<String, dynamic> extra;

  @override
  // debug version
  String toString() => '${(extra?.keys?.length == 0 ? "" : extra)}$s';
  // String toString() => '$s';
  LR0_Element get copy => LR0_Element(s, t: t);
  bool equal(LR0_Element other) => other.s == s && other.t == t;
}

class Token {
  Token(this.type, this.val);
  String type;
  String val;
  int index;
  LR0_Element toLr0_Element() {
    if (this.type == 'digits')
      return LR0_Element(type, t: true, extra: {'digits': this.val});
    // 之所以用ID表示 ， 是因为LR0里归约全是按照ID符号来规约的
    // 所以int a;
    //a 这个信息会丢失掉，但是我们要保存起来
    if (this.type == 'id')
      return LR0_Element(type, t: true, extra: {'lexeme': this.val});
    return LR0_Element(val, t: true);
  }

  @override
  String toString() => '[$type,$val]';
  int get columnIndexInTable => readable.searchPosition(this.toLr0_Element());
}

//slr分析表中的 si,rj,goto 的动作
class Action {
  // 0 si , 1 rj , 2 goto , -1 error
  // 5 acc
  Action(this.state, {this.action = -1});
  int action;
  int state;

//归约对应的产生式
  get rGrammar => grammar[state];
  @override
  String toString() {
    String prefix;
    switch (action) {
      case -1:
        return 'err';
      case 5:
        return 'acc';
      case 0:
        prefix = 's';
        break;
      case 1:
        prefix = 'r';
        break;
      case 2:
        prefix = 'g';
        break;
    }
    return '$prefix$state'.width(3);
  }
}

typedef CallBack = void Function(dynamic event);

class Message {
  Message(this.cbk);
  CallBack cbk;
  void add(dynamic event) {
    cbk?.call(event);
  }
}

// 以后考虑代码转换，先手工输入
List<LR0> grammar = [
  LR0(left: LR0_Element('P'), right: [LR0_Element('D'), LR0_Element('S')]),
  LR0(left: LR0_Element('D'), right: [
    LR0_Element('L'),
    LR0_Element('id', t: true),
    LR0_Element(';', t: true),
    LR0_Element('D')
  ]),
  LR0(left: LR0_Element('D'), right: []),
  LR0(left: LR0_Element('L'), right: [LR0_Element('int', t: true)]),
  LR0(left: LR0_Element('L'), right: [LR0_Element('float', t: true)]),
  LR0(left: LR0_Element('S'), right: [
    LR0_Element('id', t: true),
    LR0_Element('=', t: true),
    LR0_Element('E'),
    LR0_Element(';', t: true)
  ]),
  LR0(left: LR0_Element('S'), right: [
    LR0_Element('if', t: true),
    LR0_Element('(', t: true),
    LR0_Element('C'),
    LR0_Element(')', t: true),
    // 测试M回填
    LR0_Element('S')
  ]),
  LR0(left: LR0_Element('S'), right: [
    LR0_Element('if', t: true),
    LR0_Element('(', t: true),
    LR0_Element('C'),
    LR0_Element(')', t: true),
    // 测试M回填
    LR0_Element('S'),
    LR0_Element('else', t: true),

    LR0_Element('S')
  ]),
  LR0(left: LR0_Element('S'), right: [
    LR0_Element('while', t: true),
    LR0_Element('(', t: true),
    LR0_Element('C'),
    LR0_Element(')', t: true),
    LR0_Element('S')
  ]),
  LR0(left: LR0_Element('S'), right: [
    LR0_Element('S'),
    //老师的文法可能不对
    // LR0_Element(';', t: true),
    LR0_Element('S')
  ]),
  LR0(
      left: LR0_Element('C'),
      right: [LR0_Element('E'), LR0_Element('>', t: true), LR0_Element('E')]),
  LR0(
      left: LR0_Element('C'),
      right: [LR0_Element('E'), LR0_Element('<', t: true), LR0_Element('E')]),
  LR0(
      left: LR0_Element('C'),
      right: [LR0_Element('E'), LR0_Element('==', t: true), LR0_Element('E')]),
  LR0(
      left: LR0_Element('E'),
      right: [LR0_Element('E'), LR0_Element('+', t: true), LR0_Element('T')]),
  LR0(
      left: LR0_Element('E'),
      right: [LR0_Element('E'), LR0_Element('-', t: true), LR0_Element('T')]),
  LR0(left: LR0_Element('E'), right: [LR0_Element('T')]),
  LR0(left: LR0_Element('T'), right: [LR0_Element('F')]),
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
  LR0(left: LR0_Element('F'), right: [LR0_Element('id', t: true)]),
  LR0(left: LR0_Element('F'), right: [LR0_Element('digits', t: true)]),
  //some test case
  // LR0(left: LR0_Element('S'), right: [])
];

// first 集
HashMap<String, Set<String>> first = HashMap();
// follow 集
HashMap<String, Set<String>> follow = HashMap();

// LR0 项集族，也用来存储自动机 下标为状态号
List<List<LR0>> lr0_states = [];

// 记录状态转移的，对应于自动机转移图
HashMap<int, List<Map<LR0_Element, int>>> move = HashMap();

// 状态机转最终分析表，包括action表和goto表
// int -> 状态
// list 下表 和 readable 绑定， 表示读入的对应字符
// table 里的 goto i, si 对应于 项集序号， rj 对应于 grammar 序号
List<List<Action>> table = [];

//收集slr分析表格能读入的action表和goto表
List<LR0_Element> readable = [LR0_Element('\$', t: true)];

//实验1 产生的token列表
List<Token> tokens = [];

//当前状态为初始状态
int get currentState => stateStack[stateStack.length - 1];

//当前分析栈
List<int> stateStack = [0];

// 字符栈 characterStack
// 分析栈里对应的字符是什么，可以是终结符，非终结符，和上面的同步变化
// 记录分析栈字符
// 它们的综合、继承属性也要相应地保存起来
List<LR0_Element> cStk = [LR0_Element('\$', t: true)];

// 临时记录已经弹栈的元素，用于属性传递
// 因为弹出之后再也找不到了
// 保存的顺序和实际顺序相同
List<LR0_Element> pops = [];

Future<List<String>> mainFun(
    {
    // 用来发送信息给其他模块、函数调用
    Message streamController}) async {
  await io.Process.run('test1.exe', []);
  String fs = await io.File('out_file.txt').readAsString();

  fs.split('\n').forEach((element) {
    if (element.isNotEmpty) {
      var s = RegExp(r'\[.*').allMatches(element).first.group(0);
      var typeAndVal = s.substring(2, s.length - 1).split(' ,');
      tokens.add(Token(typeAndVal[0], typeAndVal[1]));
    }
  });

  //求first集
  var hasUpdate = true;
  grammar.forEach((element) {
    first.putIfAbsent(element.left.s, () => Set());
  });
  while (hasUpdate) {
    hasUpdate = false;
    first.forEach((key, value) {
      //遍历每个文法符号的产生式
      grammar.select(key).forEach((lr0) {
        //对当前产生式 S-> 遍历每个S的产生式
        if (lr0.isEpsilon) {
          //是ε，直接结束
          hasUpdate += first.merge(key, ['ε'], allowEpsilon: true);

          return;
        } else {
          var index = 0;
          while (index < lr0.right.length) {
            //merge next first set
            if (lr0.right[index].t) {
              hasUpdate += first.merge(key, [lr0.right[index].s]);
              //到了终结符，停止循环，不再向下查找
              return;
            }
            //先把当前非终结符合并
            hasUpdate += first.merge(key, first[lr0.right[index].s],
                //只有最后一个元素才允许产生空
                allowEpsilon: index == lr0.right.length - 1);
            //在判断是否产生空，是否向下查找
            if (!grammar.select(lr0.right[index].s).hasEpsilon()) {
              //当前产生式结束
              return;
            }
            index++;
          }
        }
      });
    });
  }

  //求follow集
  grammar.forEach((element) {
    follow.putIfAbsent(element.left.s, () => Set());
  });
  hasUpdate = true;
  follow.merge('P', ['\$']);
  while (hasUpdate) {
    hasUpdate = false;
    grammar.forEach((lr0) {
      //遍历每个产生式
      var key = lr0.left.s;
      if (lr0.isEpsilon) {
        //是ε，直接结束，follow集中没有任何价值
        return;
      } else {
        //从前向后扫描
        var index = 0;
        while (index < lr0.right.length) {
          if (lr0.right[index].t) {
            //终结符，没有任何意义
          }

          if (!lr0.right[index].t) {
            if (index == lr0.right.length - 1) {
              hasUpdate += follow.merge(lr0.right[index].s, follow[key]);
            }
            //后续
            var index2 = index + 1;
            while (index2 < lr0.right.length) {
              if (lr0.right[index2].t) {
                //终结符
                // 当前符号查找结束
                hasUpdate +=
                    follow.merge(lr0.right[index].s, [lr0.right[index2].s]);
                break;
                // return; //不能return
              }
              //非终结符
              if (!lr0.right[index2].t) {
                hasUpdate += follow.merge(
                    lr0.right[index].s, first[lr0.right[index2].s]);
                if (!first[lr0.right[index2].s].contains('ε')) {
                  break;
                }
              }
              //当前为非终结符并且包含空，可以继续向下
              if (index2 == lr0.right.length - 1) {
                //最后一个元素了，并且最后一个元素也能产生空
                hasUpdate += follow.merge(lr0.right[index].s, follow[key]);
                break;
              }
              index2++;
            }
          }
          index++;
        }
      }
    });
  }

  //LR0 求状态机
  // print('start state');
  // print((grammar[0].copy).closure());

  //lr0初始状态
  lr0_states.add((grammar[0].copy).closure());

  hasUpdate = true;
  //上一遍新加入的状态，下次从这里开始
  List<List<LR0>> lastNewStates = [];
  lastNewStates.addAll(lr0_states);

  while (hasUpdate) {
    hasUpdate = false;
    // newStates.addAll(lr0_states);
    var state_index = lr0_states.length - lastNewStates.length;
    List<List<LR0>> thisNewStates = [];
    lastNewStates.forEach((lr0_list) {
      List<LR0_Element> expect = [];

      lr0_list.where((element) => !element.isEnd).forEach((element) {
        expect.addAsSet(element.dotNext);
      });

      //当前项集的 出度expect.length ，每一项对应一个新的项集 ，并在states中查重

      expect.forEach((lr0_elem) {
        List<LR0> newState = [];
        lr0_list
            .where((lr0) => !lr0.isEnd && lr0.dotNext.equal(lr0_elem))
            .map((e) => (e.copy..dotPosition += 1))
            .forEach((same_state_closure_origin_lr0) {
          same_state_closure_origin_lr0.closure().forEach((element) {
            newState.addAsSet(element);
          });
        });
        var result = lr0_states.addAsSetWithInfo2(newState);
        if (result[0]) {
          thisNewStates.add(newState);
        }
        hasUpdate += result[0];
        int toState = result[1];
        move.putIfAbsent(state_index, () => []).add({lr0_elem: toState});
      });
      state_index++;
    });
    lastNewStates = thisNewStates;

    // print(lr0_states);
    // lr0_states = newStates;
  }

  move.forEach((key, value) {
    value.forEach((element) {
      element.forEach((key1, value1) {
        readable.addAsSet(key1);
      });
    });
  });
  readable.sort((a, b) {
    if (a.t && !b.t) return -1;
    if (!a.t && b.t) return 1;
    return 0;
  });

  //构造srl分析表,i 为状态
  for (var i = 0; i < lr0_states.length; i++) {
    table.add(List.generate(readable.length, (index) => Action(0)));
    var state = lr0_states[i];
    for (var k = 0; k < readable.length; k++) {
      var readIn = readable[k];
      var nextState = move[i]?.via(readIn) ?? -1;

      if (readIn.t) {
        // action 表

        var hasAction = false;

        //判断归约 ri，
        //需要找到当前状态中能归约的项目
        for (var j = 0; j < state.length; j++) {
          var lr0_item_to_reduce = state[j];
          if (!lr0_item_to_reduce.isEnd) continue;
          //过滤能归约的lr0项目

          //检查读入的字符是否在当前产生式的follow集里面
          if (follow[lr0_item_to_reduce.left.s].contains(readIn.s)) {
            //可以归约，ri，但是需要找到对应的初始产生式序号
            hasAction = true;
            var toFind = lr0_item_to_reduce.normalize;
            table[i][k]
              ..state = toFind.grammarIndex
              ..action = 1;
          } else {
            //默认err
          }
        }

        //已经判断归约，当前字符处理完毕
        // if (hasAction) continue;
        // 是否选择覆盖归约action，也就是 是否移入的优先级比较大
        // 对应于 S->if(C)S.elseS , S->if(C)S.
        // S 的follow中包含了 else
        // 但是读入了else肯定不能归约

        //判断移入 sj
        if (nextState == -1) {
          //默认err
        } else {
          table[i][k]
            ..state = nextState
            ..action = 0;
        }
      }

      if (!readIn.t) {
        // goto 表
        if (nextState == -1) {
          // table[i][k] = Action(0, action: -1); //默认err
        } else {
          table[i][k]
            ..state = nextState
            ..action = 2;
        }
      }
    }
  }

  // print(Token('divider', '\$').columnIndexInTable);
  // 终止状态，手工录入，初始状态的状态集合遇到终结符 就会acc
  // table[5][Token('divider', '\$').columnIndexInTable].action = 5;
  for (var i = 0; i < lr0_states.length; i++) {
    List<LR0> state = lr0_states[i];
    for (var item in state) {
      if (item.left.s == 'P' && item.isEnd) {
        table[i][Token('divider', '\$').columnIndexInTable].action = 5;
      }
    }
  }

  var token_index = 0;

  printInfo(streamController: streamController);

  while (token_index < tokens.length) {
    var token = tokens[token_index];
    var todo = table[currentState][token.columnIndexInTable];
    // print({
    //   'stack': stateStack,
    //   'act': todo.toString(),
    //   'left': tokens.sublist(token_index).map((e) => e.val)
    // });

    if (todo.action == 5) {
      print('acc');
      break;
    }
    if (todo.action == -1) {
      // return;
      print('err');
    }
    if (todo.action == 0) {
      stateStack.add(todo.state);
      cStk.add(token.toLr0_Element());
      // characterStack.add(readable[token.columnIndexInTable]);
      // 只有压栈才能光标右移
      token_index++;
    }
    if (todo.action == 1) {
      var lr0 = grammar[todo.state];
      pops.clear();
      for (var i = 0; i < lr0.right.length; i++) {
        stateStack.removeLast();

        pops.insert(0, cStk.removeLast());
      }
      var toAdd = lr0.left;

      var goto = table[currentState][readable.searchPosition(toAdd)];
      if (goto.action != -1) {
        stateStack.add(goto.state);
        cStk.add(toAdd.copy);
      } else {
        //可能需要错误处理
      }

      //归约，游标并没有向下移动，因为下一次可能继续归约
    }
    //action 2 不会是由读token产生的

    // print('${token.toLr0_Element()} ${lr0_states[currentState]}');
    // 通过事件回调，分离实验2和实验3的逻辑
    streamController?.add({
      'type': 'stack',
      'data': {
        'stack': stateStack,
        'chars': cStk,
        'act': todo,
        'left': tokens.sublist(token_index).map((e) => e.val)
      }
    });
    print({
      'stack': stateStack,
      'chars': cStk,
      'act': todo,
      'left': tokens.sublist(token_index).map((e) => e.val)
    });
  }

  print(stateStack);
  return [];
}

main3Fun() async {
  grammar = grammar3;
  Message controller = Message((event) {
    if (event['type'] == 'stack') {
      var data = event['data'];
      // print('get');
      // print(event['data']);
      Action act = data['act'];

      if (act.action == 1) {
        var g = grammar[act.state];
        print(g);
        print(g.sdtAction);
        g.sdtAction?.call();
      }
      // print(data);
      // if (act.action == 1) {
      //   //归约动作
      //   // print(act.state);
      //   print(act.rGrammar);
      // }
    }
  });

  await mainFun(streamController: controller);

  print(varTable);

  (cStk.top(1).extra['code'] as List).forEach((element) {
    print('${element["instr"]}:${element["s"]}');
  });
}

void main() async {
  await mainFun();
  // main3Fun();
}

// 也可以直接通过全局变量访问
void printInfo({Message streamController}) {
  var index = 0;
  print('grammar');
  grammar.forEach((element) {
    print('$index :　$element');
    index++;
  });

  print('states');
  index = 0;
  lr0_states.forEach((element) {
    print('$index'.width(3) + ' :　$element');
    index++;
  });
  print('first');
  print(first);
  print('follow');
  print(follow);
  print('move');
  print(move);
  print('readable');
  print(readable);

  streamController?.add({'type': 'table', 'data': table});
  print('table');
  index = 0;
  table.forEach((element) {
    print('$index'.width(3) + ' : $element');
    index++;
  });
  print('tokens');
  print(tokens);
  streamController?.add({'type': 'tokens', 'data': tokens});
}
