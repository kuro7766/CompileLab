import 'dart:collection';

import 'lab2.dart';

// lr0 项 扩展函数
extension ListLR0_Ext on List<LR0> {
  List<LR0> select(String s) {
    List<LR0> rt = [];
    grammar.forEach((element) {
      if (element.left.s == s) {
        rt.add(element);
      }
    });
    return rt;
  }

  bool addAsSet(LR0 lr0) {
    var insertable = this.every((element) => !element.equal(lr0));
    if (insertable) {
      this.add(lr0);
    }
    return insertable;
  }

  bool hasEpsilon() {
    for (var i = 0; i < this.length; i++) {
      var lr0 = this[i];
      if (lr0.right.length == 0) {
        return true;
      }
    }
    return false;
  }

  bool equal(List<LR0> other) =>
      this.length == other.length &&
      (() {
        for (var i = 0; i < this.length; i++) {
          if (!this[i].equal(other[i])) {
            return false;
          }
        }
        return true;
      })();
}

// lr0 项 扩展函数
extension ListLR0_Element_Ext on List<LR0_Element> {
  bool addAsSet(LR0_Element lr0_element) {
    var insertable = this.every((element) => !element.equal(lr0_element));
    if (insertable) {
      this.add(lr0_element);
    }
    return insertable;
  }

  int searchPosition(LR0_Element element) {
    for (var i = 0; i < this.length; i++) {
      if (element.equal(this[i])) return i;
    }
    return -1;
  }
}

extension State_Out_Can_Read_Ext on List<Map<LR0_Element, int>> {
  int via(LR0_Element read) {
    for (var i = 0; i < this.length; i++) {
      var mp = this[i];
      var val = null;
      mp.forEach((key, value) {
        if (key.equal(read)) {
          val = value;
          // return value;
        }
      });
      if (val != null) return val;
    }
    return -1;
  }
}

extension List_List_LR0_Ext on List<List<LR0>> {
  bool addAsSet(List<LR0> state) {
    var insertable = this.every((element) => !element.equal(state));
    if (insertable) {
      this.add(state);
    }
    return insertable;
  }

  List<dynamic> addAsSetWithInfo2(List<LR0> state) {
    var i = 0;
    for (; i < this.length; i++) {
      var element = this[i];
      if (element.equal(state)) {
        return [false, i];
      }
    }
    this.add(state);
    return [true, i];
  }
}

extension First_Follow_SetExt on HashMap<String, Set<String>> {
  // return: hasChange
  bool merge(String key, Iterable<String> firstSet,
      {bool allowEpsilon = false}) {
    //有一次变更就变 true
    var hasChange = false;
    firstSet?.forEach((element) {
      if (element == 'ε' && !allowEpsilon) return;
      hasChange = this[key].add(element) ? true : hasChange;
    });
    return hasChange;
  }
}

extension BoolExt on bool {
  // only set to true
  operator +(bool other) => other ? true : this;
}
