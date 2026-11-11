# Week 45 — Normalization: Exercises

> [!IMPORTANT]
> **_How to Complete These Exercises_**
> Write your answers directly in the highlighted **Your Answer** / **Your SQL** fields below each task. Replace the placeholder text with your own work before submitting.

---

## 1. TrailShop Project Task

### Task 1.1: Analyze a Denormalized Table

Consider this denormalized table that TrailShop's old system used:

```
supplier_products(
    supplier_id, supplier_name, supplier_email, supplier_city,
    product_id, product_name, category_id, category_name,
    supply_price, lead_time_days
)
```

Sample data:

| supplier_id | supplier_name | supplier_email      | supplier_city | product_id | product_name    | category_id | category_name | supply_price | lead_time_days |
| ----------- | ------------- | ------------------- | ------------- | ---------- | --------------- | ----------- | ------------- | ------------ | -------------- |
| 1           | NordGear Oy   | info@nordgear.fi    | Helsinki      | 101        | Trail Runner X  | 10          | Footwear      | 45.00        | 7              |
| 1           | NordGear Oy   | info@nordgear.fi    | Helsinki      | 102        | Summit Boot     | 10          | Footwear      | 62.00        | 7              |
| 2           | OutdoorPro AB | sales@outdoorpro.se | Stockholm     | 201        | Rain Jacket Pro | 30          | Clothing      | 55.00        | 14             |
| 2           | OutdoorPro AB | sales@outdoorpro.se | Stockholm     | 101        | Trail Runner X  | 10          | Footwear      | 43.00        | 10             |

**Tasks:**

1. Identify the primary key of this table.
   > [!NOTE]
   > **_Your Answer_**
   >
   > The primary key is the composite key **{supplier_id, product_id}**. Neither column is unique alone (supplier 1 appears twice and product 101 appears twice), but the combination of a supplier and a product identifies exactly one row: it is one supplier offering one product at one price and lead time.
2. Identify any insertion, update, and deletion anomalies (give specific examples).
   > [!NOTE]
   > **_Your Answer_**
   >
   > **Insertion anomaly:** I can't store a new supplier (for example supplier 3) until they supply at least one product, because every row needs a product_id as part of the key. In the same way I can't add a new product or a new category (for example "Camping") before some supplier supplies it.
   >
   > **Update anomaly:** The same facts are repeated in several rows. NordGear's email appears in 2 rows, "Trail Runner X" and its category appear in rows 1 and 4, and "Footwear" appears in 3 rows. If NordGear changes its email or Footwear is renamed, I have to update every row, and if I miss one the data becomes inconsistent.
   >
   > **Deletion anomaly:** If I delete row 3 (OutdoorPro AB supplying Rain Jacket Pro), I also lose the only record that product 201 "Rain Jacket Pro" and the category 30 "Clothing" exist. If a supplier's only row is deleted, the supplier's contact details disappear too.
3. Normalize this table to 3NF. Show each step (1NF, then 2NF, then 3NF) with the resulting tables.
   > [!NOTE]
   > **_Your Answer_**
   >
   > **Dependencies I found** (PK = {supplier_id, product_id}):
   >
   > - supplier_id → supplier_name, supplier_email, supplier_city (partial dependency)
   > - product_id → product_name, category_id (partial dependency)
   > - category_id → category_name (transitive: product_id → category_id → category_name)
   > - {supplier_id, product_id} → supply_price, lead_time_days (full dependency; the price and lead time are different for each supplier-product pair, for example product 101 costs 45.00 from supplier 1 and 43.00 from supplier 2)
   >
   > **Step 1, 1NF:** All values are atomic, there are no repeating groups and the table has a primary key, so it is already in 1NF.
   >
   > **Step 2, 2NF:** I remove the partial dependencies by moving the attributes that depend on only part of the key into their own tables:
   >
   > ```text
   > suppliers(supplier_id PK, supplier_name, supplier_email, supplier_city)
   > products(product_id PK, product_name, category_id, category_name)
   > supplier_products(supplier_id FK, product_id FK, supply_price, lead_time_days)  PK: {supplier_id, product_id}
   > ```
   >
   > **Step 3, 3NF:** In `products`, category_name depends on category_id, which is not the key (transitive dependency), so I split it out. `suppliers` and `supplier_products` have no transitive dependencies.
   >
   > ```text
   > suppliers(supplier_id PK, supplier_name, supplier_email, supplier_city)
   > categories(category_id PK, category_name)
   > products(product_id PK, product_name, category_id FK -> categories)
   > supplier_products(supplier_id FK, product_id FK, supply_price, lead_time_days)  PK: {supplier_id, product_id}
   > ```
   >
   > Now every non-key attribute depends on the key, the whole key and nothing but the key. The decomposition is lossless because I can rebuild the original table by joining the four tables on their keys.
   >
   > ```sql
   > CREATE TABLE suppliers (
   >     supplier_id    INTEGER PRIMARY KEY,
   >     supplier_name  VARCHAR(100) NOT NULL,
   >     supplier_email VARCHAR(255) NOT NULL UNIQUE,
   >     supplier_city  VARCHAR(100)
   > );
   >
   > CREATE TABLE categories (
   >     category_id   INTEGER PRIMARY KEY,
   >     category_name VARCHAR(100) NOT NULL UNIQUE
   > );
   >
   > CREATE TABLE products (
   >     product_id   INTEGER PRIMARY KEY,
   >     product_name VARCHAR(200) NOT NULL,
   >     category_id  INTEGER NOT NULL REFERENCES categories(category_id)
   > );
   >
   > CREATE TABLE supplier_products (
   >     supplier_id    INTEGER NOT NULL REFERENCES suppliers(supplier_id),
   >     product_id     INTEGER NOT NULL REFERENCES products(product_id),
   >     supply_price   NUMERIC(10,2) NOT NULL CHECK (supply_price > 0),
   >     lead_time_days INTEGER NOT NULL CHECK (lead_time_days >= 0),
   >     PRIMARY KEY (supplier_id, product_id)
   > );
   > ```
 
### Task 1.2: Review Your Existing TrailShop Schema
 
1. For each table, confirm it is in 3NF by verifying:
   - No partial dependencies (check tables with composite keys or surrogate keys)
   - No transitive dependencies
   > [!NOTE]
   > **_Your Answer_**
   >
   > All my tables have a single-column surrogate primary key, so a partial dependency is impossible (there is no "part" of the key). That means every table in 1NF is automatically in 2NF. I then checked each one for transitive dependencies:
   >
   > - **customers** (customer_id PK): first_name, last_name, email, phone and created_at all describe the customer and depend only on customer_id. No non-key column determines another. **3NF ✓**
   > - **categories** (category_id PK): the name and description depend only on category_id. **3NF ✓**
   > - **products** (product_id PK): name, description, price, stock and weight depend only on product_id. The category is stored only as the foreign key category_id, and the category name is not repeated here. **3NF ✓**
   > - **orders** (order_id PK): customer_id, order_date and status depend only on order_id. Customer details are not repeated, only the foreign key. **3NF ✓**
   > - **order_items** (order_item_id PK): order_id, product_id, quantity and unit_price all describe that one order line. Product name and category are not stored here. **3NF ✓**
   >
   > If I treat {order_id, product_id} as the natural key of order_items, quantity and unit_price still depend on the whole pair and not on only one of them, so there is no partial dependency there either. My schema is in 3NF.
2. Explain why `unit_price` in `order_items` is NOT a normalization violation.
   > [!NOTE]
   > **_Your Answer_**
   >
   > `unit_price` in `order_items` is not the same fact as `products.price`. `products.price` is the current price of the product, while `order_items.unit_price` is the price that was actually charged on that specific order line at the time of sale. It depends on the order item (the order and product together) and not on product_id alone, so it is not a partial or transitive dependency. It is also not a copy that I have to keep in sync: if the product's price changes later, old orders must keep their original price, so the value has to be stored with the order line. Removing it would make historical orders change whenever prices change.
### Task 1.3: Add a Suppliers Table (Optional Extension)
 
You may skip this task. Suppliers are not part of the TrailShop project schema.
 
If TrailShop wanted to track suppliers:
 
1. Design a normalized schema that includes suppliers. Consider:
   - Each product can have multiple suppliers
   - Each supplier offers different prices and lead times
   - Each supplier has contact info (name, email, city)
2. Write the `CREATE TABLE` statements.
   > [!NOTE]
   > **_Your SQL_**
   >
   > ```sql
   > -- Supplier facts live in suppliers (depend only on supplier_id)
   > CREATE TABLE suppliers (
   >     supplier_id   SERIAL PRIMARY KEY,
   >     company_name  VARCHAR(200) NOT NULL UNIQUE,
   >     contact_name  VARCHAR(150),
   >     email         VARCHAR(255) NOT NULL UNIQUE,
   >     city          VARCHAR(100)
   > );
   >
   > -- Many-to-many between products and suppliers. Price and lead time depend on the
   > -- combination of product and supplier, so they belong in the junction table.
   > CREATE TABLE product_suppliers (
   >     product_id     INTEGER NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
   >     supplier_id    INTEGER NOT NULL REFERENCES suppliers(supplier_id) ON DELETE RESTRICT,
   >     supply_price   NUMERIC(10,2) NOT NULL CHECK (supply_price > 0),
   >     lead_time_days INTEGER NOT NULL CHECK (lead_time_days >= 0),
   >     PRIMARY KEY (product_id, supplier_id)
   > );
   > ```
3. Verify your design is in 3NF.
> [!NOTE]
> **_Your Answer_**
>
> - **suppliers:** single-column PK, so no partial dependencies. company_name, contact_name, email and city all depend directly on supplier_id, and none of them determines another. 3NF ✓
> - **product_suppliers:** the PK is {product_id, supplier_id}. supply_price and lead_time_days depend on the whole pair, since the same product has a different price and lead time from each supplier, and neither depends on only the product or only the supplier. There is no non-key attribute that determines another. 3NF ✓
> - **products** (existing) is unchanged, so it stays in 3NF.
 
---

## 2. Theory Review Questions
 
Answer in your own words (2–4 sentences each):
 
1. What is normalization, and what problem does it solve?
> [!NOTE]
> **_Your Answer_**
>
> Normalization is the process of splitting poorly structured tables into smaller, well-structured ones so that each fact is stored in exactly one place. It solves the problem of redundancy, which causes insertion, update and deletion anomalies and inconsistent data. After normalizing, each table describes one concept and the structure itself helps protect the data's correctness.
 
2. Explain the difference between an insertion anomaly and a deletion anomaly, using an example.
> [!NOTE]
> **_Your Answer_**
>
> An insertion anomaly means I can't store one fact without also storing an unrelated one. For example, in a flat order table I can't add a new product until somebody orders it. A deletion anomaly is the opposite: deleting a row accidentally removes other facts too. For example, if a product was ordered only once, deleting that order also deletes every record that the product exists.
 
3. What is the difference between a partial dependency and a transitive dependency?
> [!NOTE]
> **_Your Answer_**
>
> A partial dependency is when a non-key attribute depends on only part of a composite primary key, for example product_name depending only on product_id in order_items(order_id, product_id, ...). It violates 2NF. A transitive dependency is when a non-key attribute depends on another non-key attribute, which in turn depends on the key, for example category_name depending on category_id in a products table. It violates 3NF.
 
4. State the "informal rule" for 3NF. Explain what each part means.
> [!NOTE]
> **_Your Answer_**
>
> The rule is: "every non-key attribute must depend on the key, the whole key, and nothing but the key, so help me Codd." "The key" means the table must have a key that identifies each row (1NF). "The whole key" means every non-key column depends on the entire primary key and not just a part of it (2NF). "Nothing but the key" means non-key columns may not depend on other non-key columns, only directly on the key (3NF).
 
5. Why can partial dependencies only occur in tables with composite primary keys?
> [!NOTE]
> **_Your Answer_**
>
> A partial dependency means a column depends on part of the key, so the key has to have more than one column to have a "part" at all. With a single-column primary key, a column either depends on that whole key or on nothing, so there is no smaller piece it could depend on. That is why a table in 1NF with a single-column PK is automatically in 2NF.
 
6. What is BCNF, and how does it differ from 3NF? In what rare case can a table be in 3NF but not BCNF?
> [!NOTE]
> **_Your Answer_**
>
> BCNF (Boyce-Codd Normal Form) is a stricter version of 3NF: in BCNF, every determinant (a column or set of columns that determines another column) must be a candidate key. 3NF still allows a dependency where a non-key column determines a column that is part of a candidate key. This can happen when a table has overlapping composite candidate keys. For example, in enrollment(student, course, teacher), if each teacher teaches only one course, then teacher → course, but teacher is not a candidate key. The table can be in 3NF but not in BCNF. Every table in BCNF is also in 3NF.
 
7. Give two legitimate reasons to denormalize a database.
> [!NOTE]
> **_Your Answer_**
>
> First, performance in a read-heavy system: if I have measured that a frequent query spends too much time on many JOINs, I can store some data redundantly (for example the category name in the products table) to avoid the join. Second, reporting and analytics (data warehouses): data is loaded in batches, not updated row by row, so update anomalies are not a problem, and denormalized star schemas make large analytical queries simpler and faster. In both cases I would normalize first and denormalize only after measuring a real problem.
 
---
 
## 3. Normalization Exercise (Optional)
 
> [!TIP]
> **Recommended practice.** Do this section. It is not required to finish the TrailShop project. It prepares you for the exams.
 
Normalize each table to 3NF. Show your work for each step.
 
### Table 1: event_registrations
 
| event_id | event_name     | event_date | venue_id | venue_name      | venue_city | attendee_id | attendee_name | ticket_type | ticket_price |
| -------- | -------------- | ---------- | -------- | --------------- | ---------- | ----------- | ------------- | ----------- | ------------ |
| E1       | Trail Run 2025 | 2025-06-15 | V1       | City Park Arena | Helsinki   | A1          | Matti Aho     | VIP         | 75.00        |
| E1       | Trail Run 2025 | 2025-06-15 | V1       | City Park Arena | Helsinki   | A2          | Sara Lund     | Standard    | 35.00        |
| E2       | Mountain Fest  | 2025-07-20 | V2       | Summit Center   | Tampere    | A1          | Matti Aho     | Standard    | 40.00        |
 
**Business rules:**
 
- Each event has one name, date, and venue.
- Each venue has one name and city.
- Each attendee has one name.
- Ticket price depends on the event and ticket type combination.
**Steps:**
 
1. Identify the PK
   > [!NOTE]
   > **_Your Answer_**
   >
   > The PK is **{event_id, attendee_id}**. One attendee registers once for an event (Matti appears for E1 and E2, but only once per event), and that pair determines the ticket type.
2. Check 1NF, 2NF, 3NF
3. Decompose as needed
   > [!NOTE]
   > **_Your Answer_**
   >
   > **1NF:** All values are atomic, there are no repeating groups and there is a primary key, so it is in 1NF.
   >
   > **2NF:** Partial dependencies exist:
   >
   > - event_id → event_name, event_date, venue_id, venue_name, venue_city (depend only on event_id)
   > - attendee_id → attendee_name (depends only on attendee_id)
   > - ticket_type depends on the whole key {event_id, attendee_id}, so it stays.
   >
   > After removing them:
   >
   > ```text
   > events_v1(event_id PK, event_name, event_date, venue_id, venue_name, venue_city)
   > attendees(attendee_id PK, attendee_name)
   > registrations_v1(event_id, attendee_id, ticket_type, ticket_price)  PK: {event_id, attendee_id}
   > ```
   >
   > **3NF:** Transitive dependencies remain:
   >
   > - In events_v1: venue_name and venue_city depend on venue_id, which is not the key (event_id → venue_id → venue_name, venue_city).
   > - In registrations_v1: ticket_price depends on {event_id, ticket_type}, and ticket_type is a non-key attribute (key → ticket_type → ticket_price).
   >
   > Final tables:
   >
   > ```text
   > venues(venue_id PK, venue_name, venue_city)
   > events(event_id PK, event_name, event_date, venue_id FK -> venues)
   > attendees(attendee_id PK, attendee_name)
   > event_ticket_types(event_id FK, ticket_type, ticket_price)  PK: {event_id, ticket_type}
   > registrations(event_id FK, attendee_id FK, ticket_type)  PK: {event_id, attendee_id}
   >                FK: {event_id, ticket_type} -> event_ticket_types
   > ```
 
4. Write final CREATE TABLE statements
   > [!NOTE]
   > **_Your SQL_**
   >
   > ```sql
   > CREATE TABLE venues (
   >     venue_id   VARCHAR(10) PRIMARY KEY,
   >     venue_name VARCHAR(100) NOT NULL,
   >     venue_city VARCHAR(100) NOT NULL
   > );
   >
   > CREATE TABLE events (
   >     event_id   VARCHAR(10) PRIMARY KEY,
   >     event_name VARCHAR(100) NOT NULL,
   >     event_date DATE NOT NULL,
   >     venue_id   VARCHAR(10) NOT NULL REFERENCES venues(venue_id)
   > );
   >
   > CREATE TABLE attendees (
   >     attendee_id   VARCHAR(10) PRIMARY KEY,
   >     attendee_name VARCHAR(100) NOT NULL
   > );
   >
   > -- Price depends on the event + ticket type combination
   > CREATE TABLE event_ticket_types (
   >     event_id     VARCHAR(10) NOT NULL REFERENCES events(event_id),
   >     ticket_type  VARCHAR(20) NOT NULL,
   >     ticket_price NUMERIC(8,2) NOT NULL CHECK (ticket_price >= 0),
   >     PRIMARY KEY (event_id, ticket_type)
   > );
   >
   > CREATE TABLE registrations (
   >     event_id    VARCHAR(10) NOT NULL REFERENCES events(event_id),
   >     attendee_id VARCHAR(10) NOT NULL REFERENCES attendees(attendee_id),
   >     ticket_type VARCHAR(20) NOT NULL,
   >     PRIMARY KEY (event_id, attendee_id),
   >     FOREIGN KEY (event_id, ticket_type)
   >         REFERENCES event_ticket_types (event_id, ticket_type)
   > );
   > ```
 
### Table 2: store_inventory
 
| store_id | store_name         | store_city | product_id | product_name    | category | quantity | reorder_level | supplier_name |
| -------- | ------------------ | ---------- | ---------- | --------------- | -------- | -------- | ------------- | ------------- |
| S1       | TrailShop Helsinki | Helsinki   | 101        | Trail Runner X  | Footwear | 50       | 10            | NordGear Oy   |
| S1       | TrailShop Helsinki | Helsinki   | 201        | Rain Jacket Pro | Clothing | 20       | 5             | OutdoorPro AB |
| S2       | TrailShop Tampere  | Tampere    | 101        | Trail Runner X  | Footwear | 30       | 8             | NordGear Oy   |
 
**Business rules:**
 
- Each store has one name and city.
- Each product has one name, category, and supplier.
- Quantity and reorder_level depend on the specific store-product combination.
**Steps:** Same as above.
 
> [!NOTE]
> **_Your Answer_**
>
> **PK:** {store_id, product_id}, because each row is one product stocked in one store.
>
> **1NF:** All values are atomic and there is a primary key, so it is in 1NF.
>
> **2NF:** Partial dependencies exist:
>
> - store_id → store_name, store_city
> - product_id → product_name, category, supplier_name
> - quantity and reorder_level depend on the whole key {store_id, product_id}, so they stay.
>
> After removing them:
>
> ```text
> stores(store_id PK, store_name, store_city)
> products(product_id PK, product_name, category, supplier_name)
> store_inventory(store_id FK, product_id FK, quantity, reorder_level)  PK: {store_id, product_id}
> ```
>
> **3NF:** According to the business rules, category and supplier_name each depend directly on product_id, and neither determines the other or product_name. All three tables have single-column keys or fully dependent columns, so there are no transitive dependencies and the tables are in 3NF. (If categories and suppliers had their own attributes, such as a supplier email, I would move them into their own tables.)
 
> [!NOTE]
> **_Your SQL_**
>
> ```sql
> CREATE TABLE stores (
>     store_id   VARCHAR(10) PRIMARY KEY,
>     store_name VARCHAR(100) NOT NULL,
>     store_city VARCHAR(100) NOT NULL
> );
>
> CREATE TABLE products (
>     product_id    INTEGER PRIMARY KEY,
>     product_name  VARCHAR(200) NOT NULL,
>     category      VARCHAR(100) NOT NULL,
>     supplier_name VARCHAR(100) NOT NULL
> );
>
> CREATE TABLE store_inventory (
>     store_id      VARCHAR(10) NOT NULL REFERENCES stores(store_id),
>     product_id    INTEGER NOT NULL REFERENCES products(product_id),
>     quantity      INTEGER NOT NULL CHECK (quantity >= 0),
>     reorder_level INTEGER NOT NULL CHECK (reorder_level >= 0),
>     PRIMARY KEY (store_id, product_id)
> );
> ```
 
---
 
## 4. True/False
 
For each statement, write TRUE or FALSE and briefly explain why.
 
1. A table with a single-column primary key can violate 2NF.
> [!NOTE]
> **_Your Answer_**
>
> **FALSE.** 2NF violations are partial dependencies, which need a composite key. With a single-column key every non-key column depends on the whole key, so a table in 1NF is automatically in 2NF.
 
2. If a table is in 3NF, it is automatically in 2NF.
> [!NOTE]
> **_Your Answer_**
>
> **TRUE.** 3NF is defined as 2NF plus no transitive dependencies, so a table in 3NF has already met 2NF (and 1NF).
 
3. Normalization always improves query performance.
> [!NOTE]
> **_Your Answer_**
>
> **FALSE.** Normalization improves data integrity and makes writes and updates safer, but reads can need more JOINs. In read-heavy or reporting systems a normalized design can be slower, which is why denormalization is sometimes used.
 
4. Storing a customer's current address in the orders table is always a normalization violation.
> [!NOTE]
> **_Your Answer_**
>
> **FALSE.** If it is just a copy of the customer's current address, it is redundant and violates 3NF. But if it is the delivery address at the time of the order, it is a different fact (a historical snapshot) and the order must keep it even if the customer moves later, so it is not a violation.
 
5. BCNF is stricter than 3NF — every table in BCNF is also in 3NF.
> [!NOTE]
> **_Your Answer_**
>
> **TRUE.** BCNF requires every determinant to be a candidate key, which is a stronger condition than 3NF, so any table in BCNF also satisfies 3NF. The reverse is not always true.
 
6. Denormalization should be done before normalization to save time.
> [!NOTE]
> **_Your Answer_**
>
> **FALSE.** I should normalize first, and denormalize only afterwards if I have measured a real performance problem. Denormalizing first would bring back the redundancy and anomalies that normalization removes, and I would not know what I was giving up.
 
---
 
## Submission Checklist
 
**Required**
 
- [ ] Existing TrailShop schema reviewed and confirmed in 3NF (Task 1.2)
- [ ] Theory review questions answered
- [ ] True/False questions answered with a short explanation

**Recommended practice**
 
- [ ] Denormalized `supplier_products` table analyzed and normalized (Task 1.1)
- [ ] Normalization exercise completed for both tables

**Optional extension**
 
- [ ] Suppliers schema designed (Task 1.3) — you may skip this
