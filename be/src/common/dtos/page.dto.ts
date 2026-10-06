export class PageReq {
  page: number;
  size: number;
}

export class Page<T> {
  data: T[];
  total: number;
  req: PageReq;

  static of<T>(data: T[], total: number, req: PageReq): Page<T> {
    const page = new Page<T>();
    page.data = data;
    page.total = total;
    page.req = req;
    return page;
  }
}
