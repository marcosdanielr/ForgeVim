import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

/** Resolve conditional classes before merging conflicting Tailwind utilities. */
export function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs));
}
