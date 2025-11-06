export class AppError extends Error {
  code: string;
  status: number;
  detail?: any;
  constructor(code: string, status = 400, message?: string, detail?: any) {
    super(message ?? code);
    this.code = code;
    this.status = status;
    this.detail = detail;
  }
}
