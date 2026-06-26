import { http } from "@kit.NetworkKit";
import { buffer } from "@kit.ArkTS";
import { UserDatabase } from "../database/UserDatabase";
import { UserPreferenceRepository } from '../repositories/UserPreferenceRepository';
import { AppPreferenceKey } from '../../app/AppConstants';

/**
 * 组件功能简介：
 * - AI 服务配置结构，定义访问模型 API 所需关键参数。
 *
 * 可传入项：
 * - `apiKey`、`baseUrl`、`model`。
 *
 * 返回行为：
 * - 作为 `AIService` 的配置输入与持有结构。
 *
 * 副作用：
 * - 无。
 */
interface AIConfig {
  apiKey: string;
  baseUrl: string;
  model: string;
}

export class AIConfigSnapshot {
  apiKey: string = '';
  baseUrl: string = '';
  model: string = '';

  constructor(apiKey: string = '', baseUrl: string = '', model: string = '') {
    this.apiKey = apiKey;
    this.baseUrl = baseUrl;
    this.model = model;
  }
}

/**
 * 组件功能简介：
 * - AI 对话消息结构，描述一次聊天消息的角色和正文。
 *
 * 可传入项：
 * - `role`、`content`。
 *
 * 返回行为：
 * - 作为聊天请求消息数组中的标准元素。
 *
 * 副作用：
 * - 无。
 */
interface ChatMessage {
  role: "system" | "user" | "assistant";
  content: string;
}

/**
 * 组件功能简介：
 * - AI 服务封装，提供配置加载、连通性测试与流式洞察生成能力。
 *
 * 可传入项：
 * - 构造参数 `apiKey`，以及各公开方法传入的消息/回调参数。
 *
 * 返回行为：
 * - 输出流式请求句柄、测试结果和 AI 文本增量回调。
 *
 * 副作用：
 * - 会读取本地配置并发起网络请求。
 */
export class AIService {
  private static readonly DEFAULT_CONFIG: AIConfig = {
    apiKey: "",
    baseUrl: "",
    model: "",
  };

  private config: AIConfig;
  private userPreferenceRepository: UserPreferenceRepository = new UserPreferenceRepository();

  constructor(apiKey: string = "") {
    this.config = {
      apiKey: AIService.DEFAULT_CONFIG.apiKey,
      baseUrl: AIService.DEFAULT_CONFIG.baseUrl,
      model: AIService.DEFAULT_CONFIG.model,
    };
    if (apiKey.length > 0) {
      this.config.apiKey = apiKey;
    }
  }

  /**
   * 设置 API Key。
   */
  setApiKey(apiKey: string): void {
    this.config.apiKey = apiKey;
  }

  getConfigSnapshot(): AIConfigSnapshot {
    return new AIConfigSnapshot(this.config.apiKey, this.config.baseUrl, this.config.model);
  }

  async loadPersistedOverrides(): Promise<void> {
    if (!UserDatabase.getInstance().isReady()) {
      this.clearConfigCache();
      return;
    }
    this.clearConfigCache();
    const apiKey: string = await this.userPreferenceRepository.getString(AppPreferenceKey.AI_API_KEY, '');
    const baseUrl: string = await this.userPreferenceRepository.getString(AppPreferenceKey.AI_BASE_URL, '');
    const model: string = await this.userPreferenceRepository.getString(AppPreferenceKey.AI_MODEL, '');
    this.config.apiKey = apiKey.trim();
    this.config.baseUrl = this.normalizeBaseUrl(baseUrl);
    this.config.model = model.trim();
  }

  async saveConfig(config: AIConfigSnapshot): Promise<void> {
    const normalizedApiKey: string = config.apiKey.trim();
    const normalizedBaseUrl: string = this.normalizeBaseUrl(config.baseUrl);
    const normalizedModel: string = config.model.trim().length > 0
      ? config.model.trim()
      : '';
    this.config.apiKey = normalizedApiKey;
    this.config.baseUrl = normalizedBaseUrl;
    this.config.model = normalizedModel;
    if (!UserDatabase.getInstance().isReady()) {
      return;
    }
    await this.userPreferenceRepository.setString(AppPreferenceKey.AI_API_KEY, normalizedApiKey);
    await this.userPreferenceRepository.setString(AppPreferenceKey.AI_BASE_URL, normalizedBaseUrl);
    await this.userPreferenceRepository.setString(AppPreferenceKey.AI_MODEL, normalizedModel);
  }

  /**
   * 当前用户是否已完整配置 AI 服务。
   */
  hasUsableConfig(): boolean {
    return this.config.apiKey.length > 0
      && this.config.baseUrl.length > 0
      && this.config.model.length > 0;
  }

  clearConfigCache(): void {
    this.config.apiKey = '';
    this.config.baseUrl = '';
    this.config.model = '';
  }

  /**
   * 流式生成闪记洞察报告。
   * @param ideasContent 闪记内容汇总
   * @param onChunk 每收到一段增量文本时回调
   * @param onDone 流式接收完成时回调
   * @param onError 出错时回调
   * @returns HttpRequest 对象，可调用 destroy() 取消请求；若 API Key 未配置则返回 null
   */
  generateInsightStream(
    ideasContent: string,
    onChunk: (text: string) => void,
    onDone: () => void,
    onError: (error: string) => void,
  ): http.HttpRequest | null {
    if (!this.hasUsableConfig()) {
      onError("AI 功能尚未配置，请先前往“我的”页完成 API Key、Base URL 和 Model 配置。");
      return null;
    }

    const systemPrompt = `你是一个 thoughtful 的思考伙伴和洞察分析师。
用户会分享他们的闪念笔记，这些笔记记录了他们日常的思考、灵感、困惑和感悟。
请基于这些内容，生成一份有深度的洞察报告。

报告要求：
1. 分析用户近期思考的主题和关注点
2. 发现用户思维中的模式和倾向
3. 提供有建设性的反思和建议
4. 用温暖、理解但专业的语气
5. 报告长度适中，结构清晰

报告格式：
## 思考主题
[分析用户主要关注的主题]

## 思维模式
[发现用户思维中的特点和倾向]

## 深度洞察
[提供更深层的分析和解读]

## 成长建议
[给出具体可行的建议]`;

    const messages: ChatMessage[] = [
      { role: "system", content: systemPrompt },
      { role: "user", content: `以下是我最近的闪念笔记：\n\n${ideasContent}` },
    ];

    return this.chatStream(messages, onChunk, onDone, onError);
  }

  /**
   * 测试网络连接。
   */
  async testConnection(): Promise<string> {
    if (!this.hasUsableConfig()) {
      return '请先前往“我的”页完整配置 API Key、Base URL 和 Model';
    }
    const httpRequest = http.createHttp();
    try {
      const result = await httpRequest.request(this.resolveModelsUrl(), {
        method: http.RequestMethod.GET,
        header: {
          "Authorization": `Bearer ${this.config.apiKey}`,
        },
        connectTimeout: 10000,
        readTimeout: 10000,
      });
      if (result.responseCode === 200) {
        return "连接成功";
      }
      return `连接测试失败，状态码: ${result.responseCode}`;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      return `连接测试出错: ${errorMessage}`;
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 流式调用聊天 API（SSE）。
   * 通过 requestInStream + on('dataReceive') 逐 chunk 接收，
   * 从 choices[0].delta.content 提取增量文本。
   * @returns HttpRequest 对象，调用方可通过 destroy() 取消请求
   */
  private chatStream(
    messages: ChatMessage[],
    onChunk: (text: string) => void,
    onDone: () => void,
    onError: (error: string) => void,
  ): http.HttpRequest {
    const httpRequest = http.createHttp();
    let sseBuffer: string = '';
    let hasError: boolean = false;

    // 注册数据接收事件：逐 chunk 解析 SSE 格式
    httpRequest.on('dataReceive', (data: ArrayBuffer) => {
      if (hasError) {
        return;
      }
      const text: string = buffer.from(data).toString('utf-8');
      sseBuffer += text;

      // 按 SSE 事件边界（\n\n）拆分
      const parts: string[] = sseBuffer.split('\n\n');
      // 最后一段可能不完整，留在 buffer 中
      sseBuffer = parts[parts.length - 1];

      for (let i = 0; i < parts.length - 1; i++) {
        const event: string = parts[i].trim();
        if (event.length === 0) {
          continue;
        }
        const lines: string[] = event.split('\n');
        for (let j = 0; j < lines.length; j++) {
          const line: string = lines[j];
          if (!line.startsWith('data: ')) {
            continue;
          }
          const payload: string = line.substring(6).trim();
          if (payload === '[DONE]') {
            continue;
          }
          try {
            const parsed: Record<string, Object> = JSON.parse(payload);
            const choices = parsed.choices as Array<Record<string, Object>>;
            if (choices && choices.length > 0) {
              const delta = choices[0].delta as Record<string, Object>;
              if (delta) {
                const content = delta.content as string;
                if (content && content.length > 0) {
                  onChunk(content);
                }
              }
            }
          } catch (_parseErr) {
            // 单条 SSE 事件解析失败不中断整体流
          }
        }
      }
    });

    // 注册数据接收完成事件
    httpRequest.on('dataEnd', () => {
      if (!hasError) {
        onDone();
      }
    });

    // 发起流式请求
    httpRequest.requestInStream(
      this.resolveChatCompletionsUrl(),
      {
        method: http.RequestMethod.POST,
        header: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${this.config.apiKey}`,
        },
        extraData: JSON.stringify({
          model: this.config.model,
          messages: messages,
          temperature: 0.7,
          max_tokens: 2000,
          stream: true,
        }),
        connectTimeout: 30000,
        readTimeout: 120000,
      },
    ).then((responseCode: number) => {
      if (responseCode !== 200) {
        hasError = true;
        onError(this.resolveHttpError(responseCode));
      }
    }).catch((error: Error) => {
      hasError = true;
      onError(this.resolveNetworkError(error));
    });

    return httpRequest;
  }

  /**
   * 根据 HTTP 状态码返回错误提示。
   */
  private resolveHttpError(code: number): string {
    if (code === 401) {
      return '请求失败：API Key 无效或已过期，请检查配置';
    }
    if (code === 429) {
      return '请求失败：请求过于频繁，请稍后再试';
    }
    if (code === 500 || code === 502 || code === 503) {
      return '请求失败：服务器暂时不可用，请稍后再试';
    }
    return `请求失败，状态码：${code}`;
  }

  /**
   * 根据网络错误类型返回分类提示。
   */
  private resolveNetworkError(error: Error): string {
    const msg: string = error.message;
    if (msg.includes('SSL') || msg.includes('certificate')) {
      return '网络错误：SSL 证书验证失败';
    }
    if (msg.includes('timeout') || msg.includes('Timed out')) {
      return '网络错误：请求超时，请检查网络连接';
    }
    if (msg.includes('ECONNREFUSED') || msg.includes('Connection refused')) {
      return '网络错误：无法连接到服务器';
    }
    if (msg.includes('Network')) {
      return '网络错误：请检查网络连接';
    }
    return `请求出错：${msg}`;
  }

  private normalizeBaseUrl(baseUrl: string): string {
    let normalizedBaseUrl: string = baseUrl.trim().length > 0
      ? baseUrl.trim()
      : '';

    if (normalizedBaseUrl.length === 0) {
      return '';
    }

    while (normalizedBaseUrl.endsWith('/')) {
      normalizedBaseUrl = normalizedBaseUrl.substring(0, normalizedBaseUrl.length - 1);
    }

    if (normalizedBaseUrl.endsWith('/chat/completions')) {
      normalizedBaseUrl = normalizedBaseUrl.substring(
        0,
        normalizedBaseUrl.length - '/chat/completions'.length,
      );
    } else if (normalizedBaseUrl.endsWith('/models')) {
      normalizedBaseUrl = normalizedBaseUrl.substring(0, normalizedBaseUrl.length - '/models'.length);
    }

    if (!/\/v\d+$/.test(normalizedBaseUrl)) {
      normalizedBaseUrl = `${normalizedBaseUrl}/v1`;
    }

    return normalizedBaseUrl;
  }

  private resolveModelsUrl(): string {
    return `${this.normalizeBaseUrl(this.config.baseUrl)}/models`;
  }

  private resolveChatCompletionsUrl(): string {
    return `${this.normalizeBaseUrl(this.config.baseUrl)}/chat/completions`;
  }
}

// 全局单例
const AI_SERVICE: AIService = new AIService();

export function useAIService(): AIService {
  return AI_SERVICE;
}
