import http from '@ohos.net.http';

const TS_RING_SIZE = 8 * 1024 * 1024; // 8MB ring buffer

export class HttpTsStreamer {
  private ring: Uint8Array = new Uint8Array(TS_RING_SIZE);
  private writePos: number = 0;
  private readPos: number = 0;
  isEnded: boolean = false;
  hasError: boolean = false;
  private httpRequest: http.HttpRequest | null = null;

  private writeChunk(data: ArrayBuffer): void {
    const bytes = new Uint8Array(data);
    const len = bytes.length;
    if (len === 0) {
      return;
    }
    const writeIdx = this.writePos % TS_RING_SIZE;
    const tail = TS_RING_SIZE - writeIdx;
    if (len <= tail) {
      this.ring.set(bytes, writeIdx);
    } else {
      this.ring.set(bytes.subarray(0, tail), writeIdx);
      this.ring.set(bytes.subarray(tail), 0);
    }
    this.writePos += len;
    // Drop oldest data if buffer overflows
    if (this.writePos - this.readPos > TS_RING_SIZE) {
      this.readPos = this.writePos - TS_RING_SIZE;
    }
  }

  read(outBuffer: ArrayBuffer, length: number): number {
    const available = this.writePos - this.readPos;
    if (available <= 0) {
      if (this.isEnded || this.hasError) {
        return -1;
      }
      return 0; // No data yet, player should retry
    }
    const toRead = Math.min(available, length);
    const readIdx = this.readPos % TS_RING_SIZE;
    const view = new Uint8Array(outBuffer);
    const tail = TS_RING_SIZE - readIdx;
    if (toRead <= tail) {
      view.set(this.ring.subarray(readIdx, readIdx + toRead));
    } else {
      view.set(this.ring.subarray(readIdx, TS_RING_SIZE));
      view.set(this.ring.subarray(0, toRead - tail), tail);
    }
    this.readPos += toRead;
    return toRead;
  }

  buffered(): number {
    return this.writePos - this.readPos;
  }

  start(url: string): void {
    this.httpRequest = http.createHttp();

    this.httpRequest.on('dataReceive', (data: ArrayBuffer) => {
      this.writeChunk(data);
    });

    this.httpRequest.on('dataEnd', () => {
      this.isEnded = true;
    });

    this.httpRequest.requestInStream(url, {
      method: http.RequestMethod.GET,
      connectTimeout: 10000,
      readTimeout: 120000,
      header: {
        'User-Agent': 'HarmonyIPTV/1.0',
        'Accept': '*/*',
        'Connection': 'keep-alive'
      }
    }).catch(() => {
      this.hasError = true;
    });
  }

  stop(): void {
    if (this.httpRequest) {
      try {
        this.httpRequest.off('dataReceive');
        this.httpRequest.off('dataEnd');
        this.httpRequest.destroy();
      } catch {
        // ignore
      }
      this.httpRequest = null;
    }
    this.isEnded = true;
  }
}
