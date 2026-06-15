// Per-number review memory for the Sendblue iMessage bot.
//
// A review is RECEIPT-GATED: the bot only invites a review right after it logs a
// verified visit (a forwarded receipt), so every stored review is backed by
// proof the person was actually there. This is the core TruCritic property —
// reviews you can trust because a receipt sits behind each one.
//
// Backed by an injected pg-pool-like query function (NOT the pool directly),
// same pattern as the place/receipt stores, so no circular import on server.ts.

export type StoredReview = {
  merchant: string;
  rating?: number;
  text?: string;
  createdAt?: Date;
};

export type Queryable = {
  query: (sql: string, values?: unknown[]) => Promise<{ rows: Record<string, unknown>[] }>;
};

export interface ReviewStore {
  /** Record a receipt-gated review for a phone. Returns the phone's total review count. */
  save(phone: string, review: StoredReview): Promise<number>;
  /** Most-recent reviews for a phone (default limit 15). */
  list(phone: string, limit?: number): Promise<StoredReview[]>;
}

export const reviewsTableSql = `
create table if not exists sendblue_reviews (
  id serial primary key,
  phone text not null,
  merchant text not null,
  rating int,
  text text,
  created_at timestamptz not null default now()
);
create index if not exists sendblue_reviews_phone_created_idx
  on sendblue_reviews (phone, created_at desc);
`;

export class PgReviewStore implements ReviewStore {
  constructor(private readonly db: Queryable) {}

  async save(phone: string, review: StoredReview): Promise<number> {
    const rating =
      typeof review.rating === "number" && review.rating >= 1 && review.rating <= 5
        ? Math.round(review.rating)
        : null;
    await this.db.query(
      `insert into sendblue_reviews (phone, merchant, rating, text)
       values ($1, $2, $3, $4)`,
      [phone, review.merchant.trim(), rating, review.text?.slice(0, 2000) || null],
    );
    const counted = await this.db.query(
      `select count(*)::int as count from sendblue_reviews where phone = $1`,
      [phone],
    );
    const count = counted.rows[0]?.count;
    return typeof count === "number" ? count : Number(count ?? 0);
  }

  async list(phone: string, limit = 15): Promise<StoredReview[]> {
    const { rows } = await this.db.query(
      `select merchant, rating, text, created_at
       from sendblue_reviews
       where phone = $1
       order by created_at desc
       limit $2`,
      [phone, limit],
    );
    return rows.map((row) => ({
      merchant: String(row.merchant ?? ""),
      rating: typeof row.rating === "number" ? row.rating : row.rating ? Number(row.rating) : undefined,
      text: row.text ? String(row.text) : undefined,
      createdAt: row.created_at instanceof Date ? row.created_at : undefined,
    }));
  }
}
