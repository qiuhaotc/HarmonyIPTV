import { Channel } from '../models/Channel';
import { ChannelGroup } from '../models/ChannelGroup';

interface ExtInfInfo {
  name: string;
  groupTitle: string;
  tvgLogo: string;
  tvgId: string;
}

export class M3uParser {
  static parse(content: string): ChannelGroup[] {
    const lines = content.split(/\r?\n/);
    const groupMap = new Map<string, ChannelGroup>();
    const ungrouped = new ChannelGroup('未分组');
    let pendingInfo: ExtInfInfo | null = null;
    let channelIndex = 0;

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();
      if (!line) {
        continue;
      }
      if (line.startsWith('#EXTM3U')) {
        continue;
      }
      if (line.startsWith('#EXTINF:')) {
        pendingInfo = M3uParser.parseExtInf(line);
        continue;
      }
      if (line.startsWith('#')) {
        continue;
      }
      // This is a URL line
      if (M3uParser.isValidUrl(line)) {
        channelIndex++;
        const id = `ch_${channelIndex}_${Date.now()}`;
        const name = pendingInfo !== null ? (pendingInfo.name || `频道${channelIndex}`) : `频道${channelIndex}`;
        const group = pendingInfo !== null ? pendingInfo.groupTitle : '';
        const logo = pendingInfo !== null ? pendingInfo.tvgLogo : '';
        const tvgId = pendingInfo !== null ? pendingInfo.tvgId : '';

        const channel = new Channel(id, name, line, group, logo, tvgId);

        if (group) {
          if (!groupMap.has(group)) {
            groupMap.set(group, new ChannelGroup(group));
          }
          groupMap.get(group)!.channels.push(channel);
        } else {
          ungrouped.channels.push(channel);
        }
        pendingInfo = null;
      }
    }

    const result: ChannelGroup[] = [];
    groupMap.forEach((g) => result.push(g));
    if (ungrouped.channels.length > 0) {
      result.push(ungrouped);
    }
    return result;
  }

  private static parseExtInf(line: string): ExtInfInfo {
    let name = '';
    let groupTitle = '';
    let tvgLogo = '';
    let tvgId = '';

    // Extract tvg-id
    const tvgIdMatch = line.match(/tvg-id="([^"]*)"/);
    if (tvgIdMatch) {
      tvgId = tvgIdMatch[1];
    }

    // Extract tvg-name
    const tvgNameMatch = line.match(/tvg-name="([^"]*)"/);
    if (tvgNameMatch) {
      name = tvgNameMatch[1];
    }

    // Extract tvg-logo
    const tvgLogoMatch = line.match(/tvg-logo="([^"]*)"/);
    if (tvgLogoMatch) {
      tvgLogo = tvgLogoMatch[1];
    }

    // Extract group-title
    const groupMatch = line.match(/group-title="([^"]*)"/);
    if (groupMatch) {
      groupTitle = groupMatch[1];
    }

    // Extract channel name (after the last comma)
    const commaIdx = line.lastIndexOf(',');
    if (commaIdx >= 0 && !name) {
      name = line.substring(commaIdx + 1).trim();
    }

    return { name, groupTitle, tvgLogo, tvgId };
  }

  private static isValidUrl(line: string): boolean {
    return line.startsWith('http://') ||
      line.startsWith('https://') ||
      line.startsWith('rtsp://') ||
      line.startsWith('rtmp://') ||
      line.startsWith('rtp://');
  }
}
