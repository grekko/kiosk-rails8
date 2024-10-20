CREATE TABLE IF NOT EXISTS "schema_migrations" ("version" varchar NOT NULL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS "ar_internal_metadata" ("key" varchar NOT NULL PRIMARY KEY, "value" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "clients" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "orders" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "ordered_at" date NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "drinks" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "price_in_cents" integer DEFAULT 0 NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "order_positions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "order_id" integer NOT NULL, "drink_id" integer NOT NULL, "amount" integer DEFAULT 0 NOT NULL, "price_in_cents" integer DEFAULT 0 NOT NULL, "deposit_in_cents" integer DEFAULT 0 NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "total_price_in_cents"  GENERATED ALWAYS AS (price_in_cents + deposit_in_cents) VIRTUAL /*application='Kiosk'*/, CONSTRAINT "fk_rails_7dbe8a92c4"
FOREIGN KEY ("drink_id")
  REFERENCES "drinks" ("id")
, CONSTRAINT "fk_rails_41ffabeca6"
FOREIGN KEY ("order_id")
  REFERENCES "orders" ("id")
);
CREATE INDEX "index_order_positions_on_order_id" ON "order_positions" ("order_id") /*application='Kiosk'*/;
CREATE INDEX "index_order_positions_on_drink_id" ON "order_positions" ("drink_id") /*application='Kiosk'*/;
CREATE TABLE IF NOT EXISTS "settlements" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "client_id" integer NOT NULL, "generated_at" date NOT NULL, "paid_at" datetime(6), "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_4a7bf0e43f"
FOREIGN KEY ("client_id")
  REFERENCES "clients" ("id")
);
CREATE INDEX "index_settlements_on_client_id" ON "settlements" ("client_id") /*application='Kiosk'*/;
CREATE TABLE IF NOT EXISTS "settlement_positions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "settlement_id" integer NOT NULL, "drink_id" integer NOT NULL, "amount" integer DEFAULT 1 NOT NULL, "price_in_cents" integer DEFAULT 0 NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_643a9db810"
FOREIGN KEY ("settlement_id")
  REFERENCES "settlements" ("id")
, CONSTRAINT "fk_rails_4fbd36354c"
FOREIGN KEY ("drink_id")
  REFERENCES "drinks" ("id")
);
CREATE INDEX "index_settlement_positions_on_settlement_id" ON "settlement_positions" ("settlement_id") /*application='Kiosk'*/;
CREATE INDEX "index_settlement_positions_on_drink_id" ON "settlement_positions" ("drink_id") /*application='Kiosk'*/;
INSERT INTO "schema_migrations" (version) VALUES
('20241020183615'),
('20241020181935'),
('20241020174122'),
('20241020155635'),
('20241020154205'),
('20241020151113'),
('20241020143921');

