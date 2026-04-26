import http from '@ohos.net.http';

export class HttpUtil {
  static async fetchText(url: string, timeoutMs: number = 15000): Promise<string> {
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        connectTimeout: timeoutMs,
        readTimeout: timeoutMs,
        header: {
          'User-Agent': 'HarmonyIPTV/1.0',
          'Accept': '*/*'
        }
      });
      if (response.responseCode === 200) {
        return response.result as string;
      }
      throw new Error(`HTTP ${response.responseCode}`);
    } finally {
      httpRequest.destroy();
    }
  }
}
