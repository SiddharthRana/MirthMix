import { HttpException, HttpStatus } from '@nestjs/common';
import { ApiProperty } from '@nestjs/swagger';

/** API errors carry a stable machine-readable `code` plus a human message. */
export class ApiError extends HttpException {
  constructor(
    status: HttpStatus,
    code: string,
    message: string,
    extra: Record<string, unknown> = {},
  ) {
    super({ statusCode: status, code, message, ...extra }, status);
  }
}

export class ApiErrorDto {
  @ApiProperty() statusCode: number;
  @ApiProperty() code: string;
  @ApiProperty() message: string;
}
