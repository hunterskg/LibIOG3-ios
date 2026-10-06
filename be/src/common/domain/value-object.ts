export interface ValueObject<T> {
  equals(vo?: ValueObject<T>): boolean;
}
