# Week 40 — Exercises: SQL Fundamentals

> [!IMPORTANT]
> ***How to Complete These Exercises***
> Write your answers directly in the highlighted **Your Answer** / **Your SQL** fields below each task. Replace the placeholder text with your own work before submitting.

## Exercise 1: TrailShop Project Task

This week you'll build the TrailShop database from scratch and practice manipulating data.

### Task 1.1: Create the Database

1. Open your PostgreSQL terminal (psql) or pgAdmin
2. Create a new database called `trailshop`
3. Connect to it

### Task 1.2: Create All Tables

Write and execute the CREATE TABLE statements for all five TrailShop tables in the correct order:
- categories
- customers
- products
- orders
- order_items

**Requirements:**
- Use appropriate data types for each column
- Include all constraints from the theory (NOT NULL, UNIQUE, CHECK, FOREIGN KEY, DEFAULT)
- Use SERIAL for primary keys
- Ensure foreign keys reference the correct parent tables

**Verify** by running `\dt` in psql to list all tables.

> [!NOTE]
> ***Your SQL***
>
```sql
CREATE TABLE categories (
    category_id  SERIAL PRIMARY KEY,
    name         VARCHAR(100) NOT NULL UNIQUE,
    description  TEXT
);

CREATE TABLE customers (
    customer_id  SERIAL PRIMARY KEY,
    first_name   VARCHAR(100) NOT NULL,
    last_name    VARCHAR(100) NOT NULL,
    email        VARCHAR(255) NOT NULL UNIQUE,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE products (
    product_id   SERIAL PRIMARY KEY,
    name         VARCHAR(200) NOT NULL,
    description  TEXT,
    price        NUMERIC(10,2) NOT NULL CHECK (price > 0),
    stock        INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
    category_id  INTEGER NOT NULL REFERENCES categories(category_id),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE orders (
    order_id     SERIAL PRIMARY KEY,
    customer_id  INTEGER NOT NULL REFERENCES customers(customer_id),
    order_date   TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status       VARCHAR(20) NOT NULL DEFAULT 'pending'
                 CHECK (status IN ('pending', 'shipped', 'delivered', 'cancelled'))
);

CREATE TABLE order_items (
    order_item_id  SERIAL PRIMARY KEY,
    order_id       INTEGER NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id     INTEGER NOT NULL REFERENCES products(product_id),
    quantity       INTEGER NOT NULL CHECK (quantity > 0),
    unit_price     NUMERIC(10,2) NOT NULL CHECK (unit_price > 0)
);
>
>
```


### Task 1.3: Insert Sample Data

Insert the following data:

**Categories** (at least 5):
- Footwear, Backpacks, Tents, Clothing, Accessories

> [!NOTE]
> ***Your SQL***
>
 ```sql
INSERT INTO categories (name, description) VALUES
    ('Footwear', 'Hiking boots, trail runners, and sandals'),
    ('Backpacks', 'Day packs, overnight packs, and expedition packs'),
    ('Tents', 'One-person to family-size tents'),
    ('Clothing', 'Outdoor clothing for all seasons'),
    ('Accessories', 'Water bottles, headlamps, trekking poles');
 ```

**Customers** (at least 5):
- Use easy to write names with realistic email addresses

> [!NOTE]
> ***Your SQL***
>
 ```sql
INSERT INTO customers (first_name, last_name, email) VALUES
    ('Anna', 'Virtanen', 'anna.v@email.com'),
    ('Mikko', 'Korhonen', 'mikko.k@email.com'),
    ('Sara', 'Makinen', 'sara.m@email.com'),
    ('Juha', 'Nieminen', 'juha.n@email.com'),
    ('Laura', 'Hamalainen', 'laura.h@email.com');
```

**Products** (at least 10):
- At least 2 products per category
- Prices ranging from €20 to €500
- Various stock levels

> [!NOTE]
> ***Your SQL***
>
```sql
INSERT INTO products (name, description, price, stock, category_id) VALUES
    ('TrailMaster X4', 'Hiking boot with Gore-Tex lining', 149.99, 25, 1),
    ('LiteStep Pro', 'Lightweight trail runner', 89.99, 40, 1),
    ('Summit 45L', 'Multi-day hiking backpack', 199.99, 15, 2),
    ('DayTripper 20L', 'Compact day pack', 59.99, 50, 2),
    ('CloudNest 2P', 'Two-person ultralight tent', 349.99, 10, 3),
    ('StormShield 4P', 'Four-season family tent', 499.99, 5, 3),
    ('ThermoLayer Jacket', 'Insulated mid-layer', 129.99, 30, 4),
    ('RainGuard Pro', 'Waterproof rain jacket', 179.99, 20, 4),
    ('HydroFlask 1L', 'Insulated water bottle', 34.99, 100, 5),
    ('LumaBeam 800', 'Rechargeable headlamp', 44.99, 60, 5);

```

**Orders** (at least 5):
- Different customers, different statuses

> [!NOTE]
> ***Your SQL***
>
 ```sql
NSERT INTO orders (customer_id, status) VALUES
    (1, 'delivered'),
    (2, 'shipped'),
    (1, 'pending'),
    (3, 'delivered'),
    (4, 'pending');
 ```

**Order Items** (at least 10):
- Multiple items in some orders, single items in others

> [!NOTE]
> ***Your SQL***
>
 ```sql
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
    (1, 1, 1, 149.99), (1, 9, 2, 34.99),
    (2, 3, 1, 199.99), (2, 7, 1, 129.99),
    (3, 5, 1, 349.99),
    (4, 2, 1, 89.99), (4, 4, 1, 59.99), (4, 10, 1, 44.99),
    (5, 6, 1, 499.99), (5, 8, 1, 179.99);
```

**Verify** each insert with `SELECT * FROM table_name;`

### Task 1.4: Practice UPDATE

Perform the following updates and verify each one:

1. Increase the price of all products in the Footwear category by 10%
2. Change customer #3's email to a new address
3. Update the status of order #2 from 'shipped' to 'delivered'
4. Set the stock of 'HydroFlask 1L' to 85
5. Add a description to any product that currently has NULL in description

> [!NOTE]
> ***Your SQL***
>
```sql
UPDATE products SET price = price * 1.10 WHERE category_id = 1;
UPDATE customers SET email = 'sara.new@email.com' WHERE customer_id = 3;
UPDATE orders SET status = 'delivered' WHERE order_id = 2;
UPDATE products SET stock = 85 WHERE name = 'HydroFlask 1L';
UPDATE products SET description = 'No description available yet.' WHERE description IS NULL;
```


### Task 1.5: Practice DELETE

1. Delete the most recently created order (and observe what happens to its order_items if you used CASCADE)
2. Try to delete a category that has products — what error do you get?

> [!NOTE]
> ***Your Answer***
>
>Its order_items rows are deleted automatically, because order_items.order_id has ON DELETE CASCADE.
>
>ERROR: update or delete on table "categories" violates foreign key constraint "products_category_id_fkey" on table "products", with the detail Key (category_id)=(1) is still referenced from table "products". It fails because the FK has no ON DELETE action, so the default is NO ACTION (blocked).
>

3. Delete a customer who has no orders

### Task 1.6: Practice ALTER TABLE

1. Add a column `phone VARCHAR(20)` to the customers table
2. Add a column `weight_grams INTEGER` to the products table
3. Add a CHECK constraint to ensure `weight_grams > 0` (allow NULL though — not all products have weight recorded yet)
4. Rename the `stock` column in products to `quantity_in_stock`

> [!NOTE]
> ***Your SQL***
>
 ```sql
ALTER TABLE customers ADD COLUMN phone VARCHAR(20);
ALTER TABLE products ADD COLUMN weight_grams INTEGER;
ALTER TABLE products ADD CONSTRAINT chk_products_weight CHECK (weight_grams > 0);
ALTER TABLE products RENAME COLUMN stock TO quantity_in_stock;
```


---

## Exercise 2: Theory Review Questions

Answer the following questions in your own words using the answer fields below:

1. What does SQL stand for, and why was the language designed to look like English?

> [!NOTE]
> ***Your Answer***
>
>SQL stands for Structured Query Language (originally SEQUEL, Structured English Query Language). It was made to read like English so non-programmers could query databases.>
>
>
>

2. Explain the difference between DDL and DML. Give two example commands for each.

> [!NOTE]
> ***Your Answer***
>
>DDL defines structure (CREATE TABLE, ALTER TABLE). DML works with the data inside tables (INSERT, UPDATE).
>
>
>

3. What is the difference between DCL and TCL? When would you use each?

> [!NOTE]
> ***Your Answer***
>
>DCL manages permissions (GRANT, REVOKE), used when setting up who can access what. TCL manages transactions (BEGIN, COMMIT, ROLLBACK), used when several >statements must succeed or fail together, like a money transfer.
>
>
>

4. Why must you create tables in a specific order? What determines that order?

> [!NOTE]
> ***Your Answer***
>
> A foreign key needs the referenced table to already exist. The FK dependencies decide the order, so categories comes before products and orders before >order_items.
>
>
>
>

5. What is the difference between a column-level constraint and a table-level constraint? When *must* you use a table-level constraint?

> [!NOTE]
> ***Your Answer***
>
>A column-level constraint sits right after one column and applies only to it. A table-level constraint is declared after all columns and can span several. We >must use table-level for composite primary keys, composite foreign keys, and CHECKs across multiple columns.>
>
>
>

6. Explain the difference between `DELETE FROM products;` and `TRUNCATE TABLE products;`. When would you prefer each?

> [!NOTE]
> ***Your Answer***
>
>DELETE FROM products; removes rows one by one, can take a WHERE, fires triggers, and can be rolled back. TRUNCATE empties the whole table quickly, takes no >WHERE, and skips row triggers (RESTART IDENTITY resets the serial). Use DELETE for specific rows or when triggers matter, and TRUNCATE to quickly reset test data.
>
>
>

7. What does `ON DELETE CASCADE` do on a foreign key? Give a real-world scenario where it's appropriate and one where it would be dangerous.

> [!NOTE]
> ***Your Answer***
>
>ON DELETE CASCADE deletes child rows when the parent is deleted. It suits deleting an order, since its items mean nothing without it. It is dangerous on >products.category_id, where deleting a category would silently wipe all its products.
>
>
>

8. Why should you store `unit_price` in the `order_items` table instead of just looking it up from the `products` table?

> [!NOTE]
> ***Your Answer***
>
>unit_price preserves the price actually paid. If we looked it up from products, every past order's total would change whenever a price changed.
>
>
>

9. What is the difference between SERIAL and GENERATED ALWAYS AS IDENTITY? Which would you use in a new project and why?

> [!NOTE]
> ***Your Answer***
>
>SERIAL is PostgreSQL-specific shorthand over a sequence, and manual inserts can override it. GENERATED ALWAYS AS IDENTITY is the SQL standard and blocks> >accidental overrides. For a new project using IDENTITY is safer and portable.

10. Explain why `UPDATE products SET price = 9.99;` is dangerous. What steps should you take before running any UPDATE statement?

> [!NOTE]
> ***Your Answer***
>
>With no WHERE clause, UPDATE products SET price = 9.99; overwrites every product's price. Before any UPDATE, We should write the WHERE first, run a SELECT with the same condition, and wrap it in BEGIN so we can ROLLBACK.
>
>
>
---

## Exercise 3: SQL Writing Exercises

Write the SQL statements for each task in the **Your SQL** fields below. Verify by running them when ready.

### 3.1 CREATE TABLE

Write a CREATE TABLE statement for a `suppliers` table with the following columns:
- supplier_id (auto-incrementing primary key)
- company_name (required, max 200 characters, must be unique)
- contact_name (max 150 characters)
- email (max 255 characters, required, unique)
- phone (max 20 characters)
- country (max 100 characters, required, default 'Finland')

> [!NOTE]
> ***Your SQL***
>
>```sql
>CREATE TABLE suppliers (
>    supplier_id   SERIAL PRIMARY KEY,
>    company_name  VARCHAR(200) NOT NULL UNIQUE,
>   contact_name  VARCHAR(150),
>    email         VARCHAR(255) NOT NULL UNIQUE,
>    phone         VARCHAR(20),
>    country       VARCHAR(100) NOT NULL DEFAULT 'Finland'
>);
>```

### 3.2 CREATE TABLE with Foreign Key

Write a CREATE TABLE statement for a `product_reviews` table:
- review_id (auto-incrementing primary key)
- product_id (required, references products)
- customer_id (required, references customers)
- rating (required integer, must be between 1 and 5 inclusive)
- review_text (optional, unlimited length)
- created_at (required, defaults to current timestamp)

> [!NOTE]
> ***Your SQL***
>
>```sql
>CREATE TABLE product_reviews (
>    review_id    SERIAL PRIMARY KEY,
>    product_id   INTEGER NOT NULL REFERENCES products(product_id),
>    customer_id  INTEGER NOT NULL REFERENCES customers(customer_id),
>    rating       INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
>    review_text  TEXT,
>    created_at   TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
>);
>```

### 3.3 INSERT — Single Row

Write an INSERT statement to add a new category called 'Electronics' with description 'GPS devices, solar chargers, and tech gear'.

> [!NOTE]
> ***Your SQL***
>
>```sql
>INSERT INTO categories (name, description)
>VALUES ('Electronics', 'GPS devices, solar chargers, and tech gear');
>```

### 3.4 INSERT — Multiple Rows

Write a single INSERT statement that adds three new customers:
- Eero Lahtinen, eero.l@email.com
- Maria Salminen, maria.s@email.com
- Petri Kallio, petri.k@email.com

> [!NOTE]
> ***Your SQL***
>
>```sql
>INSERT INTO customers (first_name, last_name, email) VALUES
>    ('Eero', 'Lahtinen', 'eero.l@email.com'),
>    ('Maria', 'Salminen', 'maria.s@email.com'),
>    ('Petri', 'Kallio', 'petri.k@email.com');
>```

### 3.5 INSERT with RETURNING

Write an INSERT statement that adds a new product called 'NorthStar GPS' priced at €229.99 with stock of 12 in category 'Electronics' (assume category_id = 6). Return the product_id and created_at.

> [!NOTE]
> ***Your SQL***
>
>```sql
>INSERT INTO products (name, price, stock, category_id)
>VALUES ('NorthStar GPS', 229.99, 12, 6)
>RETURNING product_id, created_at;
>```

### 3.6 UPDATE — Simple

Write an UPDATE statement that changes the email of the customer with customer_id = 2 to 'mikko.korhonen@newmail.com'.

> [!NOTE]
> ***Your SQL***
>
>```sql
>UPDATE customers SET email = 'mikko.korhonen@newmail.com' WHERE customer_id = 2;
>```

### 3.7 UPDATE — Expression

Write an UPDATE statement that reduces the stock of all products by 1 where the stock is currently greater than 0.

> [!NOTE]
> ***Your SQL***
>
> ```sql
>UPDATE products SET stock = stock - 1 WHERE stock > 0;
>```

### 3.8 UPDATE — Multiple Columns

Write an UPDATE statement that changes order #3 to status 'cancelled' and sets a (hypothetical) cancelled_at timestamp to the current time. (Assume you've already added a cancelled_at column.)

> [!NOTE]
> ***Your SQL***
>
> ```sql
>UPDATE orders SET status = 'cancelled', cancelled_at = CURRENT_TIMESTAMP WHERE order_id = 3;
>
>
> ```

### 3.9 DELETE — With Condition

Write a DELETE statement that removes all orders with status 'cancelled'.

> [!NOTE]
> ***Your SQL***
>
> ```sql
>DELETE FROM orders WHERE status = 'cancelled';
>
>
> ```

### 3.10 ALTER TABLE

Write the ALTER TABLE statements to:
a) Add a `discount_percent NUMERIC(5,2) DEFAULT 0 CHECK (discount_percent >= 0 AND discount_percent <= 100)` column to products
b) Drop the `description` column from categories
c) Add a composite unique constraint on (customer_id, product_id) in the product_reviews table (preventing a customer from reviewing the same product twice)

> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- Write your query here
>ALTER TABLE products ADD COLUMN discount_percent NUMERIC(5,2) DEFAULT 0
>    CHECK (discount_percent >= 0 AND discount_percent <= 100);
>ALTER TABLE categories DROP COLUMN description;
>ALTER TABLE product_reviews ADD CONSTRAINT uq_review_customer_product UNIQUE (customer_id, product_id);
>
> ```

---

## Exercise 4: Error Diagnosis

Each of the following SQL statements contains one or more errors. Identify the error(s) and write the corrected version.

### 4.1

```sql
CREATE TABLE warehouses
    warehouse_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    city VARCHAR(100
);
```

> [!NOTE]
> ***Error(s) Identified***
>
>Missing opening ( after the table name, and VARCHAR(100 is missing its closing )



> [!NOTE]
> ***Corrected SQL***
>
>```sq
>CREATE TABLE warehouses (warehouse_id SERIAL PRIMARY KEY, name VARCHAR(100) NOT NULL, city VARCHAR(100));
>


### 4.2

```sql
INSERT INTO products (name, price, stock, category_id)
VALUES ("Alpine Sleeping Bag", 89.99, 20, 2);
```

> [!NOTE]
> ***Error(s) Identified***
>
>Double quotes on a string value (they are for identifiers)
>
>


> [!NOTE]
> ***Corrected SQL***
>
> ```sql
> 
>VALUES ('Alpine Sleeping Bag', 89.99, 20, 2);
>
> ```


### 4.3

```sql
CREATE TABLE shipments (
    shipment_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id)
    shipped_date DATE NOT NULL,
    carrier VARCHAR(100)
);
```

> [!NOTE]
> ***Error(s) Identified***
>
> Missing comma after order_id INTEGER REFERENCES orders(order_id)
>
>
>


> [!NOTE]
> ***Corrected SQL***
>
> ```sql
>CREATE TABLE shipments (
>    shipment_id SERIAL PRIMARY KEY,
>    order_id INTEGER REFERENCES orders(order_id),
>    shipped_date DATE NOT NULL,
>    carrier VARCHAR(100)
>);
>
> ```


### 4.4

```sql
UPDATE products
SET price = price * 0.9
SET stock = stock + 10
WHERE category_id = 3;
```

> [!NOTE]
> ***Error(s) Identified***
>
>Two SET keywords, but UPDATE takes one SET with comma-separated assignments
>
>


> [!NOTE]
> ***Corrected SQL***
>
> ```sql
>UPDATE products
>SET price = price * 0.9,
>stock = stock + 10
>WHERE category_id = 3;
>
> ```


### 4.5

```sql
CREATE TABLE wishlists (
    wishlist_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
    product_id INTEGER NOT NULL REFERENCES products(product_id),
    added_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (customer_id, product_id)
);
```

> [!NOTE]
> ***Error(s) Identified***
>
>Two primary keys: wishlist_id PRIMARY KEY and the table-level PRIMARY KEY (customer_id, product_id)
>
>


> [!NOTE]
> ***Corrected SQL***
>
 ```sql
CREATE TABLE wishlists (
    wishlist_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
    product_id INTEGER NOT NULL REFERENCES products(product_id),
    added_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (customer_id, product_id)
);
```


---

## Submission Checklist

- [ ] All 5 TrailShop tables created successfully
- [ ] Sample data inserted (at least 5 categories, 5 customers, 10 products, 5 orders, 10 order items)
- [ ] UPDATE exercises completed and verified
- [ ] DELETE exercises completed and verified
- [ ] ALTER TABLE exercises completed and verified
- [ ] Theory review questions answered
- [ ] SQL writing exercises completed
- [ ] Error diagnosis completed with corrections
- [ ] All inline answer fields completed
