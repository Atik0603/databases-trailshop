# Week 39 — Logical Database Design: Exercises

> [!IMPORTANT]
> ***How to Complete These Exercises***
> Write your answers directly in the highlighted **Your Answer** / **Your SQL** fields below each task. Replace the placeholder text with your own work before submitting.

These exercises accompany the Week 39 Theory material. Refer to the theory sections indicated in brackets when you need help.

---

## Exercise 1: TrailShop Project Task — Build the Schema

**Goal:** Convert the TrailShop ER diagram (from Week 38) into a complete PostgreSQL relational schema.

### Instructions

Write `CREATE TABLE` statements for all five TrailShop tables:

1. `categories`
2. `customers`
3. `products`
4. `orders`
5. `order_items`

### Requirements

For each table, you must:

- Choose appropriate PostgreSQL data types for every column (justify at least 3 choices in writing)
- Define primary keys (surrogate or composite as appropriate)
- Define foreign keys with explicit `ON DELETE` and `ON UPDATE` actions (justify each choice)
- Add `NOT NULL`, `UNIQUE`, `CHECK`, and `DEFAULT` constraints where appropriate
- Create tables in the correct dependency order
- Follow the naming conventions from Theory Section 8

### Deliverables

1. A single `.sql` file with all five `CREATE TABLE` statements (executable in PostgreSQL)
2. A short written document (1–2 pages) containing:
   - Justification for 3 data type choices (e.g., why `NUMERIC(10,2)` for price instead of `REAL`)
   - Justification for each FK action choice (e.g., why CASCADE on `order_items.order_id`)
   - One design decision you made that wasn't specified in the requirements (e.g., whether shipping address is optional)

### Bonus Challenge

After creating the tables, insert sample data:
- At least 5 categories
- At least 8 products (across at least 3 categories)
- At least 3 customers
- At least 4 orders (across at least 2 customers)
- At least 10 order items

Verify that your constraints work by attempting at least 2 invalid inserts and showing the error messages.

> [!NOTE]
> ***Your SQL***
>
> ```sql
> -- Paste key CREATE TABLE statements or link to your .sql file contents here
>
>
https://github.com/Atik0603/databases-trailshop/blob/main/Week39-LogicalDatabaseDesign/trailshop_schema.sql
>
> ```

> [!NOTE]
> ***Your Answer***
>
> *(Paste written justifications for data types, FK actions, and design decisions here.)*
>

***Data type choices:***

>price NUMERIC(10,2) instead of REAL/DOUBLE PRECISION — floating-point types store an approximation, so 0.1 + 0.2 can come back as 0.30000001192092896. Money must be exact and NUMERIC guarantees that.


>email VARCHAR(254) rather than plain TEXT — RFC 5321 caps email addresses at 254 characters, so the limit documents an actual constraint of the data rather than being arbitrary.


>registered_at/order_date/created_at as TIMESTAMPTZ instead of TIMESTAMP — TrailShop customers may be anywhere, and TIMESTAMPTZ stores in UTC and converts per session, avoiding silent timezone bugs that plain TIMESTAMP would cause.

***FK action choices:***

>products.category_id → categories: ON DELETE RESTRICT — a category with active products shouldn't be deletable by accident; someone must first reassign or remove those products. ON UPDATE CASCADE — if a category's surrogate ID ever changed, products should follow it automatically rather than orphan.


>orders.customer_id → customers: ON DELETE RESTRICT — deleting a customer with order history would silently erase business records; a soft-delete flag would be the safer real-world approach instead of hard delete.


>order_items.order_id → orders: ON DELETE CASCADE — order_items is a weak entity; a line item has no independent meaning once its parent order is gone.


>order_items.product_id → products: ON DELETE RESTRICT — a product that has been ordered before must not be deletable, or historical order records would reference a nonexistent product.


***Design decision:*** 
>I made the orders shipping address columns (shipping_street, etc.) nullable and separate from the customer's own address, rather than always reusing customers.street/city/.... This allows a customer to ship to a different address than their registered one (e.g. gift orders), while still defaulting to their own address at the application level when left blank.

>
>
>

## Exercise 2: Theory Review Questions

Answer each question in 2–4 sentences. Reference the relevant theory section.

1. List the seven phases of the database development lifecycle in order. Which phase is this week's focus? *(Section 1)*

> [!NOTE]
> ***Your Answer***
>
> *(Write your answer here.)*
>The seven phases: Requirements Gathering → Conceptual Design → Logical Design → Physical Design → Implementation → Testing & Validation → Maintenance & Evolution. This week's focus is Logical Design, transforming the ER model into a relational schema with data types and constraints.
>
>
>

2. Explain the transformation rule for mapping a 1:N relationship to the relational model. Why is the foreign key placed on the "many" side? *(Section 3.2)*

> [!NOTE]
> ***Your Answer***
>
> *(Write your answer here.)*
>The rule: place the primary key of the "one" side as a foreign key column on the "many" side table. It goes there because each row on the many side relates to exactly one row on the one side, so a single FK column can hold that reference; putting it on the one side would require storing multiple values in one cell, which breaks atomicity
>
>
>

3. What is a junction table? When is it needed? Give an example not from TrailShop. *(Section 3.3)*

> [!NOTE]
> ***Your Answer***
>
> *(Write your answer here.)*
>A junction table resolves a many-to-many relationship by holding foreign keys to both participating tables, since a single FK column can't represent "many-to-many" directly. Example outside TrailShop: a students table and a courses table connected by an enrollments junction table, since one student takes many courses and one course has many students.
>
>
>

4. When mapping a 1:1 relationship, how do you decide which table gets the foreign key? *(Section 3.4)*

> [!NOTE]
> ***Your Answer***
>
> *(Write your answer here.)*
>WE look at participation: if one side is mandatory and the other optional, put the FK on the mandatory side (it's guaranteed to have a value). If both sides are mandatory, either works. We pick whichever makes queries more natural. If both are optional, we put the FK on whichever side is more likely to actually have the value, and allow NULL.
>
>
>

5. How does the mapping of a weak entity differ from a strong entity? What happens to the primary key? *(Section 3.5)*

> [!NOTE]
> ***Your Answer***
>
> *(Write your answer here.)*
>A weak entity's table includes the owning entity's primary key as both a foreign key and part of its own composite primary key — it has no independent identity apart from its owner. A strong entity gets its own independent primary key that doesn't need to incorporate another table's key.
>
>
>

6. Why should you never use `REAL` or `DOUBLE PRECISION` for monetary values? What should you use instead? *(Section 4.1)*

> [!NOTE]
> ***Your Answer***
>
> *(Write your answer here.)*
>REAL/DOUBLE PRECISION store approximate binary floating-point values, so arithmetic on them can produce tiny rounding errors (e.g. 0.1 + 0.2 ≠ exactly 0.3), which is unacceptable for money. NUMERIC(p,s) stores exact decimal values instead, guaranteeing the precision matches what was entered.
>
>
>

7. What is the difference between `TIMESTAMP` and `TIMESTAMPTZ`? Which should you prefer and why? *(Section 4.3)*
> [!NOTE]
> ***Your Answer***
>
> *(Write your answer here.)*
>TIMESTAMP stores a date/time with no timezone information, so its meaning depends on an assumption about which zone it represents. TIMESTAMPTZ stores the value converted to UTC internally and displays it converted to the session's timezone. We should prefer it because it avoids ambiguity and bugs when users or servers are in different timezones.




8. Explain the difference between `CASCADE` and `RESTRICT` as foreign key delete actions. Give a scenario where each is appropriate. *(Section 6)*
> [!NOTE]
> ***Your Answer***
>
> *(Write your answer here.)*
>CASCADE automatically propagates the delete to child rows; RESTRICT blocks the delete entirely if child rows exist. CASCADE is appropriate for order_items when its orders parent is deleted (line items are meaningless without the order). RESTRICT is appropriate for categories when products still reference it becasue we don't want product data silently destroyed.




9. What is an insertion anomaly? Give an example and explain how proper schema design prevents it. *(Section 7)*
> [!NOTE]
> ***Your Answer***
>
> *(Write your answer here.)*
>In insertion anomaly is when we can't add one piece of data without also being forced to add unrelated data.
>Example: if category and product data are merged into a single table, we can't add a new category ("Cycling") until a product exists in it — the category has no independent row. Proper schema design prevents this by giving categories their own table, decoupled from whether any products currently belong to it.




10. What is the difference between a surrogate key and a natural key? Give one advantage of each. *(Section 9)*
> [!NOTE]
> ***Your Answer***
>
> *(Write your answer here.)*
>A surrogate key is artificial and has no real-world meaning (e.g. an auto-incrementing SERIAL); a natural key is drawn from real business data (e.g. an ISBN or email). Advantage of surrogate: it never changes and is compact/fast for joins. Advantage of natural: it's already meaningful and doesn't require inventing an extra identifier when a stable real-world one already exists.




11. Why does PostgreSQL fold unquoted identifiers to lowercase? How does `snake_case` naming help? *(Section 8)*

> [!NOTE]
> ***Your Answer***
>
> *(Write your answer here.)*
>PostgreSQL folds unquoted identifiers to lowercase for consistency, since SQL identifiers are technically case-insensitive unless quoted — without folding, Products and products could be treated inconsistently across statements. snake_case sidesteps the whole issue because it's naturally lowercase already, so what we type is exactly what PostgreSQL stores, with no need for quoting.
>
>
>

12. What does `SET NULL` do as a foreign key action? When would you use it instead of `CASCADE`? *(Section 6)*
> [!NOTE]
> ***Your Answer***
>
> *(Write your answer here.)*
>SET NULL sets the foreign key column to NULL in child rows when the referenced parent row is deleted, leaving the child row intact but unlinked. We'd use it instead of CASCADE when the child record should survive independently of its parent — e.g. deleting a manager shouldn't delete their direct reports, just clear their manager_id




---

## Exercise 3: Transformation Exercise — Hotel Booking System

### Given ER Diagram

A hotel booking system has the following entities and relationships:

**Entities:**

1. **Hotel** — hotel_id (PK), name, city, star_rating, phone
2. **Room** (weak entity, owned by Hotel) — room_number (partial key), room_type, floor, price_per_night, has_balcony
3. **Guest** — guest_id (PK), first_name, last_name, email, phone, passport_number
4. **Booking** — booking_id (PK), check_in_date, check_out_date, total_amount, status
5. **Service** — service_id (PK), name, description, price (e.g., "Room Service", "Spa", "Airport Shuttle")

**Relationships:**

- Hotel (1) → Room (N): A hotel has many rooms. Each room belongs to exactly one hotel. (Identifying relationship — Room is weak.)
- Guest (1) → Booking (N): A guest can make many bookings. Each booking belongs to one guest.
- Booking (M) ↔ Room (N): A booking can include multiple rooms, and a room can appear in many bookings (over time). The junction records the specific dates.
- Booking (M) ↔ Service (N): A booking can use multiple services, and a service can be used by many bookings. The junction records the date used and quantity.

### Task

1. Write `CREATE TABLE` statements for ALL tables (including junction tables).
2. For each table:
   - Choose appropriate data types
   - Define PK, FK, NOT NULL, UNIQUE, CHECK, and DEFAULT constraints
   - Specify ON DELETE and ON UPDATE actions for all FKs
3. Create the tables in the correct dependency order.
4. Explain why Room is a weak entity and how its PK reflects this.

> [!NOTE]
> ***Your SQL***
>
```sql
CREATE TABLE hotels (
    hotel_id    SERIAL       PRIMARY KEY,
    name        VARCHAR(150) NOT NULL,
    city        VARCHAR(100) NOT NULL,
    star_rating SMALLINT     NOT NULL CHECK (star_rating BETWEEN 1 AND 5),
    phone       VARCHAR(20)
);

CREATE TABLE rooms (
    hotel_id       INTEGER       NOT NULL
                   REFERENCES hotels(hotel_id)
                   ON DELETE CASCADE
                   ON UPDATE CASCADE,
    room_number    VARCHAR(10)   NOT NULL,
    room_type      VARCHAR(50)   NOT NULL,
    floor          SMALLINT,
    price_per_night NUMERIC(10,2) NOT NULL CHECK (price_per_night > 0),
    has_balcony    BOOLEAN       NOT NULL DEFAULT FALSE,
    PRIMARY KEY (hotel_id, room_number)
);

CREATE TABLE guests (
    guest_id        SERIAL       PRIMARY KEY,
    first_name      VARCHAR(50)  NOT NULL,
    last_name       VARCHAR(50)  NOT NULL,
    email           VARCHAR(254) NOT NULL UNIQUE,
    phone           VARCHAR(20),
    passport_number VARCHAR(20)  NOT NULL UNIQUE
);

CREATE TABLE bookings (
    booking_id     SERIAL        PRIMARY KEY,
    guest_id       INTEGER       NOT NULL
                   REFERENCES guests(guest_id)
                   ON DELETE RESTRICT
                   ON UPDATE CASCADE,
    check_in_date  DATE          NOT NULL,
    check_out_date DATE          NOT NULL,
    total_amount   NUMERIC(10,2) NOT NULL CHECK (total_amount >= 0),
    status         VARCHAR(20)   NOT NULL DEFAULT 'confirmed'
                   CHECK (status IN ('confirmed', 'checked_in', 'checked_out', 'cancelled')),
    CHECK (check_out_date > check_in_date)
);

CREATE TABLE services (
    service_id  SERIAL        PRIMARY KEY,
    name        VARCHAR(100)  NOT NULL UNIQUE,
    description TEXT,
    price       NUMERIC(10,2) NOT NULL CHECK (price >= 0)
);

-- Junction: Booking (M) <-> Room (N)
CREATE TABLE booking_rooms (
    booking_id  INTEGER     NOT NULL
                REFERENCES bookings(booking_id)
                ON DELETE CASCADE
                ON UPDATE CASCADE,
    hotel_id    INTEGER     NOT NULL,
    room_number VARCHAR(10) NOT NULL,
    FOREIGN KEY (hotel_id, room_number)
        REFERENCES rooms(hotel_id, room_number)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    PRIMARY KEY (booking_id, hotel_id, room_number)
);

-- Junction: Booking (M) <-> Service (N)
CREATE TABLE booking_services (
    booking_id  INTEGER  NOT NULL
                REFERENCES bookings(booking_id)
                ON DELETE CASCADE
                ON UPDATE CASCADE,
    service_id  INTEGER  NOT NULL
                REFERENCES services(service_id)
                ON DELETE RESTRICT
                ON UPDATE CASCADE,
    date_used   DATE     NOT NULL,
    quantity    INTEGER  NOT NULL DEFAULT 1 CHECK (quantity > 0),
    PRIMARY KEY (booking_id, service_id, date_used)
);

```

> [!NOTE]
> ***Your Answer***
>
> *(Explain why Room is a weak entity and how its PK reflects this.)*
>
> 
>A room's identifying attribute — room_number — is only a partial key; room numbers repeat across different hotels (every hotel might have a "Room 101"). A room has no independent existence or unique identity without knowing which hotel it belongs to. This is reflected in its PK: PRIMARY KEY (hotel_id, room_number) — the owning hotel's key is folded into the room's own primary key, and hotel_id is both a FK to hotels and part of that composite PK, exactly per the weak-entity mapping rule.
>
>
>

---

## Exercise 4: Data Type Selection

> [!NOTE]
> ***Your Answers***
> Fill in the **Your Data Type** and **Justification** columns in the table below.



For each column described below, choose the best PostgreSQL data type and write a brief justification (1–2 sentences). Do NOT just pick `VARCHAR` or `TEXT` for everything — think carefully about validation, storage, and query needs.

| # | Column Description | Your Data Type | Justification |
|---|---|---|---|
| 1 | Employee salary (exact, up to €999,999.99) | `NUMERIC(9,2)` | Exact decimal for money; 9 digits covers up to 9,999,999.99, comfortably above the stated range |
| 2 | Number of items in stock (never negative, max ~50,000) | `INTEGER` | `SMALLINT` tops out at 32,767, too small; `INTEGER` comfortably covers it with room to grow |
| 3 | Whether a user's email is verified | `BOOLEAN` | Simple two-state (plus NULL) flag, self-documenting |
| 4 | Customer's date of birth | `DATE` | No time component needed, and `DATE` is smaller/faster than a timestamp |
| 5 | Product description (variable length, could be several paragraphs) | `TEXT` | No practical length cap needed; `TEXT` and unlimited `VARCHAR` perform identically in PostgreSQL |
| 6 | Country code (always exactly 2 letters, like "FI", "US") | `CHAR(2)` | Fixed-length code — `CHAR(n)` fits naturally and signals the exact expected width |
| 7 | IP address of a login attempt | `INET` | Built-in validation and supports network-specific operations, unlike plain text |
| 8 | Order total (exact, up to €9,999,999.99) | `NUMERIC(10,2)` | Exact decimal; 10 digits covers the stated range |
| 9 | GPS latitude of a store location | `DOUBLE PRECISION` | Coordinates need high decimal precision but not exactness to the cent — standard practice for geo data |
| 10 | A unique identifier for API tokens that must be globally unique across distributed systems | `UUID` | Designed for distributed uniqueness without coordination between systems, unlike a sequential integer |
| 11 | Duration of a video in seconds (always a whole number) | `INTEGER` | Whole number, no need for SERIAL/auto-increment or decimals |
| 12 | Timestamp of when a record was last modified (users in multiple time zones) | `TIMESTAMPTZ` | Timezone-aware, avoids ambiguity across users in different zones |
| 13 | A Finnish phone number like "+358 40 123 4567" | `VARCHAR(20)` | Contains `+`, spaces, and digits — never store phone numbers as a numeric type |
| 14 | A percentage discount (0.00% to 100.00%) | `NUMERIC(5,2)` | Exact decimal with 2 fractional digits, enough range for 0.00–100.00 |
| 15 | A product's color options (e.g., a product comes in "red", "blue", "green") | Separate table (e.g. `product_colors`) or `TEXT[]` if simple | A multivalued attribute violates atomicity in a single column; per Rule 6, model it as its own table (or an array if queries on individual colors are rare) |

---

## Exercise 5: Constraint Design

For each business rule below, write the appropriate PostgreSQL constraint. Provide the constraint as it would appear inside a `CREATE TABLE` statement or as an `ALTER TABLE` statement.

### Part A: Single-Column Constraints

1. "A product's weight must be greater than zero (if provided)."

2. "Every customer must have an email address."

3. "Product names must be unique."

4. "An employee's hire date defaults to today if not specified."

5. "Order status can only be one of: 'new', 'confirmed', 'shipped', 'delivered', 'returned'."

> [!NOTE]
> ***Your SQL***
>
 ```sql
> -- Write constraints 1–5 here
-- 1
weight NUMERIC(8,2) CHECK (weight > 0)

-- 2
email VARCHAR(254) NOT NULL

-- 3
name VARCHAR(100) NOT NULL UNIQUE

-- 4
hire_date DATE NOT NULL DEFAULT CURRENT_DATE

-- 5
status VARCHAR(20) NOT NULL
    CHECK (status IN ('new', 'confirmed', 'shipped', 'delivered', 'returned'))
>
```

### Part B: Multi-Column Constraints

6. "A flight's arrival time must be after its departure time."

7. "In the `enrollments` table, the combination of `student_id` and `course_id` must be unique (a student can only enroll in a course once)."

8. "A discount percentage must be between 0 and 100, inclusive."

> [!NOTE]
> ***Your SQL***
>
```sql
-- 6
CHECK (arrival_time > departure_time)

-- 7
UNIQUE (student_id, course_id)

-- 8
CHECK (discount_percent >= 0 AND discount_percent <= 100)


```

### Part C: Foreign Key Constraints with Actions

9. "When a department is deleted, all employees in that department should have their `department_id` set to NULL (they become unassigned)."

10. "When a customer is deleted, prevent the deletion if the customer has any orders."

11. "When an author is deleted, all their blog posts should be deleted automatically."

12. "When a course is deleted, all enrollments for that course should be removed."

> [!NOTE]
> ***Your SQL***
>
 ```sql
-- 9
department_id INTEGER REFERENCES departments(department_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE

-- 10
customer_id INTEGER NOT NULL REFERENCES customers(customer_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE

-- 11
author_id INTEGER NOT NULL REFERENCES authors(author_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE

-- 12
course_id INTEGER NOT NULL REFERENCES courses(course_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
>
>
```

---

## Submission Checklist

- [ ] Exercise 1: `.sql` file with all CREATE TABLE statements + written justifications
- [ ] Exercise 2: All 12 theory review answers
- [ ] Exercise 3: Hotel booking schema with all tables and explanations
- [ ] Exercise 4: Data type selections with justifications for all 15 columns
- [ ] Exercise 5: All 12 constraints written in valid PostgreSQL syntax
