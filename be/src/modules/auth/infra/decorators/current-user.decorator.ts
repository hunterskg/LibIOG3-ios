import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { UserRes } from '../../../user/domain/dtos/res.dto';

export const CurrentUser = createParamDecorator(
  (data: keyof UserRes | undefined, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest<{ user?: UserRes }>();
    const user = request.user;
    return data ? user?.[data] : user;
  },
);
