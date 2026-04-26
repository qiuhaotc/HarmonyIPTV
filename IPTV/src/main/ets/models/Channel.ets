export class Channel {
  id: string = '';
  name: string = '';
  url: string = '';
  groupTitle: string = '';
  tvgLogo: string = '';
  tvgId: string = '';
  isCustom: boolean = false;

  constructor(id: string, name: string, url: string, groupTitle: string = '', tvgLogo: string = '', tvgId: string = '') {
    this.id = id;
    this.name = name;
    this.url = url;
    this.groupTitle = groupTitle;
    this.tvgLogo = tvgLogo;
    this.tvgId = tvgId;
  }
}
