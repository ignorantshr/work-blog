编写的一个小脚本，将mkdown文档转换为reStructuredText 文档。

支持的语法：

- 斜体
- 粗体
- 引用
- 图片
- 超连接
- 代码块
- 标题

不支持嵌套语法，比如***粗些体***。

支持目录或单个文件的转换。

```python
# coding=utf-8
import os


def _replace(string, old, sub, start, count=None):
    string_left = string[0:start]
    string_right = string[start:]

    if count is not None:
        string_right = string_right.replace(old, sub, count)
    else:
        string_right = string_right.replace(old, sub)
    return string_left + string_right


class mkdown2ReStructuredText:

    def __init__(self):
        pass

    _replace_level_char = {
        1: '=',
        2: '-',
        3: '^',
        4: "'",
        5: "'",
        6: "'",
    }

    def _nums_head(self, tmp_string):
        n = 0
        while tmp_string[n:n + 1] == '#':
            n += 1

        return n

    def _replace_line_block(self, line):
        left_right = 'left'
        location = -3
        while location <= len(line):
            location = line.find("`", location + 3)
            if location == -1:
                break
            if left_right == 'left':
                left_right = 'right'
                if location != 0:
                    line = _replace(line, "`", " ``", location, 1)
                else:
                    line = _replace(line, "`", "``", location, 1)
            else:
                left_right = 'left'
                line = _replace(line, "`", "`` ", location, 1)

        return line

    def _replace_img(self, line):
        location_left = line.find("![")
        if location_left != -1:
            location_tmp_left = line.find("](", location_left)
            # location_right = line.find(")", location_tmp_left)
            line = line.replace(line[location_left:location_tmp_left + 2],
                                " .. image:: ", 1)
            line = line.replace(")", "")

        return line

    def _replace_link(self, line):
        img = line.find('![')
        if img != -1:
            return line

        mid = line.find('](')
        while mid != -1:
            left = line.rfind('[', 0, mid)
            right = line.find(')', mid)
            if left == 0:
                line = _replace(line, '[', '`', left, 1)
            else:
                line = _replace(line, '[', ' `', left, 1)
            line = _replace(line, ')', '>`_ ', right, 1)
            line = _replace(line, '](', ' <', mid, 1)
            mid = line.find('](', right + 2)

        return line

    def _replace_quote(self, line):
        if line.startswith(">"):
            line = line.replace(">", "    ", 1)
        if line.startswith("    >"):
            line = line.replace("    >", "    ", 1)
        if line.startswith("\t>"):
            line = line.replace("\t>", "    ", 1)

        return line

    def _replace_header(self, line):
        if line.startswith('#'):
            level = self._nums_head(line)
            line = line.replace("#" * level, '', 1)
            return '\r\n' + line.lstrip() + \
                self._replace_level_char[level] * 80 + '\r\n'

        return line

    def _replace_bold(self, line):
        left_right = 'left'
        location = -3
        while location <= len(line):
            location = line.find("**", location + 3)
            if location == -1:
                break
            if line[location:location + 3] == '***' \
                    or line[location - 1:location + 2] == '***' \
                    or line[location - 2:location + 1] == '***':
                continue
            if left_right == 'left':
                left_right = 'right'
                if location != 0:
                    line = _replace(line, "**", " **", location, 1)
            else:
                left_right = 'left'
                line = _replace(line, "**", "** ", location, 1)

        return line

    # convert italic
    def _replace_italic(self, line):
        left_right = 'left'
        location = -2
        while location <= len(line):
            location = line.find("*", location + 2)
            if location == -1:
                break
            if line[location + 1] == '*' or line[location - 1] == '*':
                continue
            if line[location:location + 3] == '***' \
                    or line[location - 1:location + 2] == '***' \
                    or line[location - 2:location + 1] == '***':
                continue
            if left_right == 'left':
                left_right = 'right'
                if location != 0:
                    line = _replace(line, "*", " *", location, 1)
            else:
                left_right = 'left'
                line = _replace(line, "*", "* ", location, 1)

        return line

    # convert bold_italic to bold
    def _replace_bold_italic(self, line):
        left_right = 'left'
        location = -4
        while location <= len(line):
            location = line.find("***", location + 4)
            if location == -1:
                break
            if left_right == 'left':
                left_right = 'right'
                if location != 0:
                    line = _replace(line, "***", " **", location, 1)
                else:
                    line = _replace(line, "***", "**", location, 1)
            else:
                left_right = 'left'
                line = _replace(line, "***", "** ", location, 1)

        return line

    def _handle_line_inner(self, line):
        line = self._replace_line_block(line)
        line = self._replace_img(line)
        line = self._replace_quote(line)
        line = self._replace_link(line)
        line = self._replace_header(line)
        line = self._replace_italic(line)
        line = self._replace_bold(line)
        line = self._replace_bold_italic(line)
        return line

    def _convert(self, source_path, dst_path):
        with open(source_path, 'r') as f:
            origin_lines = f.readlines()
        result_lines = []
        inner_block = False
        start_block = False

        for line in origin_lines:
            if line.startswith("```"):
                inner_block = not inner_block
                if not start_block:
                    result_lines.append('::\n\t\r\n')
                    start_block = not start_block
                else:
                    result_lines.append('\r\n')
                    start_block = not start_block
                continue
            if inner_block:
                result_lines.append('    ' + line)
                continue
            result_lines.append(self._handle_line_inner(line))

        tpm_file = os.path.basename(source_path)
        with open(os.path.join(dst_path, tpm_file[:len(tpm_file) - 2] + "rst"), 'w') as f:
            f.writelines(result_lines)

    def _list_dir(self, source_dir, dst_dir):
        source_files = os.listdir(source_dir)
        for f in source_files:
            current_f = os.path.join(source_dir, f)
            if os.path.isdir(current_f):
                current_dst_dir = os.path.join(dst_dir, f)
                if not os.path.exists(current_dst_dir):
                    os.mkdir(current_dst_dir)
                self._list_dir(current_f, current_dst_dir)
            elif os.path.isfile(current_f):
                if f.endswith('.md'):
                    self._convert(current_f, dst_dir)
                else:
                    with open(os.path.join(dst_dir, f), "wb") as copy_file:
                        with open(current_f, "rb") as copied_file:
                            copy_file.write(copied_file.read())

    def convert_from_dir(self, source_path, destination_path):
        self._list_dir(
            os.path.normpath(source_path),
            os.path.normpath(destination_path))

    def convert_from_file(self, source_file, destination_path):
        self._convert(
            os.path.normpath(source_file),
            os.path.normpath(destination_path))


# 路径中存在中文时需要解码
# c = mkdown2ReStructuredText()
# c.convert_from_dir('D:/mkdocs/work/docs/虚拟机转换'.decode('utf-8'), 'D:\AtomDoc\docs\source\Operation\Vm_convert')
# c.convert_from_file('D:/mkdocs/work/docs/虚拟机转换/virt-p2v介绍.md'.decode('utf-8'), 'D:\AtomDoc\docs\source\Operation\Vm_convert')
```

