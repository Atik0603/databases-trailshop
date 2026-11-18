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
 
> [!NOTE]
> **_Your SQL_**
>
> ```sql
> -- I used product_id = 1 and my column name "stock".
>
> -- Session A:
> BEGIN;
> SELECT stock FROM products WHERE product_id = 1;   -- returns e.g. 25
>
> -- Session B:
> BEGIN;
> UPDATE products SET stock = stock - 5 WHERE product_id = 1;
> COMMIT;
>
> -- Session A (same transaction, still open):
> SELECT stock FROM products WHERE product_id = 1;   -- returns e.g. 20 (different!)
> COMMIT;
> ```
 
> [!NOTE]
> **_Your Answer_**
>
> In Session A the first SELECT returned the original stock (for example 25). After Session B committed its UPDATE, the second SELECT in the same still-open transaction returned 5 less (for example 20). This is a non-repeatable read. It happens because at READ COMMITTED each statement gets a new snapshot of the data committed *before that statement started*, not before the transaction started. Session B's change was committed before Session A's second SELECT began, so Session A can see it. PostgreSQL never lets A see B's change *before* B commits, so no dirty read happened.
 
### Task 1.3: Observe Locking (Optional)
 
Open two sessions and demonstrate row-level locking:
 
1. Session A: `BEGIN;` then `SELECT * FROM products WHERE product_id = 101 FOR UPDATE;`
2. Session B: Try `UPDATE products SET price = 99.99 WHERE product_id = 101;` — observe it waits.
3. Session A: `COMMIT;` — observe Session B proceeds.
Document the behavior.
 
> [!NOTE]
> **_Your SQL_**
>
> ```sql
> -- Session A:
> BEGIN;
> SELECT * FROM products WHERE product_id = 1 FOR UPDATE;   -- locks the row
>
> -- Session B (while A is still open):
> UPDATE products SET price = 99.99 WHERE product_id = 1;   -- hangs, waiting for the lock
>
> -- Session A:
> COMMIT;                                                   -- releases the lock
> -- Session B: the UPDATE now finishes immediately ("UPDATE 1")
> ```
 
> [!NOTE]
> **_Your Answer_**
>
> When Session A ran `SELECT ... FOR UPDATE`, it took an exclusive row lock on product 1. Session B's UPDATE did not return and just waited (the cursor hangs). As soon as Session A ran COMMIT, the lock was released and Session B's UPDATE completed immediately. Row locks are held until the end of the transaction, and they only block other writers or `FOR UPDATE` on the same row: a plain `SELECT` from a third session would still have worked, because of MVCC. Updating a different row would also not have waited.
 
### Task 1.4: Experiment with Isolation Levels (Optional)
 
1. Repeat Task 1.2, but set Session A to `REPEATABLE READ`. Does the non-repeatable read still occur?
> [!NOTE]
> **_Your Answer_**
>
> ```sql
> -- Session A:
> BEGIN ISOLATION LEVEL REPEATABLE READ;
> SELECT stock FROM products WHERE product_id = 1;   -- e.g. 25
> -- Session B: UPDATE products SET stock = stock - 5 WHERE product_id = 1; COMMIT;
> SELECT stock FROM products WHERE product_id = 1;   -- still 25
> COMMIT;
> ```
>
> No, the non-repeatable read does not occur. Session A keeps seeing the original value (25) in both SELECTs, even though Session B committed a change in between, because at REPEATABLE READ the transaction works on a snapshot taken at its first query. After Session A commits, a new SELECT shows the updated value.
 
2. In a REPEATABLE READ transaction, try to UPDATE a row that another transaction has already committed a change to. What error do you get?
> [!NOTE]
> **_Your Answer_**
>
> ```sql
> -- Session A:
> BEGIN ISOLATION LEVEL REPEATABLE READ;
> SELECT stock FROM products WHERE product_id = 1;        -- snapshot is taken
> -- Session B: UPDATE products SET stock = stock - 5 WHERE product_id = 1; COMMIT;
> UPDATE products SET stock = stock - 1 WHERE product_id = 1;
> ```
>
> The error is: `ERROR: could not serialize access due to concurrent update`. PostgreSQL refuses because Session A's snapshot is out of date for that row. Session A must ROLLBACK and retry the whole transaction.
 
3. Document the differences between READ COMMITTED and REPEATABLE READ behavior.
> [!NOTE]
> **_Your Answer_**
>
> | | READ COMMITTED | REPEATABLE READ |
> |---|---|---|
> | Snapshot taken | At the start of each statement | At the start of the transaction (first query) |
> | Non-repeatable read | Possible | Prevented |
> | Phantom read | Possible | Prevented in PostgreSQL |
> | Updating a row changed by another committed transaction | Waits, then works on the new value | Fails with "could not serialize access due to concurrent update" |
> | Application must retry? | Rarely | Yes, when a serialization error occurs |
 
---
 
## 2. Theory Review Questions
 
Answer in your own words (2–4 sentences each):
 
1. What is a transaction, and why is it important for data integrity?
> [!NOTE]
> **_Your Answer_**
>
> A transaction is a group of SQL operations that the database treats as one logical unit of work: either all of the operations succeed (COMMIT) or none of them take effect (ROLLBACK). It is important for data integrity because many real tasks, like processing an order, need several changes that only make sense together. Without a transaction, a crash halfway through would leave the data half-updated, for example an order without reduced stock.
 
2. Explain the Atomicity property using a real-world example (not from the lecture notes).
> [!NOTE]
> **_Your Answer_**
>
> Atomicity means a transaction is all or nothing. Example: booking a concert ticket online consists of two steps: marking seat 14B as reserved for me and charging my card. If the card payment fails, the seat reservation must be undone too, otherwise the seat would be blocked for nobody. With atomicity, either both steps happen or neither does.
 
3. What does Isolation guarantee? Why is it needed in a multi-user system?
> [!NOTE]
> **_Your Answer_**
>
> Isolation guarantees that concurrent transactions behave as if they ran one after another, and that one transaction's unfinished changes are not visible to the others. It is needed in a multi-user system because many people read and write the same rows at the same time, and without isolation they would see half-finished data or overwrite each other's changes, such as two customers both buying the last item.
 
4. What is the difference between COMMIT and ROLLBACK?
> [!NOTE]
> **_Your Answer_**
>
> COMMIT ends the transaction and makes all its changes permanent and visible to other transactions. ROLLBACK ends the transaction and undoes all its changes, as if it had never happened. After COMMIT I can't undo the changes with ROLLBACK.
 
5. Explain what a SAVEPOINT is and give a scenario where it's useful.
> [!NOTE]
> **_Your Answer_**
>
> A SAVEPOINT is a named checkpoint inside a transaction that I can roll back to with `ROLLBACK TO SAVEPOINT name` without cancelling the whole transaction. It is useful, for example, when processing an order: after inserting the order I set a savepoint, then one order item fails because the product doesn't exist. I roll back to the savepoint, keep the order, and insert the correct item instead of starting over.
 
6. What is a dirty read? Why does PostgreSQL never allow it?
> [!NOTE]
> **_Your Answer_**
>
> A dirty read is when a transaction reads data that another transaction has changed but not yet committed. If the other transaction rolls back, the first one has used data that never really existed. PostgreSQL never allows it because of MVCC: each statement only sees row versions that were already committed, and even if I ask for READ UNCOMMITTED, PostgreSQL treats it as READ COMMITTED.
 
7. Describe the lost update problem. How can SELECT FOR UPDATE prevent it?
> [!NOTE]
> **_Your Answer_**
>
> A lost update happens when two transactions read the same value, each calculates a new value from it, and both write it back, so one overwrites the other's change. For example, two workers both read stock 10, one writes 7 and the other writes 8, and the final stock is wrong. With `SELECT ... FOR UPDATE` the first transaction locks the row when it reads it, so the second transaction has to wait until the first commits and then reads the up-to-date value, so no update is lost.
 
8. What is the default isolation level in PostgreSQL? What concurrency problems does it still allow?
> [!NOTE]
> **_Your Answer_**
>
> The default is READ COMMITTED. It prevents dirty reads but still allows non-repeatable reads and phantom reads, because every statement sees the latest committed data. Lost updates are also possible when I read a value first and then write a calculated value back, unless I lock the row or use `stock = stock - n`.
 
9. Explain MVCC in one paragraph: what is it, and what advantage does it provide?
> [!NOTE]
> **_Your Answer_**
>
> MVCC (Multi-Version Concurrency Control) means PostgreSQL does not overwrite a row when it is updated. It creates a new version of the row and keeps the old one for a while, and each row version records which transaction created it (xmin) and which one removed it (xmax). Every transaction works on a snapshot and sees only the versions that are visible to it. The big advantage is that readers never block writers and writers never block readers, so many users can work at the same time with good performance. Old versions that nobody needs anymore are cleaned up by VACUUM.
 
10. What is a deadlock, and how does PostgreSQL handle it when one is detected?
> [!NOTE]
> **_Your Answer_**
>
> A deadlock is a circular wait: transaction A holds a lock that B needs, and B holds a lock that A needs, so neither can continue. PostgreSQL's deadlock detector checks after `deadlock_timeout` (1 second by default), and when it finds a cycle it aborts one of the transactions with `ERROR: deadlock detected`, which lets the other one continue. The aborted transaction has to be retried by the application. I can prevent deadlocks by always locking rows in the same order and keeping transactions short.
 
---
 
## 3. Scenario Analysis (Optional)
 
> [!TIP]
> **Recommended practice.** Do this section. It is not required to finish the TrailShop project. It prepares you for the exams.
 
For each scenario, identify: (a) which concurrency problem occurs, and (b) at which isolation level(s) it can happen.
 
### Scenario A
 
Transaction 1 reads customer 5's order count (3 orders). Transaction 2 inserts a new order for customer 5 and commits. Transaction 1 reads customer 5's order count again and gets 4.
 
> [!NOTE]
> **_Your Answer_**
>
> (a) A **phantom read**: the same query returns a different set of rows because another transaction inserted a new matching row (a new row "appeared"). (b) By the SQL standard it can happen at READ UNCOMMITTED, READ COMMITTED and REPEATABLE READ, and it is prevented at SERIALIZABLE. In PostgreSQL it can happen at READ COMMITTED (the default) only, because PostgreSQL's REPEATABLE READ uses a snapshot and also prevents phantoms.
 
### Scenario B
 
Transaction 1 reads product 101's price (€89.99). Transaction 2 updates product 101's price to €79.99 but then rolls back. If Transaction 1 had somehow seen €79.99, what problem would that be?
 
> [!NOTE]
> **_Your Answer_**
>
> (a) A **dirty read**: Transaction 1 would have read an uncommitted value that never became real. (b) By the standard it is possible only at READ UNCOMMITTED, and prevented at READ COMMITTED and above. In PostgreSQL it can never happen at any level, because READ UNCOMMITTED is treated as READ COMMITTED.
 
### Scenario C
 
Two warehouse workers simultaneously check stock for product 101 (both see 10). Worker A ships 3 units and sets stock to 7. Worker B ships 4 units and sets stock to 6. The correct stock should be 3.
 
> [!NOTE]
> **_Your Answer_**
>
> (a) A **lost update**: both workers read 10 and wrote an absolute value, so B's write overwrote A's, and A's 3 shipped units disappeared. (b) It can happen at READ COMMITTED (the PostgreSQL default) with this read-then-write pattern. At REPEATABLE READ and SERIALIZABLE PostgreSQL does not silently lose the update: the second transaction fails with a serialization error and has to retry. It can be avoided at any level with `SELECT ... FOR UPDATE` or by writing `SET stock = stock - 3`.
 
---
 
## 4. Transaction Writing (Optional)
 
> [!TIP]
> **Recommended practice.** Do this section. It is not required to finish the TrailShop project. It prepares you for the exams.
 
Write complete SQL transactions for the following TrailShop scenarios. Include BEGIN, appropriate operations, error handling (SAVEPOINT where useful), and COMMIT.
 
### Transaction 1: Bulk Price Update
 
Update the price of all products in the "Footwear" category by +10%. If any product's new price would exceed €200, rollback the entire update.
 
> [!NOTE]
> **_Your SQL_**
>
> ```sql
> BEGIN;
>
> UPDATE products
> SET price = ROUND(price * 1.10, 2)
> WHERE category_id = (SELECT category_id FROM categories WHERE name = 'Footwear');
>
> -- Check: any Footwear product above 200 after the update?
> SELECT name, price
> FROM products
> WHERE category_id = (SELECT category_id FROM categories WHERE name = 'Footwear')
>   AND price > 200;
>
> -- If this returned any rows:  ROLLBACK;   (the whole update is undone)
> -- If it returned no rows:     COMMIT;
> ```
>
> ```sql
> -- Alternative: one DO block checks automatically. If the exception is raised,
> -- the whole block (including the UPDATE) is rolled back.
> DO $$
> BEGIN
>     UPDATE products
>     SET price = ROUND(price * 1.10, 2)
>     WHERE category_id = (SELECT category_id FROM categories WHERE name = 'Footwear');
>
>     IF EXISTS (
>         SELECT 1 FROM products
>         WHERE category_id = (SELECT category_id FROM categories WHERE name = 'Footwear')
>           AND price > 200
>     ) THEN
>         RAISE EXCEPTION 'A Footwear price would exceed 200 - update cancelled';
>     END IF;
> END $$;
> ```
 
### Transaction 2: Customer Account Deletion
 
Delete a customer and all their associated data:
 
1. Delete their order_items (for all their orders)
> [!NOTE]
> **_Your SQL_**
>
> ```sql
> -- Customer 1 is used as the example. To test safely, replace COMMIT at the end
> -- of step 3 with ROLLBACK.
> BEGIN;
>
> DELETE FROM order_items
> WHERE order_id IN (SELECT order_id FROM orders WHERE customer_id = 1);
>
> SAVEPOINT after_items;
> ```
 
2. Delete their orders
> [!NOTE]
> **_Your SQL_**
>
> ```sql
> DELETE FROM orders WHERE customer_id = 1;
>
> SAVEPOINT after_orders;
> -- If this step fails, I run: ROLLBACK TO SAVEPOINT after_items;
> ```
 
3. Delete the customer record
> [!NOTE]
> **_Your SQL_**
>
> ```sql
> DELETE FROM customers WHERE customer_id = 1;
> -- If this step fails (for example another table still references the customer), I run:
> --     ROLLBACK TO SAVEPOINT after_orders;   (and fix the problem, or ROLLBACK everything)
>
> COMMIT;
> ```
 
Use SAVEPOINTs between each step in case of errors.
 
> [!NOTE]
> **_Your Answer_**
>
> The three boxes above are one single transaction that I run in order: `BEGIN`, step 1 and its savepoint, step 2 and its savepoint, step 3, `COMMIT`. The order matters: order_items go first, then orders, then the customer, because each table references the next one through a foreign key. If a step fails, I roll back to the savepoint before it, so the earlier steps are not repeated, or I use a plain `ROLLBACK` to cancel everything and keep the customer's data intact.
 
### Transaction 3: Inventory Restock
 
Restock 3 products (add specific quantities to stock). Use SELECT FOR UPDATE to lock the rows first, preventing lost updates. Include a check that the new stock doesn't exceed a maximum (e.g., 200).
 
> [!NOTE]
> **_Your SQL_**
>
> ```sql
> BEGIN;
>
> -- same order, which avoids deadlocks.
> SELECT product_id, name, stock
> FROM products
> WHERE product_id IN (1, 2, 3)
> ORDER BY product_id
> FOR UPDATE;
>
> SAVEPOINT before_restock;
>
> -- Add the restock quantities: +50 to product 1, +40 to product 2, +30 to product 3
> UPDATE products p
> SET stock = p.stock + v.qty
> FROM (VALUES (1, 50), (2, 40), (3, 30)) AS v(product_id, qty)
> WHERE p.product_id = v.product_id;
>
> -- Check: no product may exceed the maximum of 200
> SELECT product_id, name, stock
> FROM products
> WHERE product_id IN (1, 2, 3) AND stock > 200;
>
> ```
 
---
 
## 5. True/False
 
For each statement, write TRUE or FALSE and briefly explain why.
 
1. In PostgreSQL, a single SQL statement outside of an explicit BEGIN/COMMIT is not a transaction.
> [!NOTE]
> **_Your Answer_**
>
> **FALSE.** PostgreSQL runs in autocommit mode: a single statement outside BEGIN/COMMIT is automatically wrapped in its own transaction and committed immediately.
 
2. ROLLBACK undoes all changes made since the last SAVEPOINT.
> [!NOTE]
> **_Your Answer_**
>
> **FALSE.** A plain `ROLLBACK` undoes the whole transaction, everything since `BEGIN`. Only `ROLLBACK TO SAVEPOINT name` undoes the changes made since that savepoint and keeps the transaction open.
 
3. At READ COMMITTED isolation level, a transaction can never see another transaction's uncommitted changes.
> [!NOTE]
> **_Your Answer_**
>
> **TRUE.** READ COMMITTED prevents dirty reads: each statement sees only data that was committed before the statement started.
 
4. REPEATABLE READ in PostgreSQL prevents phantom reads.
> [!NOTE]
> **_Your Answer_**
>
> **TRUE.** The SQL standard allows phantom reads at REPEATABLE READ, but PostgreSQL implements it with a snapshot taken at the start of the transaction, so new rows from other transactions are not visible either.
 
5. SELECT FOR UPDATE blocks other SELECT statements on the same rows.
> [!NOTE]
> **_Your Answer_**
>
> **FALSE.** Plain SELECTs are not blocked, because of MVCC (readers don't block writers). `FOR UPDATE` blocks other transactions that try to UPDATE, DELETE or `SELECT ... FOR UPDATE` the same rows.
 
6. If a deadlock occurs, PostgreSQL will wait indefinitely for it to resolve.
> [!NOTE]
> **_Your Answer_**
>
> **FALSE.** PostgreSQL's deadlock detector runs after `deadlock_timeout` (1 second by default) and aborts one of the transactions with `ERROR: deadlock detected`, so the other can continue.
 
7. MVCC means PostgreSQL keeps multiple versions of each row, allowing readers and writers to work concurrently without blocking.
> [!NOTE]
> **_Your Answer_**
>
> **TRUE.** Updates create new row versions and each transaction sees the version that fits its snapshot, so readers don't wait for writers and writers don't wait for readers.
 
8. Once a transaction is committed, its changes can be undone with ROLLBACK.
> [!NOTE]
> **_Your Answer_**
>
> **FALSE.** After COMMIT the changes are permanent (durability). ROLLBACK only works on a transaction that is still open; I would have to write new statements to reverse the changes.
 
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
 
