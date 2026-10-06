import {
  registerDecorator,
  ValidationArguments,
  ValidationOptions,
} from 'class-validator';

export function AtLeastNonEmpty(
  min?: number,
  validationOptions?: ValidationOptions,
): ClassDecorator {
  return function (target: Function) {
    registerDecorator({
      name: 'atLeastNonEmpty',
      target,
      propertyName: '',
      options: validationOptions,
      constraints: [min],
      validator: {
        validate(_: unknown, args: ValidationArguments) {
          const [n] = args.constraints as [number | undefined];
          if (n == null || n < 1) return true;

          const obj = args.object as Record<string, unknown>;
          const keys = Object.keys(obj);

          // ponytail: chi dem field cap 1 khong rong (null/undefined/''/trim/empty array), nang cap khi can deep check
          const count = keys.reduce((acc, k) => {
            const v = obj[k];
            const isEmpty =
              v === undefined ||
              v === null ||
              v === '' ||
              (typeof v === 'string' && v.trim() === '') ||
              (Array.isArray(v) && v.length === 0);
            return isEmpty ? acc : acc + 1;
          }, 0);

          return count >= n;
        },
        defaultMessage(args: ValidationArguments) {
          const [n] = args.constraints;
          return `Ít nhất ${n} trường không được để trống`;
        },
      },
    });
  };
}
