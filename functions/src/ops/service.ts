import { logger } from 'firebase-functions/v2';

export interface ClientError {
  message: string;
  stack: string;
  fatal: boolean;
  appVersion: string;
}

/**
 * Writes a sampled web error report to Cloud Logging (ARCH §9). No message
 * content or personal data: the client sends only the error and stack.
 */
export function recordClientError(error: ClientError, uid: string | undefined): void {
  const entry = { ...error, signedIn: uid !== undefined };
  if (error.fatal) {
    logger.error('client_error', entry);
  } else {
    logger.warn('client_error', entry);
  }
}
