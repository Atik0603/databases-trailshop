# Week 41 — Exercises: Querying Data

> [!IMPORTANT]
> ***How to Complete These Exercises***
> Write your answers directly in the highlighted **Your Answer** / **Your SQL** fields below each task. Replace the placeholder text with your own work before submitting.

## Exercise 1: TrailShop Project Task — Business Questions

Use the TrailShop database you created in Week 40. Write SQL queries to answer each business question below. Run each query and verify the results make sense.

### Basic Queries (SELECT + WHERE)

1. List all products in the 'Footwear' category (show name, price, stock).
> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- products only stores category_id, so join categories to filter by name
> SELECT p.name, p.price, p.stock
> FROM products p
> JOIN categories c ON c.category_id = p.category_id
> WHERE c.name = 'Footwear';
> ```

2. Find all products priced between €50 and €150, sorted by price ascending.
> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- BETWEEN is inclusive: price >= 50 AND price <= 150
> SELECT name, price
> FROM products
> WHERE price BETWEEN 50 AND 150
> ORDER BY price ASC;
> ```

3. Show all customers whose last name starts with the letter 'M' or 'K'.
> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- % matches any characters, so 'M%' means "starts with M"
> SELECT *
> FROM customers
> WHERE last_name LIKE 'M%' OR last_name LIKE 'K%';
> ```

4. List all orders with status 'pending' or 'shipped', sorted by order date (most recent first).
> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- IN (...) is shorthand for several ORs
> SELECT *
> FROM orders
> WHERE status IN ('pending', 'shipped')
> ORDER BY order_date DESC;
> ```

5. Find all products that have the word 'Pro' or 'pro' somewhere in their name.
> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- ILIKE ignores case, so it covers both 'Pro' and 'pro'
> SELECT name, price, stock
> FROM products
> WHERE name ILIKE '%pro%';
> ```

### Aggregate Queries

6. What is the total number of products in the database?

> [!NOTE]
> ***Your SQL***
>
> ```sql
> SELECT COUNT(*) AS total_products
> FROM products;
> ```

7. What is the average price of all products? Round to 2 decimal places.
> [!NOTE]
> ***Your SQL***
>
> ```sql
> SELECT ROUND(AVG(price), 2) AS average_price
> FROM products;
> ```

8. Which is the most expensive product and which is the cheapest? Show both in one query.
> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- Each half needs its own ORDER BY + LIMIT, so each is in parentheses.
> -- UNION ALL stacks the two results into one table.
> (SELECT 'most expensive' AS label, name, price FROM products ORDER BY price DESC LIMIT 1)
> UNION ALL
> (SELECT 'cheapest', name, price FROM products ORDER BY price ASC LIMIT 1);
> ```

9. How many orders does each customer have? Show customer name and order count, sorted by count descending.
> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- LEFT JOIN keeps customers with no orders.
> -- COUNT(o.order_id) ignores NULLs, so they correctly get 0 (COUNT(*) would give 1).
> SELECT c.first_name || ' ' || c.last_name AS customer,
>        COUNT(o.order_id) AS order_count
> FROM customers c
> LEFT JOIN orders o ON o.customer_id = c.customer_id
> GROUP BY c.customer_id, c.first_name, c.last_name
> ORDER BY order_count DESC;
> ```

10. What is the total revenue (sum of quantity × unit_price from order_items) for each order status?

> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- unit_price in order_items is the price at purchase time, so use it (not products.price)
> SELECT o.status,
>        SUM(oi.quantity * oi.unit_price) AS revenue
> FROM orders o
> JOIN order_items oi ON oi.order_id = o.order_id
> GROUP BY o.status;
> ```

### JOIN Queries

11. List all products with their category names (not just category_id). Sort by category name, then product name.
> [!NOTE]
> ***Your SQL***
>
> ```sql
> SELECT p.name AS product, c.name AS category
> FROM products p
> JOIN categories c ON c.category_id = p.category_id
> ORDER BY c.name, p.name;
> ```

12. Show each order with the customer's full name, order date, and status.
> [!NOTE]
> ***Your SQL***
>
> ```sql
> SELECT c.first_name || ' ' || c.last_name AS customer,
>        o.order_date,
>        o.status
> FROM orders o
> JOIN customers c ON c.customer_id = o.customer_id;
> ```

13. Show a detailed breakdown of order #1: product name, quantity, unit price, and line total.
> [!NOTE]
> ***Your SQL***
>
> ```sql
> SELECT p.name, oi.quantity, oi.unit_price,
>        oi.quantity * oi.unit_price AS line_total
> FROM order_items oi
> JOIN products p ON p.product_id = oi.product_id
> WHERE oi.order_id = 1;
> ```

14. Find all customers who have NOT placed any orders. (Hint: use LEFT JOIN + IS NULL pattern.)
> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- LEFT JOIN fills NULLs where no order matches; IS NULL keeps only those customers
> SELECT c.first_name, c.last_name, c.email
> FROM customers c
> LEFT JOIN orders o ON o.customer_id = c.customer_id
> WHERE o.order_id IS NULL;
> ```

15. For each category, show the category name, number of products, average price, and total inventory value (price × stock summed). Only include categories with total inventory value greater than €500.
> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- The condition uses an aggregate (SUM), so it must go in HAVING, not WHERE
> SELECT c.name AS category,
>        COUNT(*) AS product_count,
>        ROUND(AVG(p.price), 2) AS avg_price,
>        SUM(p.price * p.stock) AS inventory_value
> FROM categories c
> JOIN products p ON p.category_id = c.category_id
> GROUP BY c.category_id, c.name
> HAVING SUM(p.price * p.stock) > 500;
> ```

---

## Exercise 2: Theory Review Questions

Answer in your own words:

1. What is the logical execution order of a SQL query? Why does it matter?

> [!NOTE]
> ***Your Answer***
>
> The logical order is: FROM/JOIN, WHERE, GROUP BY, HAVING, SELECT, DISTINCT, ORDER BY, LIMIT/OFFSET. This is different from the order the clauses are written in. It matters because each step can only use what earlier steps have produced. For example, a column alias created in SELECT can't be used in WHERE (which runs earlier) but can be used in ORDER BY (which runs later).



2. What is the difference between WHERE and HAVING? Give an example of when you would use each.

> [!NOTE]
> ***Your Answer***
>
> WHERE filters individual rows before grouping, so it can't use aggregate functions. HAVING filters whole groups after GROUP BY, so it can use aggregates. Example: `WHERE stock > 0` removes out-of-stock products before anything is grouped, and `HAVING AVG(price) > 100` then keeps only the categories whose average price is above 100.

3. Explain the difference between COUNT(*), COUNT(column), and COUNT(DISTINCT column).

> [!NOTE]
> ***Your Answer***
>
> `COUNT(*)` counts all rows, including rows that contain NULLs. `COUNT(column)` counts only the rows where that column is not NULL. `COUNT(DISTINCT column)` counts the number of different non-NULL values in that column.

4. What is the difference between INNER JOIN and LEFT JOIN? When would you choose one over the other?

> [!NOTE]
> ***Your Answer***
>
> INNER JOIN returns only the rows that have a match in both tables. LEFT JOIN returns every row from the left table and fills the right table's columns with NULL when there is no match. I use INNER JOIN when I only want related data (for example orders with their customers) and LEFT JOIN when the unmatched rows matter too (for example customers who have never ordered).



5. Why should you avoid SELECT * in production code?

> [!NOTE]
> ***Your Answer***
>
> If columns are added, removed or reordered, the query's result changes silently and can break the code that uses it. It also transfers more data than needed, which is slower, and it hides which columns the code actually depends on, which makes it harder to read and maintain.



6. What does DISTINCT do? On what level does it operate (columns or entire rows)?

> [!NOTE]
> ***Your Answer***
>
> DISTINCT removes duplicate rows from the result. It works on entire rows, not on a single column. Two rows count as duplicates only when every selected column has the same value.



7. Can you use a column alias in a WHERE clause? Why or why not?



> [!NOTE]
> ***Your Answer***
>
> No. WHERE is executed before SELECT, so the alias does not exist yet when WHERE runs. I have to repeat the original expression in WHERE. Aliases do work in ORDER BY because ORDER BY runs after SELECT.

8. Explain what happens when you GROUP BY a column and there's a column in SELECT that isn't aggregated and isn't in GROUP BY.

> [!NOTE]
> ***Your Answer***
>
> PostgreSQL raises an error saying the column must appear in the GROUP BY clause or be used in an aggregate function. Each group contains many rows, so there are many values of that column and SQL has no way to know which one to show.

---

## Exercise 3: Query Writing Exercises

Write the SQL for each task. Use the TrailShop schema (categories, customers, products, orders, order_items).

### Simple SELECT + WHERE

**3.1** — Select product names and prices for all products with stock less than 15.

> [!NOTE]
> ***Your SQL***
>
> ```sql
> SELECT name, price
> FROM products
> WHERE stock < 15;
> ```


**3.2** — Find all customers who registered (created_at) in 2026. Show first name, last name, and registration date.

> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- A date range is safer than extracting the year from the column
> SELECT first_name, last_name, created_at
> FROM customers
> WHERE created_at >= '2026-01-01' AND created_at < '2027-01-01';
> ```


**3.3** — Show all products that do NOT have a description (description IS NULL).

> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- Always IS NULL, never = NULL
> SELECT name
> FROM products
> WHERE description IS NULL;
> ```


### Multi-condition Filtering

**3.4** — Find products in category 1 OR category 2, priced above €100, with stock greater than 0. Sort by price descending.

> [!NOTE]
> ***Your SQL***
>
> ```sql
> SELECT name, price, stock, category_id
> FROM products
> WHERE category_id IN (1, 2)
>   AND price > 100
>   AND stock > 0
> ORDER BY price DESC;
> ```


**3.5** — Find orders that are either 'delivered' or placed by customer_id 1. Show order_id, customer_id, status.

> [!NOTE]
> ***Your SQL***
>
> ```sql
> SELECT order_id, customer_id, status
> FROM orders
> WHERE status = 'delivered' OR customer_id = 1;
> ```


### Aggregation

**3.6** — For each category_id, show the minimum, maximum, and average price. Round averages to 2 decimal places.

> [!NOTE]
> ***Your SQL***
>
> ```sql
> SELECT category_id,
>        MIN(price) AS min_price,
>        MAX(price) AS max_price,
>        ROUND(AVG(price), 2) AS avg_price
> FROM products
> GROUP BY category_id;
> ```


**3.7** — Count how many distinct customers have placed at least one order.

> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- DISTINCT is needed, otherwise this would count orders, not customers
> SELECT COUNT(DISTINCT customer_id) AS customers_with_orders
> FROM orders;
> ```


**3.8** — Find the total quantity of items sold across all orders.

> [!NOTE]
> ***Your SQL***
>
> ```sql
> SELECT SUM(quantity) AS total_units_sold
> FROM order_items;
> ```


### JOIN Queries

**3.9** — Show each product name alongside its category name. Include all products (even if somehow a category was deleted — use LEFT JOIN).

> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- LEFT JOIN keeps every product; category name is NULL if no category matches
> SELECT p.name AS product, c.name AS category
> FROM products p
> LEFT JOIN categories c ON c.category_id = p.category_id;
> ```


**3.10** — List all orders showing: order_id, customer full name, order date, number of items in the order, and order total cost.

> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- Every selected column that is not aggregated must be in GROUP BY
> SELECT o.order_id,
>        c.first_name || ' ' || c.last_name AS customer,
>        o.order_date,
>        SUM(oi.quantity) AS total_items,
>        SUM(oi.quantity * oi.unit_price) AS order_total
> FROM orders o
> JOIN customers c ON c.customer_id = o.customer_id
> JOIN order_items oi ON oi.order_id = o.order_id
> GROUP BY o.order_id, c.first_name, c.last_name, o.order_date
> ORDER BY o.order_id;
> ```


**3.11** — Show all products that have NEVER been ordered. (Hint: LEFT JOIN order_items, then IS NULL on order_item_id.)

> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- Same anti-join pattern as exercise 14
> SELECT p.name
> FROM products p
> LEFT JOIN order_items oi ON oi.product_id = p.product_id
> WHERE oi.order_item_id IS NULL;
> ```


### GROUP BY + HAVING

**3.12** — Show categories where the average product price exceeds €100. Display category name and average price.

> [!NOTE]
> ***Your SQL***
>
> ```sql
> SELECT c.name AS category,
>        ROUND(AVG(p.price), 2) AS avg_price
> FROM categories c
> JOIN products p ON p.category_id = c.category_id
> GROUP BY c.category_id, c.name
> HAVING AVG(p.price) > 100;
> ```


**3.13** — Find customers who have placed more than 1 order. Show their name and order count.

> [!NOTE]
> ***Your SQL***
>
> ```sql
> SELECT c.first_name, c.last_name,
>        COUNT(o.order_id) AS order_count
> FROM customers c
> JOIN orders o ON o.customer_id = c.customer_id
> GROUP BY c.customer_id, c.first_name, c.last_name
> HAVING COUNT(o.order_id) > 1;
> ```


### Pagination

**3.14** — Write a paginated query that returns products 4 through 6 (page 2, page size 3), ordered by product_id.

> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- OFFSET = (page_number - 1) * page_size = (2 - 1) * 3 = 3
> -- Always ORDER BY when paginating so pages are stable
> SELECT *
> FROM products
> ORDER BY product_id
> LIMIT 3 OFFSET 3;
> ```


### Complex

**3.15** — Write a "sales report" query that shows: category name, total units sold (from order_items), total revenue, and number of distinct products sold — for each category. Sort by revenue descending.

> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- COUNT(DISTINCT ...) so a product sold in several orders is only counted once
> SELECT c.name AS category,
>        SUM(oi.quantity) AS units_sold,
>        SUM(oi.quantity * oi.unit_price) AS revenue,
>        COUNT(DISTINCT p.product_id) AS distinct_products_sold
> FROM categories c
> JOIN products p ON p.category_id = c.category_id
> JOIN order_items oi ON oi.product_id = p.product_id
> GROUP BY c.category_id, c.name
> ORDER BY revenue DESC;
> ```


---

## Exercise 4: Query Reading Exercise

For each query below, explain in **plain English** what it does and what the result would look like.

### 4.1

```sql
SELECT c.name, COUNT(p.product_id) AS num_products
FROM categories c
LEFT JOIN products p ON c.category_id = p.category_id
GROUP BY c.name
ORDER BY num_products DESC;
```

> [!NOTE]
> ***Error(s) Identified***
>
> No errors, the query is valid. It lists every category with the number of products in it, with the categories that have the most products first. The LEFT JOIN keeps categories that have no products, and because COUNT(p.product_id) ignores NULLs, those categories show 0 instead of 1. One row per category, two columns: name and num_products.
>
> [!NOTE]
> ***Corrected SQL***
>
> ```sql
> -- No correction needed
> SELECT c.name, COUNT(p.product_id) AS num_products
> FROM categories c
> LEFT JOIN products p ON c.category_id = p.category_id
> GROUP BY c.name
> ORDER BY num_products DESC;
> ```


### 4.2

```sql
SELECT first_name, last_name
FROM customers
WHERE customer_id NOT IN (
    SELECT DISTINCT customer_id FROM orders
);
```

> [!NOTE]
> ***Error(s) Identified***
>
> No errors, the query is valid. It returns the first and last name of every customer who has never placed an order: the subquery lists all customer IDs that appear in orders, and NOT IN keeps the customers whose ID is not in that list. A small risk is that NOT IN returns no rows at all if the subquery ever contains a NULL. That can't happen here because orders.customer_id is NOT NULL, but the LEFT JOIN + IS NULL version is safer.
>
> [!NOTE]
> ***Corrected SQL***
>
> ```sql
> -- No correction needed. Safer equivalent using the anti-join pattern:
> SELECT c.first_name, c.last_name
> FROM customers c
> LEFT JOIN orders o ON o.customer_id = c.customer_id
> WHERE o.order_id IS NULL;
> ```


### 4.3

```sql
SELECT p.name, p.price, p.stock,
       p.price * p.stock AS inventory_value
FROM products p
WHERE p.stock > 0
ORDER BY inventory_value DESC
LIMIT 3;
```

> [!NOTE]
> ***Error(s) Identified***
>
> No errors, the query is valid. It ignores out-of-stock products, calculates the inventory value (price × stock) for each remaining product, and returns the 3 products with the highest value, with their name, price, stock and inventory_value. Using the alias inventory_value in ORDER BY is allowed because ORDER BY runs after SELECT.
>
> [!NOTE]
> ***Corrected SQL***
>
> ```sql
> -- No correction needed
> SELECT p.name, p.price, p.stock,
>        p.price * p.stock AS inventory_value
> FROM products p
> WHERE p.stock > 0
> ORDER BY inventory_value DESC
> LIMIT 3;
> ```


### 4.4

```sql
SELECT o.order_id,
       SUM(oi.quantity * oi.unit_price) AS order_total
FROM orders o
INNER JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status <> 'cancelled'
GROUP BY o.order_id
HAVING SUM(oi.quantity * oi.unit_price) > 200
ORDER BY order_total DESC;
```

> [!NOTE]
> ***Error(s) Identified***
>
> No errors, the query is valid. It calculates the total of each order that is not cancelled (WHERE removes cancelled orders before grouping), keeps only orders whose total is above €200 (HAVING filters the groups), and shows them with the biggest order first. The result has two columns: order_id and order_total.
>
> [!NOTE]
> ***Corrected SQL***
>
> ```sql
> -- No correction needed
> SELECT o.order_id,
>        SUM(oi.quantity * oi.unit_price) AS order_total
> FROM orders o
> INNER JOIN order_items oi ON o.order_id = oi.order_id
> WHERE o.status <> 'cancelled'
> GROUP BY o.order_id
> HAVING SUM(oi.quantity * oi.unit_price) > 200
> ORDER BY order_total DESC;
> ```


### 4.5

```sql
SELECT c.first_name || ' ' || c.last_name AS customer,
       COUNT(DISTINCT o.order_id) AS num_orders,
       SUM(oi.quantity) AS total_items,
       ROUND(SUM(oi.quantity * oi.unit_price), 2) AS total_spent
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC NULLS LAST;
```

> [!NOTE]
> ***Error(s) Identified***
>
> No errors, the query is valid. It gives one row per customer with their full name, number of orders, total items bought and total money spent (rounded to 2 decimals), with the biggest spenders first. Customers who never ordered still appear thanks to the LEFT JOINs, with 0 orders and NULL for items and spent, and NULLS LAST puts them at the bottom. COUNT(DISTINCT o.order_id) is needed so an order isn't counted once for every item it contains.
>
> [!NOTE]
> ***Corrected SQL***
>
> ```sql
> -- No correction needed
> SELECT c.first_name || ' ' || c.last_name AS customer,
>        COUNT(DISTINCT o.order_id) AS num_orders,
>        SUM(oi.quantity) AS total_items,
>        ROUND(SUM(oi.quantity * oi.unit_price), 2) AS total_spent
> FROM customers c
> LEFT JOIN orders o ON c.customer_id = o.customer_id
> LEFT JOIN order_items oi ON o.order_id = oi.order_id
> GROUP BY c.customer_id, c.first_name, c.last_name
> ORDER BY total_spent DESC NULLS LAST;
> ```


---

## Submission Checklist

- [ ] All 15 business questions answered with working SQL
- [ ] Theory review questions answered in your own words
- [ ] All 15 query writing exercises completed
- [ ] All 5 query reading explanations written
- [ ] Results verified by running queries against your TrailShop database