export interface DocTable {
  headers: readonly string[];
  rows: readonly (readonly string[])[];
}
export interface DocSection {
  title: string;
  paragraphs?: readonly string[];
  bullets?: readonly string[];
  code?: string;
  table?: DocTable;
  note?: string;
}
export interface DocPage {
  navigationTitle: string;
  source?: 'business-rules' | 'requirements' | 'languages';
  slug: string;
  title: string;
  description: string;
  sections: readonly DocSection[];
}
