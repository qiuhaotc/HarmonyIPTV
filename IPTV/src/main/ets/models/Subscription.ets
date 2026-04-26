export class Subscription {
  id: string = '';
  name: string = '';
  url: string = '';
  lastUpdated: number = 0;
  enabled: boolean = true;

  constructor(id: string, name: string, url: string) {
    this.id = id;
    this.name = name;
    this.url = url;
    this.lastUpdated = 0;
    this.enabled = true;
  }
}
