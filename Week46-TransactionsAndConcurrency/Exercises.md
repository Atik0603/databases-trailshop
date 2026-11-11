# Week 46 — Transactions and Concurrency: Exercises
 
> [!IMPORTANT]
> **_How to Complete These Exercises_**
> Write your answers directly in the highlighted **Your Answer** / **Your SQL** fields below each task. Replace the placeholder text with your own work before submitting.
 
---
 
## 1. TrailShop Project Task
 
### Task 1.1: Write an Order Transaction
 
Write a complete transaction that processes a new order in TrailShop:
 
1. Insert a new order for an existing customer.
2. Insert 2–3 order items.
3. Decrease `stock_quantity` for each ordered product.
4. Include a check that stock doesn't go negative (if it would, ROLLBACK).
5. Use a SAVEPOINT before the stock update step.
   > [!NOTE]
   > **_Your SQL_**
   >
   > ```sql
   > -- My stock column is called "stock" (not stock_quantity), and products have IDs 1-10.
   > -- Successful order: customer 1 buys 2 x product 1, 1 x product 4, 3 x product 9.
   > BEGIN;
   >
   > -- 1. Create the order
   > INSERT INTO orders (customer_id, status)
   > VALUES (1, 'pending')
   > RETURNING order_id;
   >
   > -- 2. Insert 3 order items. The unit price is copied from the current product price.
   > -- currval() returns the order_id that was just generated in this session.
   > INSERT INTO order_items (order_id, product_id, quantity, unit_price)
   > SELECT currval('orders_order_id_seq'), p.product_id, v.qty, p.price
   > FROM (VALUES (1, 2), (4, 1), (9, 3)) AS v(product_id, qty)
   > JOIN products p ON p.product_id = v.product_id;
   >
   > -- 3. Savepoint before the stock update, so I can undo only the stock step
   > SAVEPOINT before_stock_update;
   >
   > -- 4. Decrease stock for every item of this order.
   > -- The CHECK (stock >= 0) constraint stops the statement with an error if any
   > -- product would go negative.
   > UPDATE products p
   > SET stock = p.stock - oi.quantity
   > FROM order_items oi
   > WHERE oi.order_id = currval('orders_order_id_seq')
   >   AND oi.product_id = p.product_id;
   >
   > -- 5. Explicit check: this must return 0 rows, otherwise the order is invalid
   > SELECT product_id, name, stock
   > FROM products
   > WHERE product_id IN (1, 4, 9) AND stock < 0;
   >
   > -- If the check returned rows (or an error appeared above), I run:
   > --     ROLLBACK TO SAVEPOINT before_stock_update;   -- undo only the stock step
   > --     ROLLBACK;                                    -- then cancel the whole order
   > -- Otherwise the order is valid:
   > COMMIT;
   > ```
   >
   > ```sql
   > -- Failing test: customer 1 tries to buy 500 x product 5, but there is not enough stock
   > BEGIN;
   >
   > INSERT INTO orders (customer_id, status) VALUES (1, 'pending');
   >
   > INSERT INTO order_items (order_id, product_id, quantity, unit_price)
   > SELECT currval('orders_order_id_seq'), p.product_id, 500, p.price
   > FROM products p
   > WHERE p.product_id = 5;
   >
   > SAVEPOINT before_stock_update;
   >
   > UPDATE products SET stock = stock - 500 WHERE product_id = 5;
   > -- ERROR: new row for relation "products" violates check constraint "products_stock_check"
   > -- The transaction is now in an aborted state, so I undo everything:
   >
   > ROLLBACK TO SAVEPOINT before_stock_update;  -- brings the transaction back to a usable state
   > ROLLBACK;                                   -- cancels the order and the order item too
   >
   > -- Verify: no new order exists and the stock of product 5 is unchanged
   > SELECT * FROM orders ORDER BY order_id DESC LIMIT 3;
   > SELECT product_id, name, stock FROM products WHERE product_id = 5;
   > ```
   >
   > ```sql
   > -- Alternative: the same stock check inside a DO block (a script that checks by itself).
   > -- A DO block is one transaction, so RAISE EXCEPTION undoes everything in it.
   > DO $$
   > DECLARE
   >     new_order_id INTEGER;
   > BEGIN
   >     INSERT INTO orders (customer_id, status) VALUES (1, 'pending')
   >     RETURNING order_id INTO new_order_id;
   >
   >     INSERT INTO order_items (order_id, product_id, quantity, unit_price)
   >     SELECT new_order_id, p.product_id, 500, p.price
   >     FROM products p WHERE p.product_id = 5;
   >
   >     IF (SELECT stock FROM products WHERE product_id = 5) < 500 THEN
   >         RAISE EXCEPTION 'Insufficient stock for product 5';
   >     END IF;
   >
   >     UPDATE products SET stock = stock - 500 WHERE product_id = 5;
   > END $$;
   > ```
 
Test the transaction by:
 
- Running it successfully with sufficient stock.
- Running it where stock is insufficient — verify the ROLLBACK works.
> [!NOTE]
> **_Your Answer_**
>
> **Successful run:** After the COMMIT, `SELECT * FROM orders ORDER BY order_id DESC LIMIT 1;` shows the new pending order, `order_items` has the 3 new lines, and the stock of products 1, 4 and 9 is lower by 2, 1 and 3.
>
> **Insufficient stock:** The UPDATE fails with `violates check constraint "products_stock_check"`. After `ROLLBACK TO SAVEPOINT` and `ROLLBACK`, there is no new order, no new order item, and the stock of product 5 is unchanged, so the transaction was atomic: all or nothing.


### Task 1.2: Observe READ COMMITTED Behavior (Optional)

> [!TIP]
> **Recommended practice.** Do Tasks 1.2–1.4. They are not required to finish the TrailShop project. They prepare you for the exams.

Open two psql sessions (or two query windows). Demonstrate a non-repeatable read:

1. Session A: `BEGIN;` then `SELECT stock_quantity FROM products WHERE product_id = 101;`
2. Session B: `BEGIN;` then `UPDATE products SET stock_quantity = stock_quantity - 5 WHERE product_id = 101;` then `COMMIT;`
3. Session A: `SELECT stock_quantity FROM products WHERE product_id = 101;` (observe different value)
4. Session A: `COMMIT;`

Document what you observe and explain why it happens at READ COMMITTED.

### Task 1.3: Observe Locking (Optional)

Open two sessions and demonstrate row-level locking:

1. Session A: `BEGIN;` then `SELECT * FROM products WHERE product_id = 101 FOR UPDATE;`
2. Session B: Try `UPDATE products SET price = 99.99 WHERE product_id = 101;` — observe it waits.
3. Session A: `COMMIT;` — observe Session B proceeds.

Document the behavior.

### Task 1.4: Experiment with Isolation Levels (Optional)

1. Repeat Task 1.2, but set Session A to `REPEATABLE READ`. Does the non-repeatable read still occur?

> [!NOTE]
> **_Your Answer_**
>
> _(Write your answer here.)_
>
> 2. In a REPEATABLE READ transaction, try to UPDATE a row that another transaction has already committed a change to. What error do you get?

> [!NOTE]
> **_Your Answer_**
>
> _(Write your answer here.)_
>
> 3. Document the differences between READ COMMITTED and REPEATABLE READ behavior.

---

## 2. Theory Review Questions

Answer in your own words (2–4 sentences each):

1. What is a transaction, and why is it important for data integrity?

> [!NOTE]
> **_Your Answer_**
>
> _(Write your answer here.)_

2. Explain the Atomicity property using a real-world example (not from the lecture notes).

> [!NOTE]
> **_Your Answer_**
>
> _(Write your answer here.)_
>
> 3. What does Isolation guarantee? Why is it needed in a multi-user system?

> [!NOTE]
> **_Your Answer_**
>
> _(Write your answer here.)_

4. What is the difference between COMMIT and ROLLBACK?

> [!NOTE]
> **_Your Answer_**
>
> _(Write your answer here.)_

5. Explain what a SAVEPOINT is and give a scenario where it's useful.

> [!NOTE]
> **_Your Answer_**
>
> _(Write your answer here.)_
>
> 6. What is a dirty read? Why does PostgreSQL never allow it?

> [!NOTE]
> **_Your Answer_**
>
> _(Write your answer here.)_

7. Describe the lost update problem. How can SELECT FOR UPDATE prevent it?

> [!NOTE]
> **_Your Answer_**
>
> _(Write your answer here.)_

8. What is the default isolation level in PostgreSQL? What concurrency problems does it still allow?

> [!NOTE]
> **_Your Answer_**
>
> _(Write your answer here.)_

9. Explain MVCC in one paragraph: what is it, and what advantage does it provide?

> [!NOTE]
> **_Your Answer_**
>
> _(Write your answer here.)_

10. What is a deadlock, and how does PostgreSQL handle it when one is detected?

> [!NOTE]
> **_Your Answer_**
>
> _(Write your answer here.)_

---

## 3. Scenario Analysis (Optional)

> [!TIP]
> **Recommended practice.** Do this section. It is not required to finish the TrailShop project. It prepares you for the exams.

For each scenario, identify: (a) which concurrency problem occurs, and (b) at which isolation level(s) it can happen.

### Scenario A

Transaction 1 reads customer 5's order count (3 orders). Transaction 2 inserts a new order for customer 5 and commits. Transaction 1 reads customer 5's order count again and gets 4.

### Scenario B

Transaction 1 reads product 101's price (€89.99). Transaction 2 updates product 101's price to €79.99 but then rolls back. If Transaction 1 had somehow seen €79.99, what problem would that be?

### Scenario C

Two warehouse workers simultaneously check stock for product 101 (both see 10). Worker A ships 3 units and sets stock to 7. Worker B ships 4 units and sets stock to 6. The correct stock should be 3.

---

## 4. Transaction Writing (Optional)

> [!TIP]
> **Recommended practice.** Do this section. It is not required to finish the TrailShop project. It prepares you for the exams.

Write complete SQL transactions for the following TrailShop scenarios. Include BEGIN, appropriate operations, error handling (SAVEPOINT where useful), and COMMIT.

### Transaction 1: Bulk Price Update

Update the price of all products in the "Footwear" category by +10%. If any product's new price would exceed €200, rollback the entire update.

### Transaction 2: Customer Account Deletion

Delete a customer and all their associated data:

1. Delete their order_items (for all their orders)

> [!NOTE]
> **_Your Answer_**
>
> _(Write your answer here.)_
>
> 2. Delete their orders

> [!NOTE]
> **_Your Answer_**
>
> _(Write your answer here.)_
>
> 3. Delete the customer record

> [!NOTE]
> **_Your Answer_**
>
> _(Write your answer here.)_

Use SAVEPOINTs between each step in case of errors.

### Transaction 3: Inventory Restock

Restock 3 products (add specific quantities to stock). Use SELECT FOR UPDATE to lock the rows first, preventing lost updates. Include a check that the new stock doesn't exceed a maximum (e.g., 200).

---

## 5. True/False

For each statement, write TRUE or FALSE and briefly explain why.

1. In PostgreSQL, a single SQL statement outside of an explicit BEGIN/COMMIT is not a transaction.
2. ROLLBACK undoes all changes made since the last SAVEPOINT.
3. At READ COMMITTED isolation level, a transaction can never see another transaction's uncommitted changes.
4. REPEATABLE READ in PostgreSQL prevents phantom reads.
5. SELECT FOR UPDATE blocks other SELECT statements on the same rows.
6. If a deadlock occurs, PostgreSQL will wait indefinitely for it to resolve.
7. MVCC means PostgreSQL keeps multiple versions of each row, allowing readers and writers to work concurrently without blocking.
8. Once a transaction is committed, its changes can be undone with ROLLBACK.

---

## Submission Checklist

**Required**

- [ ] Order transaction written and tested, including the insufficient-stock rollback (Task 1.1)
- [ ] Theory review questions answered
- [ ] True/False questions answered with a short explanation

**Recommended practice**

- [ ] READ COMMITTED, locking, and isolation-level experiments documented (Tasks 1.2–1.4)
- [ ] Scenario analysis completed
- [ ] Extra transactions written
