# Week 44 — Exercises: Advanced SQL
 
> [!IMPORTANT]
> ***How to Complete These Exercises***
> Write your answers directly in the highlighted **Your Answer** / **Your SQL** fields below each task. Replace the placeholder text with your own work before submitting.
 
## 1. TrailShop Project Task
 
Continue building the TrailShop database. This week, use advanced query techniques to extract meaningful insights.
 
### Task 1.1: Subqueries
 
Write the following queries using subqueries:
 
1. Find all products priced above the average price (use a scalar subquery).
> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- The scalar subquery runs first and returns one number (the average price)
> SELECT name, price
> FROM products
> WHERE price > (SELECT AVG(price) FROM products);
> ```
 
2. Find all customers who have placed more than 2 orders (use a subquery in WHERE with IN).
> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- The inner query returns the IDs of customers with more than 2 orders.
> -- With the small sample data this may return no rows (nobody has 3+ orders yet).
> SELECT first_name, last_name
> FROM customers
> WHERE customer_id IN (
>     SELECT customer_id
>     FROM orders
>     GROUP BY customer_id
>     HAVING COUNT(*) > 2
> );
> ```
 
3. Show each product's name, price, and how much it differs from its category's average price (use a correlated subquery or derived table).
> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- Correlated subquery: for every product it recalculates the average of ITS category
> SELECT p.name,
>        p.price,
>        ROUND(p.price - (SELECT AVG(p2.price)
>                         FROM products p2
>                         WHERE p2.category_id = p.category_id), 2) AS diff_from_category_avg
> FROM products p
> ORDER BY p.category_id, p.name;
> ```
 
### Task 1.2: EXISTS
 
1. Use EXISTS to find all customers who have ordered at least one product from the "Footwear" category.
> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- EXISTS only checks that at least one matching row exists, so SELECT 1 is enough
> SELECT c.first_name, c.last_name
> FROM customers c
> WHERE EXISTS (
>     SELECT 1
>     FROM orders o
>     JOIN order_items oi ON oi.order_id = o.order_id
>     JOIN products p ON p.product_id = oi.product_id
>     JOIN categories cat ON cat.category_id = p.category_id
>     WHERE o.customer_id = c.customer_id
>       AND cat.name = 'Footwear'
> );
> ```
 
2. Use NOT EXISTS to find all products that have never been ordered.
> [!NOTE]
> ***Your SQL***
>
> ```sql
> SELECT p.name, p.price
> FROM products p
> WHERE NOT EXISTS (
>     SELECT 1
>     FROM order_items oi
>     WHERE oi.product_id = p.product_id
> );
> ```
 
### Task 1.3: CASE Expressions
 
1. Add a price_tier column to a product query that labels products as 'Budget' (< €25), 'Standard' (€25–€74.99), or 'Premium' (≥ €75).
> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- CASE is checked top to bottom and stops at the first true condition
> SELECT name,
>        price,
>        CASE
>            WHEN price < 25 THEN 'Budget'
>            WHEN price < 75 THEN 'Standard'
>            ELSE 'Premium'
>        END AS price_tier
> FROM products
> ORDER BY price;
> ```
 
2. Write a query that counts orders by status using CASE inside COUNT.
> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- COUNT ignores NULLs, and CASE without ELSE returns NULL when the condition is false,
> -- so each COUNT only counts the rows of one status
> SELECT COUNT(*) AS total_orders,
>        COUNT(CASE WHEN status = 'pending'   THEN 1 END) AS pending,
>        COUNT(CASE WHEN status = 'shipped'   THEN 1 END) AS shipped,
>        COUNT(CASE WHEN status = 'delivered' THEN 1 END) AS delivered,
>        COUNT(CASE WHEN status = 'cancelled' THEN 1 END) AS cancelled
> FROM orders;
> ```
 
### Task 1.4: Create Three Views
 
Create the following views in your TrailShop database:
 
- v_product_catalog — Shows product name, category name, price, and stock status ('In Stock', 'Low Stock' for < 5 units, 'Out of Stock' for 0).
- v_customer_summary — Shows each customer's full name, email, number of orders, and total spent.
- v_monthly_revenue — Shows revenue grouped by month.
Verify each view works with a simple SELECT.
 
> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- View 1: product catalog with category name and stock status
> CREATE VIEW v_product_catalog AS
> SELECT p.name AS product_name,
>        c.name AS category_name,
>        p.price,
>        CASE
>            WHEN p.stock = 0 THEN 'Out of Stock'
>            WHEN p.stock < 5 THEN 'Low Stock'
>            ELSE 'In Stock'
>        END AS stock_status
> FROM products p
> JOIN categories c ON c.category_id = p.category_id;
>
> -- View 2: customer summary
> -- LEFT JOINs keep customers with no orders; COUNT(DISTINCT ...) stops orders being
> -- counted once per item; COALESCE turns the NULL total into 0
> CREATE VIEW v_customer_summary AS
> SELECT c.first_name || ' ' || c.last_name AS full_name,
>        c.email,
>        COUNT(DISTINCT o.order_id) AS order_count,
>        COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS total_spent
> FROM customers c
> LEFT JOIN orders o ON o.customer_id = c.customer_id
> LEFT JOIN order_items oi ON oi.order_id = o.order_id
> GROUP BY c.customer_id, c.first_name, c.last_name, c.email;
>
> -- View 3: revenue per month (DATE_TRUNC cuts a timestamp down to the start of its month)
> CREATE VIEW v_monthly_revenue AS
> SELECT DATE_TRUNC('month', o.order_date) AS month,
>        SUM(oi.quantity * oi.unit_price) AS revenue
> FROM orders o
> JOIN order_items oi ON oi.order_id = o.order_id
> GROUP BY DATE_TRUNC('month', o.order_date);
>
> -- Verify
> SELECT * FROM v_product_catalog;
> SELECT * FROM v_customer_summary;
> SELECT * FROM v_monthly_revenue ORDER BY month;
> ```
 
### Task 1.5: UNION
 
1. Write a UNION query that combines product names from two different categories into one list (without duplicates).
> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- UNION stacks the two result sets and removes duplicate rows
> SELECT name FROM products WHERE category_id = 1
> UNION
> SELECT name FROM products WHERE category_id = 2
> ORDER BY name;
> ```
 
2. Write a query using EXCEPT to find categories that have products but no orders.
> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- First query: categories that have products.
> -- Second query: categories that have at least one ordered product.
> -- EXCEPT keeps what is in the first but not in the second.
> SELECT c.name
> FROM categories c
> JOIN products p ON p.category_id = c.category_id
> EXCEPT
> SELECT c.name
> FROM categories c
> JOIN products p ON p.category_id = c.category_id
> JOIN order_items oi ON oi.product_id = p.product_id;
> ```
 
### Task 1.6: CTE
 
1. Write a CTE that calculates total revenue per category, then use it to find categories with above-average revenue.
> [!NOTE]
> ***Your SQL***
>
> ```sql
> WITH category_revenue AS (
>     SELECT p.category_id,
>            SUM(oi.quantity * oi.unit_price) AS revenue
>     FROM products p
>     JOIN order_items oi ON oi.product_id = p.product_id
>     GROUP BY p.category_id
> )
> SELECT c.name AS category, cr.revenue
> FROM category_revenue cr
> JOIN categories c ON c.category_id = cr.category_id
> WHERE cr.revenue > (SELECT AVG(revenue) FROM category_revenue)
> ORDER BY cr.revenue DESC;
> ```
 
2. Write a query with two CTEs: one for customer order counts, another for average order count, then find "top customers" (above average).
> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- The second CTE reads from the first one
> WITH customer_orders AS (
>     SELECT c.customer_id, c.first_name, c.last_name,
>            COUNT(o.order_id) AS order_count
>     FROM customers c
>     LEFT JOIN orders o ON o.customer_id = c.customer_id
>     GROUP BY c.customer_id, c.first_name, c.last_name
> ),
> avg_orders AS (
>     SELECT AVG(order_count) AS avg_count
>     FROM customer_orders
> )
> SELECT co.first_name, co.last_name, co.order_count
> FROM customer_orders co
> CROSS JOIN avg_orders a
> WHERE co.order_count > a.avg_count
> ORDER BY co.order_count DESC;
> ```
 
---
 
## 2. Theory Review Questions
 
Answer these in your own words (2–4 sentences each):
 
1. What is the difference between an INNER JOIN and a LEFT JOIN? When would you choose LEFT JOIN?
> [!NOTE]
> ***Your Answer***
>
> An INNER JOIN only returns rows that have a match in both tables, so anything without a partner is dropped. A LEFT JOIN returns every row from the left table and fills the right table's columns with NULL when there is no match. I choose LEFT JOIN when the unmatched rows are what I care about, for example listing all customers including those who have never ordered, or finding them with `WHERE o.order_id IS NULL`.
 
2. Explain what a correlated subquery is. Why can it be slower than an uncorrelated subquery?
> [!NOTE]
> ***Your Answer***
>
> A correlated subquery refers to a column of the outer query, so it can't be run on its own. Conceptually it is executed once for every row of the outer query, like a loop, for example "average price of this product's category". An uncorrelated subquery is independent, so it runs once and its result is reused. On large tables the repeated executions can be slow, so I would consider rewriting it as a JOIN or a derived table.
 
3. What is the difference between IN and EXISTS? When might you prefer EXISTS?
> [!NOTE]
> ***Your Answer***
>
> IN compares a value against the list of values returned by a subquery, while EXISTS only checks whether the subquery returns at least one row and ignores the actual values. I prefer EXISTS when the subquery result is large or the condition is complex, because it can stop at the first match. I also prefer NOT EXISTS over NOT IN, because NOT IN returns nothing if the list contains a NULL.
 
4. What rules must two SELECT statements follow to be combined with UNION?
> [!NOTE]
> ***Your Answer***
>
> Both SELECT statements must return the same number of columns, and the columns in the same position must have compatible data types (for example both numbers or both text). The column names of the result are taken from the first SELECT. An ORDER BY can only be written once, at the very end.
 
5. Explain the difference between UNION and UNION ALL. When would you use each?
> [!NOTE]
> ***Your Answer***
>
> UNION combines the results and removes duplicate rows, while UNION ALL keeps every row including duplicates and is faster because it skips the duplicate check. I use UNION when I want a list of unique values, such as all cities from two tables. I use UNION ALL when I know there are no duplicates or when duplicates matter, for example when counting total occurrences.
 
6. What is a view? Name two advantages of using views.
> [!NOTE]
> ***Your Answer***
>
> A view is a named, stored SELECT query that behaves like a virtual table: each time I query it, the database runs the underlying query. One advantage is simplicity, because I write a complex join once and reuse it by name. Another is security and abstraction: I can give users access to a view that hides sensitive columns, and I can change the underlying tables without breaking the queries that use the view.
 
7. What does WITH CHECK OPTION do on an updatable view?
> [!NOTE]
> ***Your Answer***
>
> It stops INSERTs and UPDATEs through the view that would produce a row the view itself could not show. For example, if the view has `WHERE stock_quantity > 0`, then updating a row through it to stock 0 is rejected with an error like `new row violates check option for view`. This keeps the data consistent with the view's filter.
 
8. How does a CTE differ from a derived table (subquery in FROM)? What's the main advantage of CTEs?
> [!NOTE]
> ***Your Answer***
>
> Both create a temporary result set for one query, but a CTE is defined first with `WITH name AS (...)` and given a name, while a derived table is written inside the FROM clause and needs an alias. The main advantage of a CTE is readability: the query reads top to bottom in named steps instead of inside-out. A CTE can also be referenced several times in the same query, and CTEs can be chained or made recursive.
 
---
 
## 3. Query Writing Exercises
 
Write SQL queries for the following (use the TrailShop schema):
 
1. Find the most expensive product in each category using a correlated subquery.
> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- For each product, the subquery finds the highest price in the same category
> SELECT p.name, p.price, p.category_id
> FROM products p
> WHERE p.price = (
>     SELECT MAX(p2.price)
>     FROM products p2
>     WHERE p2.category_id = p.category_id
> )
> ORDER BY p.category_id;
> ```
 
2. List all customers along with their most recent order date. Include customers who have never ordered (show NULL).
> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- LEFT JOIN keeps customers without orders; MAX over no rows gives NULL
> SELECT c.first_name, c.last_name,
>        MAX(o.order_date) AS most_recent_order
> FROM customers c
> LEFT JOIN orders o ON o.customer_id = c.customer_id
> GROUP BY c.customer_id, c.first_name, c.last_name
> ORDER BY c.last_name;
> ```
 
3. Find categories where the total revenue exceeds €500 (use a subquery or CTE).
> [!NOTE]
> ***Your SQL***
>
> ```sql
> WITH category_revenue AS (
>     SELECT p.category_id,
>            SUM(oi.quantity * oi.unit_price) AS revenue
>     FROM products p
>     JOIN order_items oi ON oi.product_id = p.product_id
>     GROUP BY p.category_id
> )
> SELECT c.name AS category, cr.revenue
> FROM category_revenue cr
> JOIN categories c ON c.category_id = cr.category_id
> WHERE cr.revenue > 500;
> ```
 
4. Write a query that shows each order's total and whether it's 'Small' (< €50), 'Medium' (€50–€149.99), or 'Large' (≥ €150).
> [!NOTE]
> ***Your SQL***
>
> ```sql
> SELECT o.order_id,
>        SUM(oi.quantity * oi.unit_price) AS order_total,
>        CASE
>            WHEN SUM(oi.quantity * oi.unit_price) < 50  THEN 'Small'
>            WHEN SUM(oi.quantity * oi.unit_price) < 150 THEN 'Medium'
>            ELSE 'Large'
>        END AS order_size
> FROM orders o
> JOIN order_items oi ON oi.order_id = o.order_id
> GROUP BY o.order_id
> ORDER BY o.order_id;
> ```
 
5. Create a view called v_never_ordered that shows products that have never appeared in an order_item.
> [!NOTE]
> ***Your SQL***
>
> ```sql
> CREATE VIEW v_never_ordered AS
> SELECT p.product_id, p.name, p.price
> FROM products p
> LEFT JOIN order_items oi ON oi.product_id = p.product_id
> WHERE oi.order_item_id IS NULL;
>
> -- Verify
> SELECT * FROM v_never_ordered;
> ```
 
6. Use EXCEPT to find products that exist in the products table but have never been ordered.
> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- EXCEPT works on matching columns, so I subtract the ordered product IDs from all
> -- product IDs, then look up the names of what is left
> SELECT name
> FROM products
> WHERE product_id IN (
>     SELECT product_id FROM products
>     EXCEPT
>     SELECT product_id FROM order_items
> );
> ```
 
7. Write a CTE that ranks categories by number of products, then selects only the top 3.
> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- ORDER BY + LIMIT 3 gives the top 3. If several categories have the same count,
> -- the name is used as a tie-breaker.
> WITH category_counts AS (
>     SELECT c.name AS category,
>            COUNT(p.product_id) AS product_count
>     FROM categories c
>     LEFT JOIN products p ON p.category_id = c.category_id
>     GROUP BY c.category_id, c.name
> )
> SELECT category, product_count
> FROM category_counts
> ORDER BY product_count DESC, category
> LIMIT 3;
> ```
 
8. Use NOT EXISTS to find categories that have no products.
> [!NOTE]
> ***Your SQL***
>
> ```sql
> SELECT c.name
> FROM categories c
> WHERE NOT EXISTS (
>     SELECT 1
>     FROM products p
>     WHERE p.category_id = c.category_id
> );
> ```
 
9. Write a query using CASE that creates a "customer loyalty" label: 'New' (1 order), 'Regular' (2–5 orders), 'VIP' (6+ orders).
> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- Customers with 0 orders don't fit any of the three labels, so I added 'No orders'
> SELECT c.first_name, c.last_name,
>        COUNT(o.order_id) AS order_count,
>        CASE
>            WHEN COUNT(o.order_id) = 0 THEN 'No orders'
>            WHEN COUNT(o.order_id) = 1 THEN 'New'
>            WHEN COUNT(o.order_id) <= 5 THEN 'Regular'
>            ELSE 'VIP'
>        END AS loyalty
> FROM customers c
> LEFT JOIN orders o ON o.customer_id = c.customer_id
> GROUP BY c.customer_id, c.first_name, c.last_name;
> ```
 
10. Use GREATEST to find the higher value between each product's current price and the average price of all products in its category.
> [!NOTE]
> ***Your SQL***
>
> ```sql
> SELECT p.name,
>        p.price,
>        ROUND((SELECT AVG(p2.price) FROM products p2
>               WHERE p2.category_id = p.category_id), 2) AS category_avg,
>        ROUND(GREATEST(p.price,
>                       (SELECT AVG(p2.price) FROM products p2
>                        WHERE p2.category_id = p.category_id)), 2) AS higher_value
> FROM products p;
> ```
 
11. Write a query using COALESCE that shows order shipping dates, substituting 'Not yet shipped' for NULL values.
> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- My orders table has no shipping date column yet, so I add one first (run once):
> ALTER TABLE orders ADD COLUMN shipped_date DATE;
>
> -- COALESCE needs both values to be the same type, so the date is cast to text
> SELECT order_id,
>        status,
>        COALESCE(shipped_date::text, 'Not yet shipped') AS shipping_date
> FROM orders;
> ```
 
12. Use a scalar subquery in the SELECT clause to show each product alongside the total number of times it has been ordered.
> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- For each product the subquery counts its rows in order_items (0 if never ordered)
> SELECT p.name,
>        (SELECT COUNT(*)
>         FROM order_items oi
>         WHERE oi.product_id = p.product_id) AS times_ordered
> FROM products p
> ORDER BY times_ordered DESC, p.name;
> ```
 
---
 
## 4. Query Comparison Exercise
 
For each pair of queries below, both produce the same result. Explain which approach you'd prefer and why (consider readability, performance, and maintainability).
 
> [!NOTE]
> ***Your Answer***
>
> **Pair A (customers with orders):** I prefer the subquery with IN (or EXISTS). It says directly what I mean, "customers whose ID appears in orders", and it needs no DISTINCT. The JOIN version produces one row per order, so DISTINCT is needed to remove the duplicates, which adds work and can hide mistakes. If I also needed columns from `orders` (like the order date), I would switch to the JOIN.
>
> **Pair B (products never ordered):** I prefer NOT EXISTS. It reads like the question ("no order item exists for this product"), it can stop at the first match, and it handles NULLs safely. LEFT JOIN + IS NULL is also correct and PostgreSQL usually plans both the same way, so the difference is mostly readability. I find NOT EXISTS clearer, but I would not mind the LEFT JOIN version if my team used it consistently.
>
> **Pair C (customer total spending):** I prefer the CTE. It reads top to bottom: first calculate the totals, then filter them. The derived table forces me to read inside-out. Performance is the same in modern PostgreSQL because both are inlined. The CTE is also easier to maintain, since it has a name, can be reused in the same query and I can add more CTEs later.

### Pair A: Finding customers with orders

**Version 1 — Subquery with IN:**

```sql
SELECT first_name, last_name
FROM customers
WHERE customer_id IN (SELECT customer_id FROM orders);
```

**Version 2 — JOIN:**

```sql
SELECT DISTINCT c.first_name, c.last_name
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id;
```

### Pair B: Finding products never ordered

**Version 1 — LEFT JOIN + IS NULL:**

```sql
SELECT p.product_name
FROM products p
LEFT JOIN order_items oi ON oi.product_id = p.product_id
WHERE oi.order_item_id IS NULL;
```

**Version 2 — NOT EXISTS:**

```sql
SELECT p.product_name
FROM products p
WHERE NOT EXISTS (
    SELECT 1 FROM order_items oi WHERE oi.product_id = p.product_id
);
```

### Pair C: Customer total spending

**Version 1 — Derived table (subquery in FROM):**

```sql
SELECT sub.full_name, sub.total_spent
FROM (
    SELECT c.first_name || ' ' || c.last_name AS full_name,
           SUM(oi.quantity * oi.unit_price) AS total_spent
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY c.customer_id, c.first_name, c.last_name
) sub
WHERE sub.total_spent > 200;
```

**Version 2 — CTE:**

```sql
WITH customer_totals AS (
    SELECT c.first_name || ' ' || c.last_name AS full_name,
           SUM(oi.quantity * oi.unit_price) AS total_spent
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY c.customer_id, c.first_name, c.last_name
)
SELECT full_name, total_spent
FROM customer_totals
WHERE total_spent > 200;
```
---
 
## Submission Checklist
 
- [ ] All Task 1.1–1.6 queries and the three views written and tested
- [ ] Theory review questions answered in my own words
- [ ] All 12 query writing exercises completed
- [ ] Query comparison answered for pairs A, B and C
- [ ] Results verified by running the queries against my TrailShop database
 
