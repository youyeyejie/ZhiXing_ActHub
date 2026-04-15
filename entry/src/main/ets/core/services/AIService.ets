import { http } from "@kit.NetworkKit";

/**
 * AI 服务配置。
 */
interface AIConfig {
  apiKey: string;
  baseUrl: string;
  model: string;
}

/**
 * AI 聊天消息。
 */
interface ChatMessage {
  role: "system" | "user" | "assistant";
  content: string;
}

/**
 * AI 服务。
 * 提供与 DeepSeek API 的交互能力。
 */
export class AIService {
  private static readonly DEFAULT_CONFIG: AIConfig = {
    apiKey: "",
    baseUrl: "https://api.deepseek.com",
    model: "deepseek-chat",
  };

  private config: AIConfig;

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

  /**
   * 检查是否已配置 API Key。
   */
  hasApiKey(): boolean {
    return this.config.apiKey.length > 0;
  }

  /**
   * 生成闪记洞察报告。
   * @param ideasContent 闪记内容汇总
   * @returns AI 生成的洞察报告
   */
  async generateInsight(ideasContent: string): Promise<string> {
    if (!this.hasApiKey()) {
      return "请先配置 DeepSeek API Key。在设置页面可以输入您的 API Key。";
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

    return this.chat(messages);
  }

  /**
   * 测试网络连接。
   */
  async testConnection(): Promise<string> {
    const httpRequest = http.createHttp();
    try {
      const result = await httpRequest.request(`${this.config.baseUrl}/v1/models`, {
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
   * 调用聊天 API。
   */
  private async chat(messages: ChatMessage[]): Promise<string> {
    const httpRequest = http.createHttp();
    try {
      const result = await httpRequest.request(`${this.config.baseUrl}/v1/chat/completions`, {
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
        }),
        connectTimeout: 30000,
        readTimeout: 90000,
      });

      if (result.responseCode === 200 && result.result) {
        try {
          const data: Record<string, Object> = JSON.parse(result.result as string);

          // 检查 API 返回的错误
          if (data.error) {
            const errorObj = data.error as Record<string, string>;
            const errorMsg = errorObj.message || JSON.stringify(data.error);
            return `API 错误：${errorMsg}`;
          }

          const choices = data.choices as Array<Record<string, Object>>;
          if (choices && choices.length > 0) {
            const message = choices[0].message as Record<string, string>;
            if (message && message.content) {
              return message.content;
            }
          }
          return "解析响应失败：无法获取消息内容";
        } catch (parseError) {
          return `解析响应失败：${parseError instanceof Error ? parseError.message : String(parseError)}`;
        }
      }

      // 处理特定的 HTTP 错误码
      if (result.responseCode === 401) {
        return "请求失败：API Key 无效或已过期，请检查配置";
      }
      if (result.responseCode === 429) {
        return "请求失败：请求过于频繁，请稍后再试";
      }
      if (result.responseCode === 500 || result.responseCode === 502 || result.responseCode === 503) {
        return "请求失败：服务器暂时不可用，请稍后再试";
      }

      return `请求失败，状态码：${result.responseCode}`;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      // 分类常见网络错误
      if (errorMessage.includes("SSL") || errorMessage.includes("certificate")) {
        return "网络错误：SSL 证书验证失败";
      }
      if (errorMessage.includes("timeout") || errorMessage.includes("Timed out")) {
        return "网络错误：请求超时，请检查网络连接";
      }
      if (errorMessage.includes("ECONNREFUSED") || errorMessage.includes("Connection refused")) {
        return "网络错误：无法连接到服务器";
      }
      if (errorMessage.includes("Network")) {
        return "网络错误：请检查网络连接";
      }
      return `请求出错：${errorMessage}`;
    } finally {
      httpRequest.destroy();
    }
  }
}

// 全局单例
const AI_SERVICE: AIService = new AIService();

export function useAIService(): AIService {
  return AI_SERVICE;
}
