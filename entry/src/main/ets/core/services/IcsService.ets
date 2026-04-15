import { fileIo as fs, ReadOptions } from '@kit.CoreFileKit';
import { buffer } from '@kit.ArkTS';

const ICS_LINE_BREAK = '\r\n';
const ICS_FOLD_LIMIT = 75;
const DEFAULT_ICS_PROD_ID = '-//youyeyejie//Zhixing ActHub//CN';

/**
 * ICS 参数定义，对应 `NAME;KEY=VALUE` 中的参数部分。
 */
export class IcsParameter {
  name: string = '';
  values: string[] = [];

  constructor(name: string = '', values: string[] = []) {
    this.name = name;
    this.values = values;
  }
}

/**
 * ICS 属性定义，对应一条 content line。
 */
export class IcsProperty {
  name: string = '';
  parameters: IcsParameter[] = [];
  value: string = '';

  constructor(name: string = '', value: string = '', parameters: IcsParameter[] = []) {
    this.name = name;
    this.value = value;
    this.parameters = parameters;
  }
}

/**
 * ICS 文件头定义，承载 `VCALENDAR` 级别属性。
 */
export class IcsHeader {
  version: string = '2.0';
  prodId: string = '';
  calScale: string = '';
  method: string = '';
  properties: IcsProperty[] = [];
}

/**
 * ICS 事件项定义，聚焦 `VEVENT` 的 MVP 常用字段。
 */
export class IcsItem {
  uid: string = '';
  dtStamp: string = '';
  dtStart: string = '';
  dtEnd: string = '';
  summary: string = '';
  description: string = '';
  location: string = '';
  sequence: string = '';
  status: string = '';
  categories: string[] = [];
  properties: IcsProperty[] = [];
}

/**
 * 其他 ICS 组件定义，用于保留 `VEVENT` 之外的内容。
 */
export class IcsComponent {
  name: string = '';
  properties: IcsProperty[] = [];
  children: IcsComponent[] = [];

  constructor(name: string = '') {
    this.name = name;
  }
}

/**
 * ICS 文件对象定义。
 */
export class IcsFile {
  header: IcsHeader = new IcsHeader();
  items: IcsItem[] = [];
  others: IcsComponent[] = [];
}

class ParsedContentLine {
  name: string = '';
  parameters: IcsParameter[] = [];
  value: string = '';
}

/**
 * 类功能简介：
 * - 提供最小可用的 iCalendar(ICS) 文件读写能力。
 * - 当前聚焦 `VCALENDAR` / `VEVENT`，并保留其他组件原始属性，便于后续扩展 `VTODO`、`VTIMEZONE`。
 *
 * 可传入项：
 * - `fromIcs(file)` 传入已打开的 `fs.File` 读取并解析。
 * - `toIcs(icsFile, file)` 传入内存对象与已打开的 `fs.File` 写出。
 *
 * 返回行为：
 * - `fromIcs()` 返回解析后的 `IcsFile`。
 * - `toIcs()` 将内容写入目标文件，不关闭文件句柄。
 *
 * 副作用：
 * - `toIcs()` 会从当前文件起始位置覆盖写入；若目标文件已有更长旧内容，调用方应确保使用空文件或截断后的文件。
 */
export class IcsService {
  fromIcs(file: fs.File): IcsFile {
    const content: string = this.readFileAsString(file);
    const unfoldedLines: string[] = this.unfoldLines(content);
    const icsFile: IcsFile = new IcsFile();
    const componentStack: IcsComponent[] = [];

    for (let index = 0; index < unfoldedLines.length; index++) {
      const rawLine: string = unfoldedLines[index].trim();
      if (rawLine.length === 0) {
        continue;
      }

      if (rawLine.startsWith('BEGIN:')) {
        const componentName: string = rawLine.substring('BEGIN:'.length).trim().toUpperCase();
        if (componentName === 'VCALENDAR') {
          continue;
        }

        const component: IcsComponent = new IcsComponent(componentName);
        if (componentStack.length > 0) {
          componentStack[componentStack.length - 1].children.push(component);
        } else if (componentName !== 'VEVENT') {
          icsFile.others.push(component);
        }
        componentStack.push(component);
        continue;
      }

      if (rawLine.startsWith('END:')) {
        const componentName: string = rawLine.substring('END:'.length).trim().toUpperCase();
        if (componentName === 'VCALENDAR') {
          continue;
        }

        if (componentStack.length > 0) {
          const completedComponent: IcsComponent = componentStack.pop() as IcsComponent;
          if (completedComponent.name === 'VEVENT') {
            icsFile.items.push(this.toIcsItem(completedComponent));
          }
        }
        continue;
      }

      const parsedLine: ParsedContentLine = this.parseContentLine(rawLine);
      if (componentStack.length === 0) {
        this.applyHeaderProperty(icsFile.header, parsedLine);
      } else {
        componentStack[componentStack.length - 1].properties.push(
          new IcsProperty(parsedLine.name, parsedLine.value, parsedLine.parameters)
        );
      }
    }

    return icsFile;
  }

  eventsToIcs(icsFile: IcsFile, file: fs.File): void {
    const normalized: IcsFile = new IcsFile();
    normalized.items = icsFile.items;
    normalized.others = icsFile.others;
    normalized.header.version = '2.0';
    normalized.header.prodId = DEFAULT_ICS_PROD_ID;
    normalized.header.calScale = 'GREGORIAN';
    normalized.header.method = '';
    this.toIcs(normalized, file);
  }

  toIcs(icsFile: IcsFile, file: fs.File): void {
    const lines: string[] = [];
    lines.push('BEGIN:VCALENDAR');
    lines.push(this.serializeProperty(this.buildHeaderProperty(
      'VERSION',
      icsFile.header.version.length > 0 ? icsFile.header.version : '2.0'
    )));

    if (icsFile.header.prodId.length > 0) {
      lines.push(this.serializeProperty(this.buildHeaderProperty('PRODID', icsFile.header.prodId)));
    }
    if (icsFile.header.calScale.length > 0) {
      lines.push(this.serializeProperty(this.buildHeaderProperty('CALSCALE', icsFile.header.calScale)));
    }
    if (icsFile.header.method.length > 0) {
      lines.push(this.serializeProperty(this.buildHeaderProperty('METHOD', icsFile.header.method)));
    }

    for (let index = 0; index < icsFile.header.properties.length; index++) {
      const property: IcsProperty = icsFile.header.properties[index];
      if (this.isKnownHeaderProperty(property.name)) {
        continue;
      }
      lines.push(this.serializeProperty(property));
    }

    for (let index = 0; index < icsFile.items.length; index++) {
      const item: IcsItem = icsFile.items[index];
      lines.push('BEGIN:VEVENT');
      const itemProperties: IcsProperty[] = this.buildItemProperties(item);
      for (let propertyIndex = 0; propertyIndex < itemProperties.length; propertyIndex++) {
        lines.push(this.serializeProperty(itemProperties[propertyIndex]));
      }
      lines.push('END:VEVENT');
    }

    for (let index = 0; index < icsFile.others.length; index++) {
      this.appendComponentLines(icsFile.others[index], lines);
    }

    lines.push('END:VCALENDAR');
    const serialized: string = lines.join(ICS_LINE_BREAK) + ICS_LINE_BREAK;
    fs.writeSync(file.fd, serialized);
  }

  private readFileAsString(file: fs.File): string {
    const chunkSize: number = 4096;
    const chunks: string[] = [];
    let offset: number = 0;
    let bytesRead: number = 0;

    do {
      const arrayBuffer: ArrayBuffer = new ArrayBuffer(chunkSize);
      const readOptions: ReadOptions = {
        offset: offset,
        length: chunkSize
      };
      bytesRead = fs.readSync(file.fd, arrayBuffer, readOptions);
      if (bytesRead > 0) {
        chunks.push(buffer.from(arrayBuffer, 0, bytesRead).toString());
        offset += bytesRead;
      }
    } while (bytesRead > 0);

    return chunks.join('');
  }

  private unfoldLines(content: string): string[] {
    const normalized: string = content.replace(/\r\n/g, '\n').replace(/\r/g, '\n');
    const folded: string[] = normalized.split('\n');
    const result: string[] = [];

    for (let index = 0; index < folded.length; index++) {
      const currentLine: string = folded[index];
      if (currentLine.length === 0) {
        result.push('');
        continue;
      }

      const firstChar: string = currentLine.substring(0, 1);
      if ((firstChar === ' ' || firstChar === '\t') && result.length > 0) {
        const previousIndex: number = result.length - 1;
        result[previousIndex] = result[previousIndex] + currentLine.substring(1);
      } else {
        result.push(currentLine);
      }
    }

    return result;
  }

  private parseContentLine(line: string): ParsedContentLine {
    const parsed: ParsedContentLine = new ParsedContentLine();
    const colonIndex: number = this.findValueSeparator(line);
    const nameAndParams: string = colonIndex >= 0 ? line.substring(0, colonIndex) : line;
    parsed.value = colonIndex >= 0 ? line.substring(colonIndex + 1) : '';

    const parts: string[] = nameAndParams.split(';');
    parsed.name = parts[0].trim().toUpperCase();
    for (let index = 1; index < parts.length; index++) {
      const parameter: IcsParameter | null = this.parseParameter(parts[index]);
      if (parameter !== null) {
        parsed.parameters.push(parameter);
      }
    }
    return parsed;
  }

  private findValueSeparator(line: string): number {
    let quoted: boolean = false;
    for (let index = 0; index < line.length; index++) {
      const currentChar: string = line.substring(index, index + 1);
      if (currentChar === '"') {
        quoted = !quoted;
      } else if (currentChar === ':' && !quoted) {
        return index;
      }
    }
    return -1;
  }

  private parseParameter(rawParameter: string): IcsParameter | null {
    const equalIndex: number = rawParameter.indexOf('=');
    if (equalIndex <= 0) {
      return null;
    }

    const name: string = rawParameter.substring(0, equalIndex).trim().toUpperCase();
    const valueText: string = rawParameter.substring(equalIndex + 1);
    const values: string[] = this.splitParameterValues(valueText);
    return new IcsParameter(name, values);
  }

  private splitParameterValues(valueText: string): string[] {
    const values: string[] = [];
    let current: string = '';
    let quoted: boolean = false;

    for (let index = 0; index < valueText.length; index++) {
      const currentChar: string = valueText.substring(index, index + 1);
      if (currentChar === '"') {
        quoted = !quoted;
        continue;
      }
      if (currentChar === ',' && !quoted) {
        values.push(current);
        current = '';
        continue;
      }
      current += currentChar;
    }
    values.push(current);
    return values;
  }

  private applyHeaderProperty(header: IcsHeader, parsedLine: ParsedContentLine): void {
    const property: IcsProperty = new IcsProperty(parsedLine.name, parsedLine.value, parsedLine.parameters);
    header.properties.push(property);

    switch (parsedLine.name) {
      case 'VERSION':
        header.version = parsedLine.value;
        break;
      case 'PRODID':
        header.prodId = this.decodeTextValue(parsedLine.value);
        break;
      case 'CALSCALE':
        header.calScale = parsedLine.value;
        break;
      case 'METHOD':
        header.method = parsedLine.value;
        break;
      default:
        break;
    }
  }

  private toIcsItem(component: IcsComponent): IcsItem {
    const item: IcsItem = new IcsItem();
    for (let index = 0; index < component.properties.length; index++) {
      const property: IcsProperty = component.properties[index];
      switch (property.name) {
        case 'UID':
          item.uid = this.decodeTextValue(property.value);
          break;
        case 'DTSTAMP':
          item.dtStamp = property.value;
          break;
        case 'DTSTART':
          item.dtStart = property.value;
          break;
        case 'DTEND':
          item.dtEnd = property.value;
          break;
        case 'SUMMARY':
          item.summary = this.decodeTextValue(property.value);
          break;
        case 'DESCRIPTION':
          item.description = this.decodeTextValue(property.value);
          break;
        case 'LOCATION':
          item.location = this.decodeTextValue(property.value);
          break;
        case 'SEQUENCE':
          item.sequence = property.value;
          break;
        case 'STATUS':
          item.status = property.value;
          break;
        case 'CATEGORIES':
          item.categories = this.parseTextList(property.value);
          break;
        default:
          break;
      }
      item.properties.push(property);
    }
    return item;
  }

  private parseTextList(rawValue: string): string[] {
    const values: string[] = [];
    let current: string = '';
    let escaping: boolean = false;

    for (let index = 0; index < rawValue.length; index++) {
      const currentChar: string = rawValue.substring(index, index + 1);
      if (escaping) {
        current += '\\' + currentChar;
        escaping = false;
        continue;
      }
      if (currentChar === '\\') {
        escaping = true;
        continue;
      }
      if (currentChar === ',') {
        values.push(this.decodeTextValue(current));
        current = '';
        continue;
      }
      current += currentChar;
    }
    values.push(this.decodeTextValue(current));
    return values;
  }

  private decodeTextValue(value: string): string {
    return value
      .replace(/\\\\/g, '\u0000')
      .replace(/\\n/gi, '\n')
      .replace(/\\,/g, ',')
      .replace(/\\;/g, ';')
      .replace(/\u0000/g, '\\');
  }

  private encodeTextValue(value: string): string {
    return value
      .replace(/\\/g, '\\\\')
      .replace(/\r\n/g, '\n')
      .replace(/\r/g, '\n')
      .replace(/\n/g, '\\n')
      .replace(/,/g, '\\,')
      .replace(/;/g, '\\;');
  }

  private buildHeaderProperty(name: string, value: string): IcsProperty {
    const property: IcsProperty = new IcsProperty();
    property.name = name;
    if (name === 'PRODID') {
      property.value = this.encodeTextValue(value);
    } else {
      property.value = value;
    }
    return property;
  }

  private buildItemProperties(item: IcsItem): IcsProperty[] {
    const properties: IcsProperty[] = [];

    if (item.uid.length > 0) {
      properties.push(new IcsProperty('UID', this.encodeTextValue(item.uid)));
    }
    if (item.dtStamp.length > 0) {
      properties.push(new IcsProperty('DTSTAMP', item.dtStamp));
    }
    if (item.dtStart.length > 0) {
      properties.push(new IcsProperty('DTSTART', item.dtStart));
    }
    if (item.dtEnd.length > 0) {
      properties.push(new IcsProperty('DTEND', item.dtEnd));
    }
    if (item.summary.length > 0) {
      properties.push(new IcsProperty('SUMMARY', this.encodeTextValue(item.summary)));
    }
    if (item.description.length > 0) {
      properties.push(new IcsProperty('DESCRIPTION', this.encodeTextValue(item.description)));
    }
    if (item.location.length > 0) {
      properties.push(new IcsProperty('LOCATION', this.encodeTextValue(item.location)));
    }
    if (item.sequence.length > 0) {
      properties.push(new IcsProperty('SEQUENCE', item.sequence));
    }
    if (item.status.length > 0) {
      properties.push(new IcsProperty('STATUS', item.status));
    }
    if (item.categories.length > 0) {
      const encodedCategories: string[] = [];
      for (let index = 0; index < item.categories.length; index++) {
        encodedCategories.push(this.encodeTextValue(item.categories[index]));
      }
      properties.push(new IcsProperty('CATEGORIES', encodedCategories.join(',')));
    }

    for (let index = 0; index < item.properties.length; index++) {
      const property: IcsProperty = item.properties[index];
      if (this.isKnownItemProperty(property.name)) {
        continue;
      }
      properties.push(property);
    }

    return properties;
  }

  private appendComponentLines(component: IcsComponent, lines: string[]): void {
    lines.push(`BEGIN:${component.name}`);
    for (let index = 0; index < component.properties.length; index++) {
      lines.push(this.serializeProperty(component.properties[index]));
    }
    for (let index = 0; index < component.children.length; index++) {
      this.appendComponentLines(component.children[index], lines);
    }
    lines.push(`END:${component.name}`);
  }

  private serializeProperty(property: IcsProperty): string {
    let line: string = property.name;
    for (let index = 0; index < property.parameters.length; index++) {
      const parameter: IcsParameter = property.parameters[index];
      const renderedValues: string[] = [];
      for (let valueIndex = 0; valueIndex < parameter.values.length; valueIndex++) {
        renderedValues.push(this.quoteParameterValueIfNeeded(parameter.values[valueIndex]));
      }
      line += `;${parameter.name}=${renderedValues.join(',')}`;
    }
    line += `:${property.value}`;
    return this.foldLine(line);
  }

  private quoteParameterValueIfNeeded(value: string): string {
    if (value.indexOf(':') >= 0 || value.indexOf(';') >= 0 || value.indexOf(',') >= 0) {
      return `"${value}"`;
    }
    return value;
  }

  private foldLine(line: string): string {
    if (line.length <= ICS_FOLD_LIMIT) {
      return line;
    }

    let folded: string = '';
    let start: number = 0;
    while (start < line.length) {
      const end: number = Math.min(start + ICS_FOLD_LIMIT, line.length);
      const chunk: string = line.substring(start, end);
      if (start === 0) {
        folded += chunk;
      } else {
        folded += ICS_LINE_BREAK + ' ' + chunk;
      }
      start = end;
    }
    return folded;
  }

  private isKnownHeaderProperty(name: string): boolean {
    return name === 'VERSION' || name === 'PRODID' || name === 'CALSCALE' || name === 'METHOD';
  }

  private isKnownItemProperty(name: string): boolean {
    return name === 'UID'
      || name === 'DTSTAMP'
      || name === 'DTSTART'
      || name === 'DTEND'
      || name === 'SUMMARY'
      || name === 'DESCRIPTION'
      || name === 'LOCATION'
      || name === 'SEQUENCE'
      || name === 'STATUS'
      || name === 'CATEGORIES';
  }
}
