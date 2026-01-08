CREATE TABLE IF NOT EXISTS "schema_migrations" ("version" varchar NOT NULL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS "ar_internal_metadata" ("key" varchar NOT NULL PRIMARY KEY, "value" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "clients" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "suspended_at" datetime(6) /*application='Kiosk'*/, "access_uuid" text, "email" text);
CREATE TABLE IF NOT EXISTS "orders" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "ordered_at" date NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "order_positions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "order_id" integer NOT NULL, "drink_id" integer NOT NULL, "amount" integer DEFAULT 0 NOT NULL, "price_in_cents" integer DEFAULT 0 NOT NULL, "deposit_in_cents" integer DEFAULT 0 NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "total_price_in_cents"  GENERATED ALWAYS AS (price_in_cents + deposit_in_cents) VIRTUAL /*application='Kiosk'*/, CONSTRAINT "fk_rails_7dbe8a92c4"
FOREIGN KEY ("drink_id")
  REFERENCES "drinks" ("id")
, CONSTRAINT "fk_rails_41ffabeca6"
FOREIGN KEY ("order_id")
  REFERENCES "orders" ("id")
);
CREATE INDEX "index_order_positions_on_order_id" ON "order_positions" ("order_id") /*application='Kiosk'*/;
CREATE INDEX "index_order_positions_on_drink_id" ON "order_positions" ("drink_id") /*application='Kiosk'*/;
CREATE TABLE IF NOT EXISTS "settlement_positions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "settlement_id" integer NOT NULL, "drink_id" integer NOT NULL, "amount" integer DEFAULT 1 NOT NULL, "price_in_cents" integer DEFAULT 0 NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_643a9db810"
FOREIGN KEY ("settlement_id")
  REFERENCES "settlements" ("id")
, CONSTRAINT "fk_rails_4fbd36354c"
FOREIGN KEY ("drink_id")
  REFERENCES "drinks" ("id")
);
CREATE INDEX "index_settlement_positions_on_settlement_id" ON "settlement_positions" ("settlement_id") /*application='Kiosk'*/;
CREATE INDEX "index_settlement_positions_on_drink_id" ON "settlement_positions" ("drink_id") /*application='Kiosk'*/;
CREATE TABLE IF NOT EXISTS "drinks" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "price_in_cents" integer DEFAULT 0 NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "settlement_prices" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "drink_id" integer NOT NULL, "valid_from" date NOT NULL, "price_in_cents" integer DEFAULT 0 NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "deactivated_at" datetime(6) /*application='Kiosk'*/, CONSTRAINT "fk_rails_c777451a4b"
FOREIGN KEY ("drink_id")
  REFERENCES "drinks" ("id")
);
CREATE INDEX "index_settlement_prices_on_drink_id" ON "settlement_prices" ("drink_id") /*application='Kiosk'*/;
CREATE TABLE IF NOT EXISTS "monthly_reports" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "title" text, "description" text, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "active_storage_blobs" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "key" varchar NOT NULL, "filename" varchar NOT NULL, "content_type" varchar, "metadata" text, "service_name" varchar NOT NULL, "byte_size" bigint NOT NULL, "checksum" varchar, "created_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_active_storage_blobs_on_key" ON "active_storage_blobs" ("key") /*application='Kiosk'*/;
CREATE TABLE IF NOT EXISTS "active_storage_attachments" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "record_type" varchar NOT NULL, "record_id" bigint NOT NULL, "blob_id" bigint NOT NULL, "created_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_c3b3935057"
FOREIGN KEY ("blob_id")
  REFERENCES "active_storage_blobs" ("id")
);
CREATE INDEX "index_active_storage_attachments_on_blob_id" ON "active_storage_attachments" ("blob_id") /*application='Kiosk'*/;
CREATE UNIQUE INDEX "index_active_storage_attachments_uniqueness" ON "active_storage_attachments" ("record_type", "record_id", "name", "blob_id") /*application='Kiosk'*/;
CREATE TABLE IF NOT EXISTS "active_storage_variant_records" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "blob_id" bigint NOT NULL, "variation_digest" varchar NOT NULL, CONSTRAINT "fk_rails_993965df05"
FOREIGN KEY ("blob_id")
  REFERENCES "active_storage_blobs" ("id")
);
CREATE UNIQUE INDEX "index_active_storage_variant_records_uniqueness" ON "active_storage_variant_records" ("blob_id", "variation_digest") /*application='Kiosk'*/;
CREATE TABLE IF NOT EXISTS "settlements" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "client_id" integer NOT NULL, "generated_at" date NOT NULL, "paid_at" datetime(6), "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "aasm_state" varchar DEFAULT 'draft' NOT NULL, "completed_at" datetime(6), "monthly_report_id" integer NOT NULL, "payment_id" integer, "email_sent_at" datetime(6), CONSTRAINT "fk_rails_4a7bf0e43f"
FOREIGN KEY ("client_id")
  REFERENCES "clients" ("id")
, CONSTRAINT "fk_rails_5c7519b292"
FOREIGN KEY ("monthly_report_id")
  REFERENCES "monthly_reports" ("id")
, CONSTRAINT "fk_rails_6ad2b9e368"
FOREIGN KEY ("payment_id")
  REFERENCES "payments" ("id")
);
CREATE INDEX "index_settlements_on_client_id" ON "settlements" ("client_id") /*application='Kiosk'*/;
CREATE INDEX "index_settlements_on_monthly_report_id" ON "settlements" ("monthly_report_id") /*application='Kiosk'*/;
CREATE INDEX "index_settlements_on_payment_id" ON "settlements" ("payment_id") /*application='Kiosk'*/;
CREATE UNIQUE INDEX "index_clients_on_access_uuid" ON "clients" ("access_uuid");
CREATE UNIQUE INDEX "index_clients_on_email" ON "clients" ("email");
CREATE TABLE IF NOT EXISTS "payments" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "client_id" integer NOT NULL, "amount_in_cents" integer DEFAULT 0 NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_66d0485df7"
FOREIGN KEY ("client_id")
  REFERENCES "clients" ("id")
);
CREATE INDEX "index_payments_on_client_id" ON "payments" ("client_id") /*application='Kiosk'*/;
INSERT INTO "schema_migrations" (version) VALUES
('20260108174900'),
('20251224082432'),
('20251224081714'),
('20251221192317'),
('20250905045403'),
('20250207171219'),
('20250207170802'),
('20250207093528'),
('20250207090317'),
('20250207090131'),
('20241021080852'),
('20241020213220'),
('20241020210147'),
('20241020183615'),
('20241020181935'),
('20241020174122'),
('20241020155635'),
('20241020154205'),
('20241020151113'),
('20241020143921');

