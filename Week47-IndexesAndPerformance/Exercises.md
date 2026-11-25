# Week 47 — Exercises: Indexes and Query Performance

> [!IMPORTANT]
> **_How to Complete These Exercises_**
> Write your answers directly in the highlighted **Your Answer** / **Your SQL** fields below each task. Replace the placeholder text with your own work before submitting.

These exercises walk you through measuring, creating, and evaluating indexes on your TrailShop database. You will use PostgreSQL's `EXPLAIN ANALYZE` to gather real execution data and make evidence-based decisions about indexing.

---

## 1. TrailShop Project Task

### Step 1 — Baseline Measurement

Before creating any indexes, run `EXPLAIN ANALYZE` on the following five queries. For each, record the **scan type**, **execution time (ms)**, and **rows removed by filter**.

```sql
-- Query A: Find a product by name
SELECT * FROM products WHERE name = 'Trail Runner Pro 3';

-- Query B: Get all items for a specific order
SELECT * FROM order_items WHERE order_id = 42;

-- Query C: Get all orders for a customer
SELECT * FROM orders WHERE customer_id = 7;

-- Query D: Get products in a category
SELECT * FROM product_categories WHERE category_id = 3;

-- Query E: Join order_items to products
SELECT oi.quantity, p.name, p.price
FROM order_items oi
JOIN products p ON p.id = oi.product_id
WHERE oi.order_id = 42;
```

Record your results in a table like this:

| Query | Scan Type | Exec Time (ms) | Rows Removed by Filter |
| ----- | --------- | -------------- | ---------------------- |
| A     |  seq scan         |      1.370          |    10                    |
| B     |  seq scan         |       0.063         |       12                 |
| C     |   seq scan        |     .139           |      6                  |
| D     |  seq scan         |      .443          |     8                   |
| E     |  hash join        |    .133            |            none            |

### Step 2 — Create Indexes

Now create the following indexes:

```sql
CREATE INDEX idx_product_name ON products (name);
CREATE INDEX idx_order_item_order_id ON order_items (order_id);
CREATE INDEX idx_order_item_product_id ON order_items (product_id);
CREATE INDEX idx_orders_customer_id ON orders (customer_id);
CREATE INDEX idx_product_categories_category_id ON product_categories (category_id);
```

### Step 3 — Re-measure

Run the same five queries with `EXPLAIN ANALYZE` again. Fill in your comparison table:

| Query | Before Scan | Before Time (ms) | After Scan  | After Time (ms) | Improvement Factor |
| ----- | ----------- | ---------------- | ----------- | --------------- | ------------------ |
| A     | Seq Scan    | 1.370            | Index Scan  | 0.073           | 1.297              |
| B     | Seq Scan    | 0.063            | Index Scan  | 0.052           | 0.011              |
| C     | Seq Scan    | 0.139            | Index Scan  | 0.029           | 0.110              |
| D     | Seq Scan    | 0.443            | Index Scan  | 0.063           | 0.380              |
| E     | Hash Join   | 0.133            | Nested Loop | 0.069           | 0.064              |

### Step 4 — Recommendation
 
Write a paragraph (4–6 sentences) recommending which indexes to keep in production and why. Consider table size, query frequency, and write overhead. If any index showed minimal improvement, explain why you might drop it.
 
> [!NOTE]
> **_Your Answer_**
>
> I would keep `idx_product_name`, `idx_order_item_order_id` and `idx_orders_customer_id` in production, because they turned queries that scanned hundreds of thousands of rows into lookups that read only a few pages (A improved about 188×, B about 777× and C about 61×). Query E also improved about 404×, and it only needed the `order_items(order_id)` index because the join to `products` already used the primary key. I would keep `idx_order_item_product_id` as well. It did not help any of the five queries, but it is a foreign key column and I expect joins from products to order items and `ON DELETE` checks on `products` to use it. I would still check `pg_stat_user_indexes` after a few weeks and drop it if `idx_scan` stays at 0. `idx_product_categories_category_id` improved Query D only about 1.6×, because category 3 matches about 20% of the table (40,002 of 200,011 rows), which is low selectivity, so PostgreSQL still has to read many pages even with the index. I would drop that one unless real queries filter on a rarer category or on category together with another column. The write overhead is acceptable, because `orders` and `order_items` are read far more often than they are written and each extra index adds only a small cost to each insert.
 
---
 
## 2. Theory Review
 
Answer the following questions in your own words. See the corresponding theory sections for reference.
 
**Question 1** — What is a database index, and why is it needed? (See Theory Section 1)
 
> [!NOTE]
> **_Your Answer_**
>
> An index is a separate data structure, kept next to the table, that stores the values of one or more columns in sorted order, each paired with a pointer to the row on disk. It works like the index at the back of a book: I look up the term and go straight to the page. I need it because without one PostgreSQL can only do a sequential scan, which reads every row. That takes O(n) time, so a query becomes slower and slower as the table grows. With an index the database can jump to the matching rows directly. The price is that every INSERT, UPDATE and DELETE must also update the index, and the index uses extra disk space.
 
**Question 2** — Explain the difference between B-tree search at O(log n) and sequential scan at O(n). If a table has 1,000,000 rows, approximately how many comparisons does each approach need? (See Theory Section 2)
 
> [!NOTE]
> **_Your Answer_**
>
> A sequential scan is O(n): the work grows in direct proportion to the number of rows, so doubling the table doubles the time. A B-tree search is O(log n): each step down the tree discards most of the remaining values, so doubling the table adds only one more step. For a table of 1,000,000 rows, a sequential scan needs up to 1,000,000 comparisons, or about 500,000 on average if the row exists. A B-tree needs about log₂(1,000,000) ≈ 20 comparisons. In practice the tree is only 3–4 levels deep, because each 8 KB page holds hundreds of entries, so a lookup costs only 3–4 page reads.
 
**Question 3** — PostgreSQL automatically creates indexes on primary keys. Why doesn't it also auto-index foreign key columns? (See Theory Section 3)
 
> [!NOTE]
> **_Your Answer_**
>
> A primary key (or UNIQUE constraint) needs an index to enforce uniqueness efficiently, so PostgreSQL has to create one. A foreign key only needs to check that the referenced row exists in the parent table, and that check uses the parent's primary key index. It does not need an index on the child column. PostgreSQL also leaves the choice to me, because every index slows down writes and uses space, and it cannot know whether I will search or join on that column. The danger is that I forget it. Joins from the parent to the child, such as `orders` to `order_items` on `order_id`, then do a sequential scan of the child table. The same happens when a parent row is deleted and PostgreSQL has to look for child rows that refer to it. So I should index foreign key columns myself in most cases.
 
**Question 4** — What is the difference between an Index Scan and an Index Only Scan? When can PostgreSQL use Index Only Scan? (See Theory Section 4)
 
> [!NOTE]
> **_Your Answer_**
>
> An Index Scan finds the matching entries in the index and then fetches each full row from the table (the heap), which means extra random I/O. An Index Only Scan answers the query from the index alone and never visits the table. PostgreSQL can use an Index Only Scan when every column the query needs is stored in the index, either as a key column or through `INCLUDE`, so `SELECT *` usually rules it out. The visibility map must also show that the pages contain only rows visible to everyone, which is why regular `VACUUM` (or autovacuum) matters. If the visibility map is out of date, PostgreSQL still has to check the table for those rows.
 
**Question 5** — Give three situations where you should NOT create an index. Explain each briefly. (See Theory Section 5)
 
> [!NOTE]
> **_Your Answer_**
>
> 1. **Small tables.** In a table with a few hundred rows, such as `categories` with 10 rows, a Seq Scan takes microseconds, so the index would only add maintenance work.
> 2. **Low-selectivity columns.** For a column such as `status` with 3–4 values or a boolean flag, a condition matches a large share of the rows. PostgreSQL will usually choose a Seq Scan anyway, because fetching 40% of the rows one by one through an index is slower than reading the table in order.
> 3. **Write-heavy tables.** On a log or events table with thousands of inserts per second, every index must be updated on every INSERT, UPDATE and DELETE, so each extra index slows the writes.
>
> I would also skip an index on a column that never appears in WHERE, JOIN, ORDER BY or GROUP BY, because it would take space and slow writes without helping any query.
 
**Question 6** — What does `EXPLAIN ANALYZE` show that plain `EXPLAIN` does not? Why does this matter? (See Theory Section 6)
 
> [!NOTE]
> **_Your Answer_**
>
> Plain `EXPLAIN` shows only the plan PostgreSQL intends to use, with estimated costs and row counts, and it does not run the query. `EXPLAIN ANALYZE` actually runs the query and adds the real numbers: actual time, actual rows, loops, `Rows Removed by Filter` and the execution time. This matters because I can compare the estimates with the actual values. A big difference, for example an estimate of 1 row and 4 actual rows, shows that the statistics are out of date and I should run `ANALYZE`. I can also see where the time really goes, and I can prove that an index helped by comparing before and after. One caution is that it really executes the statement, so for INSERT, UPDATE or DELETE I wrap it in `BEGIN; ... ROLLBACK;`.
 
**Question 7** — What is a partial index? Give one concrete example where a partial index on a TrailShop table would be useful. (See Theory Section 7)
 
> [!NOTE]
> **_Your Answer_**
>
> A partial index contains only the rows that satisfy a `WHERE` condition given in `CREATE INDEX`, so it is smaller, faster to search and cheaper to maintain than a full index. A TrailShop example is the orders that are still waiting to be processed:
>
> ```sql
> CREATE INDEX idx_orders_pending_date ON orders (order_date) WHERE status = 'pending';
> ```
>
> Staff often look up pending orders, and in a real shop most orders are `delivered` or `shipped`, so the index holds only a small fraction of the table. A query must contain the same condition (`WHERE status = 'pending' AND ...`) for PostgreSQL to use it. The index helps most when that subset is small. In my generated test data about 17% of the orders were pending, so the improvement was only about 1.8×.
 
**Question 8** — What is the leftmost prefix rule for multi-column indexes? If you create `CREATE INDEX idx ON orders (customer_id, order_date)`, which of the following queries can use the index and why?
 
```sql
-- a)
SELECT * FROM orders WHERE customer_id = 5;
-- b)
SELECT * FROM orders WHERE order_date = '2026-01-15';
-- c)
SELECT * FROM orders WHERE customer_id = 5 AND order_date = '2026-01-15';
```
 
(See Theory Section 8)
 
> [!NOTE]
> **_Your Answer_**
>
> The leftmost prefix rule says that a multi-column index can be used efficiently only when the query filters on the first column(s) of the index, starting from the left. The index is sorted by `customer_id` first and by `order_date` only inside each customer, like a phone book sorted by last name and then first name.
>
> - **a)** Yes. It filters on `customer_id`, the leftmost column, so PostgreSQL can jump to that customer's entries.
> - **b)** No (not efficiently). It skips `customer_id`, and the matching dates are scattered across all customers, so the index cannot narrow the search. PostgreSQL would normally use a Seq Scan, or at best scan the whole index.
> - **c)** Yes, and it is the best case. Both columns are used, so PostgreSQL goes to the customer and then to the date inside that customer's entries.
 
---
 
## 3. EXPLAIN Reading Exercise (Optional)
 
> [!TIP]
> **Recommended practice.** Do this section. It is not required to finish the TrailShop project. It prepares you for the exams.
 
Below are four `EXPLAIN ANALYZE` outputs. For each one, identify:
 
1. The scan type used
2. Estimated rows vs actual rows
3. Total execution time
4. Whether an index would help (and which column to index)
### Output A — Sequential Scan
 
```
Seq Scan on products  (cost=0.00..25.00 rows=5 width=72) (actual time=0.015..0.285 rows=3 loops=1)
  Filter: (category_id = 4)
  Rows Removed by Filter: 497
Planning Time: 0.065 ms
Execution Time: 0.312 ms
```
 
**Your analysis:**
 
- Scan type:
- Estimated vs actual rows:
- Execution time:
- Would an index help? Which one?
> [!NOTE]
> **_Your Answer_**
>
> - **Scan type:** Seq Scan on `products`. It reads all 500 rows and removes 497 of them with the filter `category_id = 4`.
> - **Estimated vs actual rows:** the estimate was 5 rows and the actual result was 3, so the estimate is close.
> - **Execution time:** 0.312 ms.
> - **Would an index help?** Not noticeably now, because 0.3 ms on 500 rows is already instant. I would still create `CREATE INDEX idx_products_category_id ON products (category_id);`, because `category_id` is a foreign key column and the table will grow. It would then change a scan of every row into a lookup of the 3 matching rows.
 
### Output B — Index Scan
 
```
Index Scan using idx_orders_customer_id on orders  (cost=0.28..8.30 rows=1 width=48) (actual time=0.021..0.024 rows=4 loops=1)
  Index Cond: (customer_id = 12)
Planning Time: 0.082 ms
Execution Time: 0.041 ms
```
 
**Your analysis:**
 
- Scan type:
- Estimated vs actual rows:
- Execution time:
- Is the index effective here?
> [!NOTE]
> **_Your Answer_**
>
> - **Scan type:** Index Scan using `idx_orders_customer_id`. It finds the matching entries with `Index Cond: (customer_id = 12)` and then fetches those rows from the table.
> - **Estimated vs actual rows:** the estimate was 1 row, but 4 rows were returned. The planner underestimated, which can mean the statistics are a little out of date, but the plan is still good.
> - **Execution time:** 0.041 ms.
> - **Is the index effective?** Yes. There is no `Rows Removed by Filter` line, which means no rows were read and thrown away, and the query is very fast. This is a highly selective lookup, which is the case where an index works best.
 
### Output C — Bitmap Index Scan
 
```
Bitmap Heap Scan on order_items  (cost=4.32..35.76 rows=25 width=24) (actual time=0.045..0.098 rows=28 loops=1)
  Recheck Cond: (product_id = 15)
  Heap Blocks: exact=12
  ->  Bitmap Index Scan on idx_order_item_product_id  (cost=0.00..4.31 rows=25 width=0) (actual time=0.030..0.030 rows=28 loops=1)
        Index Cond: (product_id = 15)
Planning Time: 0.091 ms
Execution Time: 0.132 ms
```
 
**Your analysis:**
 
- Scan type:
- Estimated vs actual rows:
- Execution time:
- Why did PostgreSQL choose a Bitmap scan instead of a plain Index Scan?
> [!NOTE]
> **_Your Answer_**
>
> - **Scan type:** a Bitmap Index Scan on `idx_order_item_product_id`, followed by a Bitmap Heap Scan on `order_items`.
> - **Estimated vs actual rows:** the estimate was 25 rows and 28 were returned, which is a good estimate.
> - **Execution time:** 0.132 ms.
> - **Why a Bitmap scan?** The 28 matching rows are spread over 12 table pages (`Heap Blocks: exact=12`). That is a moderate number of rows, too many for 28 separate random lookups, but far too few to justify a full table scan. First the index builds a bitmap of the pages that contain matches, then the heap scan reads each of those pages once, in physical order. A plain Index Scan could read the same page several times in random order. The `Recheck Cond` line shows PostgreSQL rechecking the condition on the rows in those pages.
 
### Output D — Hash Join
 
```
Hash Join  (cost=33.50..75.82 rows=120 width=52) (actual time=0.452..1.205 rows=115 loops=1)
  Hash Cond: (oi.product_id = p.id)
  ->  Seq Scan on order_items oi  (cost=0.00..30.40 rows=2040 width=16) (actual time=0.008..0.195 rows=2040 loops=1)
  ->  Hash  (cost=20.00..20.00 rows=500 width=40) (actual time=0.410..0.411 rows=500 loops=1)
        Buckets: 1024  Batches: 1  Memory Usage: 45kB
        ->  Seq Scan on products p  (cost=0.00..20.00 rows=500 width=40) (actual time=0.005..0.180 rows=500 loops=1)
Planning Time: 0.215 ms
Execution Time: 1.340 ms
```
 
**Your analysis:**
 
- Scan type:
- Estimated vs actual rows:
- Execution time:
- Would adding an index improve this join? Which column?
> [!NOTE]
> **_Your Answer_**
>
> - **Scan type:** a Seq Scan on both tables (`order_items` with 2,040 rows and `products` with 500 rows), combined with a Hash Join. PostgreSQL builds a hash table from the smaller table (`products`) in about 45 kB of memory and probes it with every `order_items` row.
> - **Estimated vs actual rows:** the join was estimated at 120 rows and returned 115, and the scans were estimated exactly (2,040 and 500).
> - **Execution time:** 1.340 ms.
> - **Would an index help?** Not for this query. There is no filter, so the join must look at all the `order_items` rows, and a Hash Join is the right algorithm for combining two unfiltered tables. An index on `order_items.product_id` would only start to pay off if a selective `WHERE` reduced the rows to a few, for example one product, because PostgreSQL could then switch to a Nested Loop with an Index Scan. At 1.3 ms there is nothing to fix yet.
 
---
 
## 4. Index Design Exercise (Optional)
 
> [!TIP]
> **Recommended practice.** Do this section. It is not required to finish the TrailShop project. It prepares you for the exams.
 
For each query below, recommend the best index(es), explain why, and predict the scan type PostgreSQL will use after indexing.
 
**Query 1**
 
```sql
SELECT * FROM customers WHERE email = 'anna.korhonen@email.fi';
```
 
**Query 2**
 
```sql
SELECT * FROM orders WHERE customer_id = 5 ORDER BY order_date DESC;
```
 
**Query 3**
 
```sql
SELECT product_id, SUM(quantity) FROM order_items GROUP BY product_id;
```
 
**Query 4**
 
```sql
SELECT * FROM products WHERE price BETWEEN 50 AND 100;
```
 
**Query 5**
 
```sql
SELECT p.name, c.name AS category
FROM products p
JOIN product_categories pc ON pc.product_id = p.product_id
JOIN categories c ON c.category_id = pc.category_id
WHERE pc.category_id = 2;
```
 
**Query 6**
 
```sql
SELECT * FROM payments WHERE order_id = 88;
```
 
**Query 7**
 
```sql
SELECT * FROM orders WHERE status = 'shipped' AND order_date > '2026-06-01';
```
 
**Query 8**
 
```sql
SELECT customer_id, COUNT(*) FROM orders GROUP BY customer_id HAVING COUNT(*) > 5;
```
 
**Query 9**
 
```sql
SELECT oi.quantity, p.name
FROM order_items oi
JOIN products p ON p.id = oi.product_id
WHERE oi.order_id = 100;
```
 
**Query 10**
 
```sql
SELECT * FROM products WHERE name LIKE 'Trail%';
```
 
For each query, fill in:
 
| #   | Recommended Index | Why It Helps | Expected Scan Type |
| --- | ----------------- | ------------ | ------------------ |
| 1   | `CREATE UNIQUE INDEX idx_customers_email ON customers (email);` (a `UNIQUE` constraint on email already creates this index) | Email is unique, so the condition matches at most 1 row (highest selectivity). The unique index also prevents duplicate emails. | Index Scan |
| 2   | `CREATE INDEX idx_orders_customer_date ON orders (customer_id, order_date DESC);` | The index finds this customer's orders (equality on the leftmost column), and the entries are already sorted by date, so PostgreSQL does not need a separate Sort step. | Index Scan (no Sort node) |
| 3   | `CREATE INDEX idx_order_items_product_qty ON order_items (product_id) INCLUDE (quantity);` | The query needs only `product_id` and `quantity`, so a covering index allows an Index Only Scan. The whole table is aggregated, so the gain is limited. On a small table PostgreSQL may prefer a Seq Scan with a HashAggregate. | Index Only Scan (or Seq Scan + HashAggregate on small tables) |
| 4   | `CREATE INDEX idx_products_price ON products (price);` | A B-tree supports range conditions such as `BETWEEN`. It helps only if the range matches a small part of the products. If it matches a big share of the table, PostgreSQL ignores the index. | Bitmap Index Scan + Bitmap Heap Scan (Index Scan for a very narrow range, Seq Scan for a wide one) |
| 5   | `CREATE INDEX idx_product_categories_category_id ON product_categories (category_id);` The primary keys on `products`, `categories` and `product_categories (product_id, category_id)` already exist. | The filter is on `pc.category_id`, which is the second column of the primary key, so the PK cannot be used for it. The new index finds the rows of category 2. The joins then use the primary key indexes of `products` and `categories`. | Bitmap/Index Scan on `product_categories`, then Nested Loop with Index Scans on the primary keys |
| 6   | `CREATE INDEX idx_payments_order_id ON payments (order_id);` | `order_id` is a foreign key and is not indexed automatically. It is selective, because an order has only a few payments. | Index Scan |
| 7   | `CREATE INDEX idx_orders_status_date ON orders (status, order_date);` | The equality column (`status`) goes first and the range column (`order_date`) second, so one index handles both conditions. A partial index such as `(order_date) WHERE status = 'shipped'` would also work if I only query that status. | Index Scan (Bitmap Index Scan if many rows match) |
| 8   | `CREATE INDEX idx_orders_customer_id ON orders (customer_id);` | The index keeps `customer_id` in sorted order, so PostgreSQL can count each group without a separate sort or hash step and can use an Index Only Scan. It does not filter anything, because `HAVING` is applied after the aggregation. It helps only a little, because every order must be counted. | Index Only Scan with GroupAggregate (or Seq Scan + HashAggregate on a small table) |
| 9   | `CREATE INDEX idx_order_items_order_id ON order_items (order_id);` and the primary key on `products` (which already exists). In my schema the join column is `p.product_id`. | The index finds the few items of order 100. Then each item is matched to its product by the primary key. | Index/Bitmap Scan on `order_items`, then Nested Loop with Index Scan on `products_pkey` |
| 10  | `CREATE INDEX idx_products_name_pattern ON products (name text_pattern_ops);` | A B-tree can serve `LIKE 'Trail%'` because the pattern is a fixed prefix, which turns into a range (`>= 'Trail' AND < 'Traim'`). With a normal locale (not the `C` collation) a plain B-tree is not used for LIKE, so `text_pattern_ops` is needed. It would not work for `LIKE '%Trail'`. | Index Scan (or Bitmap Index Scan) |
 
---
 
## 5. Performance Comparison Exercise
 
> [!TIP]
> **Recommended practice.** Do this section. It is not required to finish the TrailShop project. It prepares you for the exams.
 
For each query below, follow these steps:
 
1. Run `EXPLAIN ANALYZE` **without** an index — record the full output
2. Create the recommended index
3. Run `EXPLAIN ANALYZE` **again** — record the full output
4. Calculate the improvement factor (before time ÷ after time)
5. Write one sentence explaining why the improvement occurred (in the **Explanation** field under each comparison)
> [!NOTE]
> **_My test setup_**
>
> I ran these on `trailshop_perf` (the scaled-up copy described in Section 1). Before the section I dropped the five project indexes from Step 2, and after each comparison I dropped the indexes I had just created. That way every "before" measurement had no index on the tested columns and the comparisons did not influence each other. "Rows examined" means the rows PostgreSQL read from the table or index before filtering. Times are from a single run, so small differences of a few hundredths of a millisecond are only noise.
 
### Comparison 1
 
```sql
-- Query
SELECT * FROM order_items WHERE order_id = 55;
 
-- Index to create
CREATE INDEX idx_oi_order_id ON order_items (order_id);
```
 
| Metric              | Before | After |
| ------------------- | ------ | ----- |
| Scan type           | Parallel Seq Scan (under Gather) | Bitmap Index Scan + Bitmap Heap Scan on `idx_oi_order_id` |
| Execution time (ms) | 27.977 | 0.091 |
| Rows examined       | about 900,110 (the whole table) | 3 |
| Improvement factor  | — | about 307× |
 
**Explanation:**
 
> [!NOTE]
> **_Your Answer_**
>
> Without an index PostgreSQL had to read all 900,110 rows to find the 3 items of order 55, and with the index it went straight to those 3 rows, which changes a linear scan into a tree lookup.
 
### Comparison 2
 
```sql
-- Query
SELECT * FROM products p
JOIN product_categories pc ON pc.product_id = p.product_id
WHERE pc.category_id = 2 AND p.price < 80;
 
CREATE INDEX idx_product_categories_category_id ON product_categories (category_id);
CREATE INDEX idx_products_price ON products (price);
 
-- Index to create
CREATE INDEX idx_products_cat_price ON products (category_id, price);
```
 
| Metric              | Before | After |
| ------------------- | ------ | ----- |
| Scan type           | Hash Join with a Seq Scan on `products` and a Seq Scan on `product_categories` | Hash Join with a Bitmap Heap Scan on `products` (via `idx_products_price`) and on `product_categories` (via `idx_product_categories_category_id`) |
| Execution time (ms) | 36.835 | 27.560 |
| Rows examined       | 400,022 (200,011 + 200,011) | about 77,600 (37,597 + 40,002) |
| Improvement factor  | — | about 1.3× |
 
**Explanation:**
 
> [!NOTE]
> **_Your Answer_**
>
> The indexes let PostgreSQL read only the rows that matched each condition instead of both whole tables, but the improvement is small because both conditions match about 20% of their tables (low selectivity). PostgreSQL did not use `idx_products_cat_price` at all, because the filter is on `pc.category_id` of the other table and the index covers `products.category_id`, which the query does not filter on.
 
### Comparison 3
 
```sql
-- Query
SELECT * FROM customers WHERE email = 'test.user@example.com';
 
-- Index to create
CREATE UNIQUE INDEX idx_customers_email ON customers (email);
```
 
| Metric              | Before | After |
| ------------------- | ------ | ----- |
| Scan type           | Index Scan using `customers_email_key` | Index Scan using `idx_customers_email` |
| Execution time (ms) | 0.050 | 0.043 |
| Rows examined       | 1 | 1 |
| Improvement factor  | — | about 1× (no real change) |
 
**Explanation:**
 
> [!NOTE]
> **_Your Answer_**
>
> There was no improvement because my `customers.email` column is declared `UNIQUE`, and PostgreSQL had already created a unique index for that constraint (`customers_email_key`), so the new index is a duplicate that only adds write cost and I would drop it. On a table without that constraint I would expect a Seq Scan before and a large improvement after.
 
### Comparison 4
 
```sql
-- Query
SELECT order_id, SUM(quantity * unit_price) AS total
FROM order_items
WHERE order_id IN (10, 20, 30, 40, 50)
GROUP BY order_id;
 
-- Index to create
CREATE INDEX idx_oi_order_id_covering ON order_items (order_id) INCLUDE (quantity, unit_price);
```
 
| Metric              | Before | After |
| ------------------- | ------ | ----- |
| Scan type           | Parallel Seq Scan with Finalize GroupAggregate | Index Only Scan using `idx_oi_order_id_covering` with GroupAggregate |
| Execution time (ms) | 35.788 | 0.104 |
| Rows examined       | about 900,110 (the whole table) | 15 (index entries only) |
| Improvement factor  | — | about 344× |
 
**Explanation:**
 
> [!NOTE]
> **_Your Answer_**
>
> The covering index contains `order_id`, `quantity` and `unit_price`, so PostgreSQL could read the 15 needed entries from the index alone (an Index Only Scan) without touching the table, whereas before it had to read every row.
 
### Comparison 5
 
```sql
-- Query
SELECT * FROM orders WHERE status = 'pending';
 
-- Index to create (partial index)
CREATE INDEX idx_orders_pending ON orders (status) WHERE status = 'pending';
```
 
| Metric              | Before | After |
| ------------------- | ------ | ----- |
| Scan type           | Seq Scan | Bitmap Index Scan + Bitmap Heap Scan on `idx_orders_pending` |
| Execution time (ms) | 18.452 | 10.380 |
| Rows examined       | 300,035 (250,309 removed by the filter) | 49,726 |
| Improvement factor  | — | about 1.8× |
 
**Explanation:**
 
> [!NOTE]
> **_Your Answer_**
>
> The partial index holds only the pending orders, so PostgreSQL could skip the 250,309 other rows, but the gain is modest because about 17% of my test orders are pending, and `SELECT *` still has to fetch every matching row from the table. In a real shop, where only a tiny share of the orders is pending, the same index would give a much larger improvement.
 
---
 
## Submission Checklist
 
**Required**
 
- [x] Baseline measurements for all 5 project queries
- [x] All 5 indexes created and re-measured
- [x] Comparison table filled with before/after data
- [x] Recommendation paragraph written
- [x] All 8 theory questions answered
**Recommended practice**
 
- [x] All 4 EXPLAIN outputs analyzed
- [x] Index recommendations for all 10 queries
- [x] All 5 performance comparisons completed with explanations
 
