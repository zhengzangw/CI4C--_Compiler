# CI4C--\_Compiler

南京大学编译原理实验持续集成方案，基于 [compiler-tests](https://github.com/massimodong/compilers-tests) 改进

## 使用方法

```bash
./autotest.sh path_to_parser_binary
```

使用一次后 `parser` 地址将自动保存

参数含义如下

| 参数         | 作用                  |
| ------------ | --------------------- |
| -h --help    | 帮助信息              |
| -q --quiet   | 静默输出              |
| -l lab_num   | 选择实验，默认全测    |
| -t test_num  | 选择测试集，默认全测  |
| -n file_name | 选择单个测试文件测试  |
| --log        | 输出 log 到 `workdir` |
| -c --clean   | 清理 \*.log 文件      |
| --ins        | 输出中间代码条数      |

## 添加测试集

在 `tests` 目录下添加 `Lab-n` 目录，并在该目录下提供 `check.sh` 文件（错误应返回 1，正确返回 0）。通过添加 `test-n` 文件夹即可添加测试集。

每个测试用例应包含形如 `yourtest.cmm` 和 `yourtest.out` / `yourtest.json` 的两个文件。

## 测试集与测试脚本

### Lab 1

对于没有词法/语法错误的输入，会检查输出是否严格相同。对于有词法/语法错误的输入，只会检查是否报错了。

- `test-1` 为同学贡献的 Lab1 测试用例，包含 dyj 同学生成的大量随机样例。
- `test-2` 为标准样例的普通样例（2020）。
- `test-3` 为标准样例的增强样例（2020），并修改/去除了以下含有错误/歧义的测试文件
  - `L1-A-1-69.cmm`
  - `L1-A-8-41.cmm`
  - `L1-C-{0/1}-*.cmm`

### Lab 2

测试文件 `yourtest.json` 形如下，`require`为必须报告的错误，`allow`为允许你报的其他连带错误。

```json
{
  "require": {
    "e1": [[e1_1, l1_1], [e1_2, l1_2], ...],
    "e2": [[e2_1, l2_1], [e2_2, l2_2], ...],
    ...,
    "ek": [[ek_1, lk_1], [ek_2, lk_2], ...]
  },
  "allow": [[ea_1, la_1], [ea_2, la_2], ...]
}
```

- `test-1` 包括了同学贡献的 Lab2 测试用例和标准样例的普通样例（2020）

### Lab 3

测试文件 `yourtest.json` 形如下，`input` 和 `output` 分别对应输入和输出，也为列表，且列表的所有成员均为整型数。

```json
[
  [input1, output1, ret_val1],
  [input2, output2, ret_val2],
  ...,
  [inputk, outputk, ret_valk]
]
```

- `test-1` 包括了同学贡献的 Lab2 测试用例和标准样例的普通样例（2020）。

## 本地持续集成

可参考 *未公开* 中的 makefile。

## Github 持续集成

Github 持续集成可以让每次有新测试数据的时候在 github 上自动地执行测试脚本。

Fork 本仓库后，在仓库中设置如下 secrets：

1. `LAB_REPO` 编译器实验代码仓库目录，如 username/reponame
2. `GITHUB_PAT` GitHub Prosonal Access Token with repo access

前往 Actions 页面启用即可。
