export type Goal = { id: string; label: string };

export type Content = {
  contract_md: string;
  quotes: string[];
  goals: Goal[];
  reflection: string;
  updated_at?: string;
};

export const EMPTY_CONTENT: Content = {
  contract_md: "",
  quotes: [],
  goals: [],
  reflection: "",
};

export function slugId(label: string): string {
  return (
    label
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "")
      .slice(0, 40) || `goal-${Math.random().toString(36).slice(2, 8)}`
  );
}
