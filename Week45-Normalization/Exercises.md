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
   > **_Your SQL_**
   >
   > ```sql
   > -- Write your query here
   >
   >
   > ```
2. Identify any insertion, update, and deletion anomalies (give specific examples).
   > [!NOTE]
   > **_Your SQL_**
   >
   > ```sql
   > -- Write your query here
   >
   >
   > ```
3. Normalize this table to 3NF. Show each step (1NF, then 2NF, then 3NF) with the resulting tables.
   > [!NOTE]
   > **_Your SQL_**
   >
   > ```sql
   > -- Write your query here
   >
   >
   > ```

### Task 1.2: Review Your Existing TrailShop Schema

1. For each table, confirm it is in 3NF by verifying:
   - No partial dependencies (check tables with composite keys or surrogate keys)
   - No transitive dependencies
   > [!NOTE]
   > **_Your SQL_**
   >
   > ```sql
   > -- Write your query here
   >
   >
   > ```
2. Explain why `unit_price` in `order_items` is NOT a normalization violation.
   > [!NOTE]
   > **_Your SQL_**
   >
   > ```sql
   > -- Write your query here
   >
   >
   > ```

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
   > -- Write your query here
   >
   >
   > ```
3. Verify your design is in 3NF.

> [!NOTE]
> **_Your Answer_**
>
> _(Write your answer here.)_

---

## 2. Theory Review Questions

Answer in your own words (2–4 sentences each):

1. What is normalization, and what problem does it solve?

> [!NOTE]
> **_Your Answer_**
>
> _(Write your answer here.)_

2. Explain the difference between an insertion anomaly and a deletion anomaly, using an example.

> [!NOTE]
> **_Your Answer_**
>
> _(Write your answer here.)_

3. What is the difference between a partial dependency and a transitive dependency?

> [!NOTE]
> **_Your Answer_**
>
> _(Write your answer here.)_

4. State the "informal rule" for 3NF. Explain what each part means.

> [!NOTE]
> **_Your Answer_**
>
> _(Write your answer here.)_

5. Why can partial dependencies only occur in tables with composite primary keys?

> [!NOTE]
> **_Your Answer_**
>
> _(Write your answer here.)_

6. What is BCNF, and how does it differ from 3NF? In what rare case can a table be in 3NF but not BCNF?

> [!NOTE]
> **_Your Answer_**
>
> _(Write your answer here.)_

7. Give two legitimate reasons to denormalize a database.

> [!NOTE]
> **_Your Answer_**
>
> _(Write your answer here.)_

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
   > **_Your SQL_**
   >
   > ```sql
   > -- Write your query here
   >
   >
   > ```
2. Check 1NF, 2NF, 3NF
3. Decompose as needed
4. Write final CREATE TABLE statements
   > [!NOTE]
   > **_Your SQL_**
   >
   > ```sql
   > -- Write your query here
   >
   >
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

---

## 4. True/False

For each statement, write TRUE or FALSE and briefly explain why.

1. A table with a single-column primary key can violate 2NF.
2. If a table is in 3NF, it is automatically in 2NF.
3. Normalization always improves query performance.
4. Storing a customer's current address in the orders table is always a normalization violation.
5. BCNF is stricter than 3NF — every table in BCNF is also in 3NF.
6. Denormalization should be done before normalization to save time.

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
