# Kiosk

Kiosk tracks a shared drinks fridge: drinks are bought in, people take them, and once a month each person gets a bill. Clients see German text in the UI and emails; the admin UI is in English.

## Stock

**Drink**:
A kind of beverage the kiosk stocks and sells, such as "Pils". It has a default price (UI: "Default Price"), which a Settlement Price can override.

**Order**:
A purchase that restocks Drinks, dated by when it was ordered and optionally carrying its invoice.
_Avoid_: Purchase, delivery

**Order Position**:
One line of an Order: a Drink, an amount, its price and its deposit.

**Drink Inventory**:
How many of each Drink are left: the ordered count minus the settled count, valued at purchase price and selling price (UI: "Inventory").
_Avoid_: Stock count

## Billing

**Client**:
A person who takes drinks from the kiosk and gets billed. A Client can be suspended (no longer active) and reinstated.
_Avoid_: Customer, user (and don't confuse this with `KioskApi::Client`, the API wrapper)

**Client Page**:
The Client's own page, reached through a private link without a login, showing their Outstanding Balance, their Settlements ("Abrechnungen") and how to pay.

**Monthly Report**:
One month's tally, titled like "Januar 2026", with the inventory sheet attached (image or PDF). It is either draft or completed; completing is a manual marker that can be undone.

**Settlement**:
One Client's bill for one Monthly Report (German: "Abrechnung"). States: **draft** (being edited), **completed** (final, counts toward the Client's Outstanding Balance), **paid** (covered by a Payment).
_Avoid_: Invoice, bill

**Settlement Position**:
One line of a Settlement: a Drink and an amount, priced from the Drink's price on the Settlement's date. The price is fixed when the position is created.

**Settlement Price**:
A dated selling price for a Drink, valid from a given day until a newer one starts; it can be deactivated (UI: "Prices").

**Settlement Email**:
The email that tells a Client their Settlement is ready, subject "Comuna Kühlschrank Abrechnung [<report title>]". It is sent at most once per Settlement.

**Settlement Tracking**:
The link in the Settlement Email. The first click records when the Client opened it, notifies the kiosk ("Kiosk Mail [<report title>] geöffnet von <name>"), and forwards to the Client Page.

**Payment**:
Money received from a Client. It covers completed Settlements oldest first and marks them paid; any amount left over that is too small to cover the next Settlement is ignored.

**Outstanding Balance**:
The sum of a Client's completed, unpaid Settlements (German: "Deckel", the Client's tab).

## Access

**API token**:
The one shared secret that grants full access to the `/api` JSON API. There is no per-Client scoping, so treat it like the admin password.
