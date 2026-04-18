import { AppState, useAppState } from '../../../app/AppStates';

// ---- 数据模型 ----

/**
 * Markdown 行内分段（加粗/代码/普通文本）。
 */
export class MarkdownSegment {
  text: string;
  bold: boolean;
  code: boolean;

  constructor(text: string, bold: boolean, code: boolean) {
    this.text = text;
    this.bold = bold;
    this.code = code;
  }
}

/**
 * Markdown 块级元素。
 */
export class MarkdownBlock {
  type: string; // heading2 | heading3 | listItem | codeBlock | paragraph | spacer
  content: string;
  segments: MarkdownSegment[];

  constructor(type: string, content: string, segments: MarkdownSegment[]) {
    this.type = type;
    this.content = content;
    this.segments = segments;
  }
}

// ---- 解析器 ----

/**
 * 解析行内 Markdown 语法（**加粗**、`代码`）为分段数组。
 */
function parseInlineSegments(text: string): MarkdownSegment[] {
  const segments: MarkdownSegment[] = [];
  let i = 0;
  let buffer = '';
  let inBold = false;
  let inCode = false;

  while (i < text.length) {
    const ch = text.charAt(i);

    // 内联代码
    if (ch === '`' && !inBold) {
      if (inCode) {
        segments.push(new MarkdownSegment(buffer, false, true));
        buffer = '';
        inCode = false;
        i++;
        continue;
      } else {
        if (buffer.length > 0) {
          segments.push(new MarkdownSegment(buffer, false, false));
          buffer = '';
        }
        inCode = true;
        i++;
        continue;
      }
    }

    if (inCode) {
      buffer += ch;
      i++;
      continue;
    }

    // 加粗
    if (ch === '*' && i + 1 < text.length && text.charAt(i + 1) === '*') {
      if (inBold) {
        segments.push(new MarkdownSegment(buffer, true, false));
        buffer = '';
        inBold = false;
        i += 2;
        continue;
      } else {
        if (buffer.length > 0) {
          segments.push(new MarkdownSegment(buffer, false, false));
          buffer = '';
        }
        inBold = true;
        i += 2;
        continue;
      }
    }

    buffer += ch;
    i++;
  }

  // 剩余内容
  if (buffer.length > 0) {
    segments.push(new MarkdownSegment(buffer, inBold, inCode));
  }

  return segments;
}

/**
 * 将 Markdown 文本解析为块级元素数组。
 */
export function parseMarkdown(raw: string): MarkdownBlock[] {
  const lines = raw.split('\n');
  const blocks: MarkdownBlock[] = [];
  let inCodeBlock = false;
  let codeBuffer = '';

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];

    // 代码块开关
    if (line.trimStart().startsWith('```')) {
      if (inCodeBlock) {
        blocks.push(new MarkdownBlock('codeBlock', codeBuffer, []));
        codeBuffer = '';
        inCodeBlock = false;
      } else {
        inCodeBlock = true;
      }
      continue;
    }

    if (inCodeBlock) {
      if (codeBuffer.length > 0) {
        codeBuffer += '\n';
      }
      codeBuffer += line;
      continue;
    }

    const trimmed = line.trim();

    // 空行
    if (trimmed.length === 0) {
      blocks.push(new MarkdownBlock('spacer', '', []));
      continue;
    }

    // 标题
    if (trimmed.startsWith('### ')) {
      blocks.push(new MarkdownBlock('heading3', trimmed.substring(4), []));
      continue;
    }
    if (trimmed.startsWith('## ')) {
      blocks.push(new MarkdownBlock('heading2', trimmed.substring(3), []));
      continue;
    }
    if (trimmed.startsWith('# ')) {
      blocks.push(new MarkdownBlock('heading2', trimmed.substring(2), []));
      continue;
    }

    // 列表项
    if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
      const content = trimmed.substring(2);
      blocks.push(new MarkdownBlock('listItem', content, parseInlineSegments(content)));
      continue;
    }

    // 有序列表（1. 2. 等开头）
    if (trimmed.length >= 3) {
      let numEnd = 0;
      while (numEnd < trimmed.length && trimmed.charAt(numEnd) >= '0' && trimmed.charAt(numEnd) <= '9') {
        numEnd++;
      }
      if (numEnd > 0 && numEnd < trimmed.length && trimmed.charAt(numEnd) === '.') {
        const afterDot = numEnd + 1;
        if (afterDot < trimmed.length && trimmed.charAt(afterDot) === ' ') {
          const content = trimmed.substring(afterDot + 1);
          blocks.push(new MarkdownBlock('listItem', content, parseInlineSegments(content)));
          continue;
        }
      }
    }

    // 普通段落
    blocks.push(new MarkdownBlock('paragraph', trimmed, parseInlineSegments(trimmed)));
  }

  // 未闭合的代码块
  if (inCodeBlock && codeBuffer.length > 0) {
    blocks.push(new MarkdownBlock('codeBlock', codeBuffer, []));
  }

  return blocks;
}

// ---- 渲染组件 ----

/**
 * 简易 Markdown 渲染器。
 * 将 Markdown 文本解析后用 ArkUI 原生组件渲染。
 */
@ComponentV2
export struct MarkdownRenderer {
  @Local private app: AppState = useAppState();
  @Param text: string = '';

  build() {
    Column({ space: 0 }) {
      ForEach(
        parseMarkdown(this.text),
        (block: MarkdownBlock, index: number) => {
          if (block.type === 'heading2') {
            Text(block.content)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.app.theme.palette.textPrimary)
              .width('100%')
              .margin({ top: 16, bottom: 8 })
          } else if (block.type === 'heading3') {
            Text(block.content)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.app.theme.palette.textPrimary)
              .width('100%')
              .margin({ top: 12, bottom: 6 })
          } else if (block.type === 'listItem') {
            Row({ space: 0 }) {
              Text('  \u2022  ')
                .fontSize(15)
                .fontColor(this.app.theme.palette.textSecondary)
                .lineHeight(24)
              this.buildSegments(block.segments)
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)
            .margin({ top: 2, bottom: 2 })
          } else if (block.type === 'codeBlock') {
            Column() {
              Text(block.content)
                .fontSize(13)
                .fontColor(this.app.theme.palette.textPrimary)
                .fontFamily('monospace')
                .lineHeight(20)
                .width('100%')
            }
            .width('100%')
            .padding(12)
            .borderRadius(8)
            .backgroundColor(this.app.theme.palette.surfaceSecondary)
            .margin({ top: 4, bottom: 4 })
          } else if (block.type === 'spacer') {
            Column().height(6)
          } else {
            // paragraph
            this.buildParagraph(block.segments)
          }
        },
        (_block: MarkdownBlock, index: number) => `md_block_${index}_${_block.type}_${_block.content.length}`,
      )
    }
    .width('100%')
  }

  @Builder
  private buildParagraph(segments: MarkdownSegment[]) {
    if (segments.length === 0) {
      Blank()
    } else if (segments.length === 1 && !segments[0].bold && !segments[0].code) {
      Text(segments[0].text)
        .fontSize(15)
        .fontColor(this.app.theme.palette.textPrimary)
        .lineHeight(24)
        .width('100%')
        .margin({ top: 2, bottom: 2 })
    } else {
      Text() {
        ForEach(
          segments,
          (seg: MarkdownSegment, segIdx: number) => {
            if (seg.code) {
              Span(` ${seg.text} `)
                .fontSize(13)
                .fontFamily('monospace')
                .fontColor(this.app.theme.palette.textPrimary)
            } else if (seg.bold) {
              Span(seg.text)
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.app.theme.palette.textPrimary)
            } else {
              Span(seg.text)
                .fontSize(15)
                .fontColor(this.app.theme.palette.textPrimary)
            }
          },
          (_seg: MarkdownSegment, segIdx: number) => `seg_${segIdx}_${_seg.text.length}`,
        )
      }
      .lineHeight(24)
      .width('100%')
      .margin({ top: 2, bottom: 2 })
    }
  }

  @Builder
  private buildSegments(segments: MarkdownSegment[]) {
    if (segments.length === 0) {
      Blank()
    } else if (segments.length === 1 && !segments[0].bold && !segments[0].code) {
      Text(segments[0].text)
        .fontSize(15)
        .fontColor(this.app.theme.palette.textPrimary)
        .lineHeight(24)
        .layoutWeight(1)
    } else {
      Text() {
        ForEach(
          segments,
          (seg: MarkdownSegment, segIdx: number) => {
            if (seg.code) {
              Span(` ${seg.text} `)
                .fontSize(13)
                .fontFamily('monospace')
                .fontColor(this.app.theme.palette.textPrimary)
            } else if (seg.bold) {
              Span(seg.text)
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.app.theme.palette.textPrimary)
            } else {
              Span(seg.text)
                .fontSize(15)
                .fontColor(this.app.theme.palette.textPrimary)
            }
          },
          (_seg: MarkdownSegment, segIdx: number) => `lseg_${segIdx}_${_seg.text.length}`,
        )
      }
      .lineHeight(24)
      .layoutWeight(1)
    }
  }
}
