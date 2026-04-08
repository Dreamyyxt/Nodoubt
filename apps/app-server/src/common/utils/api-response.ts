export function successResponse<T>(data: T, message = "ok") {
  return {
    code: 0,
    message,
    data,
  };
}

