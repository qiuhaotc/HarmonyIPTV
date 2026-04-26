import { Channel } from './Channel';

export class ChannelGroup {
  name: string = '';
  channels: Channel[] = [];
  expanded: boolean = true;

  constructor(name: string) {
    this.name = name;
  }
}
