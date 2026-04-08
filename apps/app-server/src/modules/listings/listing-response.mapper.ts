type JsonLike = Record<string, unknown>;

function normalizeValue(value: unknown): unknown {
  if (Array.isArray(value)) {
    return value.map(normalizeValue);
  }

  if (value instanceof Date) {
    return value.toISOString();
  }

  if (value && typeof value === "object") {
    if (
      "toNumber" in (value as Record<string, unknown>) &&
      typeof (value as { toNumber?: unknown }).toNumber === "function"
    ) {
      return (value as { toNumber: () => number }).toNumber();
    }

    return Object.fromEntries(
      Object.entries(value as JsonLike).map(([key, nestedValue]) => [key, normalizeValue(nestedValue)]),
    );
  }

  return value;
}

export function mapListingResponse<T>(payload: T): T {
  return normalizeValue(payload) as T;
}
