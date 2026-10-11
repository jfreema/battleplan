/** The Firebase project this code runs in. */
export function projectId(): string {
  return process.env.GCLOUD_PROJECT ?? JSON.parse(process.env.FIREBASE_CONFIG ?? '{}').projectId ?? 'demo-battleplan';
}
