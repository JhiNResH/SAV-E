import { ReactNode } from "react";

type OptionalPrivyClient = {
  ready: boolean;
  authenticated: boolean;
  getAccessToken: () => Promise<string | null>;
  login: () => void;
  logout: () => Promise<void>;
};

export function WanderlyPrivyProvider({ children }: { children: ReactNode }) {
  return <>{children}</>;
}

export function useOptionalPrivy(): OptionalPrivyClient | null {
  return null;
}

export function hasPrivyConfig(): boolean {
  return false;
}
