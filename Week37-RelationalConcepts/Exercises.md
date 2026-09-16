# Week 37 — Exercises & Project Task

> [!IMPORTANT]
> ***How to Complete These Exercises***
> Write your answers directly in the highlighted **Your Answer** / **Your SQL** fields below each task. Replace the placeholder text with your own work before submitting.

These exercises accompany the Week 37 Theory material. Complete all sections.

---

## Part 1: TrailShop Project Task

### Task 1: Identify Keys

Using the `products`, `categories`, and `customers` tables shown in Section 2 of this week's Theory material, answer:

1. What is the primary key of the `products` table? Why is it a good choice?

> [!NOTE]
> ***Your Answer***
>
product_id. It's a good choice because it's a surrogate key — stable (never changes), simple (single integer column), has no business meaning that could change, and is guaranteed unique and non-null.
>
>
>
>


2. What is the primary key of the `categories` table?

> [!NOTE]
> ***Your Answer***
>
> category_id
>
>
>
>


3. What is the foreign key in the `products` table? What does it reference?

> [!NOTE]
> ***Your Answer***
>
> category_id, referencing categories.category_id. It links each product to exactly one category (1:N relationship).
>
>
>
>


4. Is `name` in `products` a candidate key? Under what assumption? What would make it unsuitable as a primary key?


> [!NOTE]
> ***Your Answer***
>
> Only if we assume all product names are guaranteed unique (no two products ever share a name). It would be unsuitable as a PK because names can change (rebranding, typos fixed) and long text values make worse join/index keys than a small integer.
>
>
>
>
5. Give an example of a **superkey** for the `products` table that is NOT a candidate key. Explain why it's not minimal.

> [!NOTE]
> ***Your Answer***
>
> {product_id, price}. It's a superkey because product_id alone already guarantees uniqueness, but adding price is redundant — removing it doesn't break uniqueness, so the set isn't minimal.
>
>
>
>

6. Give an example of a **composite key** using a hypothetical `order_items` table. Explain why neither column alone would be sufficient.

> [!NOTE]
> ***Your Answer***
>
> (order_id, product_id). Neither column alone is sufficient. order_id repeats once per line item in the same order, and product_id repeats across different orders. Only the combination uniquely identifies "this product on this order."
>
>
>
>

7. Is `email` in `customers` a candidate key? What makes it different from `customer_id` as a PK choice? *(See Section 6.9 on natural vs surrogate keys.)*

> [!NOTE]
> ***Your Answer***
>
> Yes, assuming emails are enforced unique. Compared to customer_id: email is a natural key (real-world meaning, can change if a customer updates their address) vs customer_id which is a surrogate key (no meaning, never changes). Natural keys are riskier as PKs because updates cascade through every FK referencing them.
>
>
>
>

### Task 2: Define Business Rules

List **5 business rules** for TrailShop. For each rule, specify:
- The rule in plain English
- Which constraint type(s) would enforce it
- Which table and column the constraint applies to
- The SQL syntax for the constraint

Example:

| Business Rule | Constraint Type | Table.Column | SQL |
|---|---|---|---|
| Every product must have a price greater than zero | CHECK | products.price | `CHECK (price > 0)` |
| ... | ... | ... | ... |

Think about rules for customers, orders, and categories — not just products.

> [!NOTE]
> ***Your Answer***
>
> *(List your 5 business rules with constraint types, table/column, and SQL syntax.)*
>

| Business Rule | Constraint Type | Table.Column | SQL |

|---|---|---|---|

| Every product must have a price greater than zero | CHECK | products.price | `CHECK (price > 0)` |

| Customer emails must be unique | UNIQUE | customers.email | `email VARCHAR(255) UNIQUE` |

| Stock quantity can't go negative | CHECK | products.stock_quantity | `CHECK (stock_quantity >= 0)` |

| Order status must be one of a fixed set | CHECK | orders.status | `CHECK (status IN ('pending','shipped','delivered','cancelled'))` |

| New products start with 0 stock by default | DEFAULT | products.stock_quantity | `stock_quantity INTEGER DEFAULT 0` |
>
>
>

### Task 3: Integrity Violations

For each SQL statement below, predict whether it will **succeed** or **fail**. If it fails, explain which integrity rule or constraint is violated and what error message you'd expect. Assume the schema from Section 9.8 of the Theory material.

```sql
-- Statement A
INSERT INTO categories (category_id, category_name)
VALUES (NULL, 'Cycling');

-- Statement B
INSERT INTO products (product_id, name, price, stock_quantity, category_id)
VALUES (109, 'AeroLite Tent', 279.00, 10, 2);

-- Statement C
INSERT INTO products (product_id, name, price, stock_quantity, category_id)
VALUES (110, 'BudgetBoots', -5.00, 25, 1);

-- Statement D
INSERT INTO products (product_id, name, price, stock_quantity, category_id)
VALUES (103, 'Duplicate Shoes', 99.99, 5, 3);

-- Statement E
INSERT INTO products (product_id, name, price, stock_quantity, category_id)
VALUES (111, 'CloudWalker Sandals', 65.00, 40, 10);

-- Statement F
INSERT INTO products (product_id, name, price, stock_quantity, category_id)
VALUES (112, NULL, 89.99, 20, 1);

-- Statement G
INSERT INTO products (product_id, name, price, stock_quantity, category_id)
VALUES (113, 'LightStep Shoes', 149.00, -3, 1);

-- Statement H
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES (1001, 101, 0, 189.50);
```

> [!NOTE]
> ***Your Answer***
>
> *(For each statement A–H, write SUCCESS or FAIL and explain any violation.)*
>A — FAIL. category_id is the PK, and PKs can never be NULL (entity integrity).
> 
> B — SUCCESS. product_id 109 is new, category_id 2 exists.
> 
C — FAIL. CHECK (price > 0) rejects -5.00 (domain/behavioral constraint).

D — FAIL. product_id 103 already exists — violates the PK's uniqueness constraint.

E — FAIL. category_id 10 doesn't exist in categories — violates referential integrity (foreign key constraint).

F — FAIL. name is NOT NULL, so inserting NULL violates that constraint.

G — FAIL. CHECK (stock_quantity >= 0) rejects -3.

H — FAIL. CHECK (quantity > 0) on order_items rejects 0.
>
>
>

### Task 4: Foreign Key Actions

Consider the following scenario using the schema from Theory Section 9.8:

1. You want to delete category 2 ("Camping") from the `categories` table. Products 102 and 106 reference this category. What happens with:
   - `ON DELETE RESTRICT`? The DELETE fails outright — PostgreSQL won't let me delete category 2 while products 102/106 still reference it.

   - `ON DELETE CASCADE`?Category 2 is deleted, and products 102 and 106 are automatically deleted too.

   - `ON DELETE SET NULL`? (Assume `category_id` in `products` allows NULL for this question)Category 2 is deleted; products 102 and 106 survive but their category_id becomes NULL (uncategorized).

2. Which foreign key action would you recommend for the TrailShop `products.category_id` → `categories.category_id` relationship? Justify your choice in 2–3 sentences.

> [!NOTE]
> ***Your Answer***
>
ON DELETE RESTRICT (or leave it as default NO ACTION). Deleting a category shouldn't silently destroy or orphan real product data — an admin should be forced to explicitly reassign or remove those products first. SET NULL is a reasonable second choice if "uncategorized" is a valid business state, but CASCADE here is dangerous, deleting a category could wipe out inventory data by accident.
>
>
>




---

## Part 2: Theory Review Questions

Answer each question in 2–4 sentences unless otherwise specified. Reference the Theory material sections as needed.

### Short-Answer Questions

**Q1.** Define the following terms in your own words: relation, tuple, attribute, domain. Give one TrailShop example for each.

> [!NOTE]
> ***Your Answer***
>
Relation = a table (a set of rows sharing the same columns), e.g. products. 

Tuple = one row, e.g. (101, 'Alpine Pro Hiking Boots', 189.50, 42, 1). 

Attribute = one column, e.g. price. 

Domain = the pool of legal values for an attribute, e.g. price's domain is positive decimal numbers.
>
>
>
>

*(See Sections 2 and 3 of this week's Theory material.)*

**Q2.** What makes a candidate key different from a primary key? Can a table have more than one candidate key?


> [!NOTE]
> ***Your Answer***
>
A candidate key is any minimal unique identifier; the primary key is the one candidate key we formally choose as the table's official identifier. 

Yes — a table can have multiple candidate keys (e.g. product_id and, if unique, name), but only one becomes the PK; the rest become alternate keys.
>
>
>
>

*(See Section 6 of this week's Theory material.)*

**Q3.** Explain entity integrity in your own words. Why can't a primary key be NULL?


> [!NOTE]
> ***Your Answer***
>
Entity integrity means every row must be uniquely and reliably identifiable via its primary key. If a PK were to be NULL, we couldn't distinguish that row from any other NULL-keyed row, and no other table could reliably reference it via a foreign key, the whole referencing system breaks down.
>
>
>
>

*(See Section 8.1 of this week's Theory material.)*

**Q4.** What happens when referential integrity is violated? Give a concrete TrailShop example — show the SQL statement and the expected error.

> [!NOTE]
> ***Your Answer***
>
> Referential integrity is violated when a foreign key value doesn't match any existing primary key value in the referenced table (and isn't NULL). Example:
> 
INSERT INTO products (product_id, name, price, stock_quantity, category_id)

VALUES (111, 'CloudWalker Sandals', 65.00, 40, 10);´
>
Expected error: ERROR: insert or update on table "products" violates foreign key constraint ... DETAIL: Key (category_id)=(10) is not present in table "categories".
>
>

*(See Section 8.2 of this week's Theory material.)*

**Q5.** Explain the difference between a surrogate key and a natural key. Give an example of each for a `books` table in a library database.

> [!NOTE]
> ***Your Answer***
>
> A surrogate key is artificial and meaningless (e.g. an auto-incrementing book_id)
>
>  a natural key is drawn from real business data (e.g. isbn). For a library books table: surrogate = book_id SERIAL PRIMARY KEY
>
>  natural = isbn VARCHAR(13) UNIQUE.
>
>
>
>

*(See Section 6.8–6.9 of this week's Theory material.)*

**Q6.** What is a NULL value? Why is `WHERE price = NULL` wrong? What should you write instead?


> [!NOTE]
> ***Your Answer***
>
> NULL represents an unknown or inapplicable value. WHERE price = NULL is wrong because any comparison to NULL evaluates to UNKNOWN, not TRUE — so it never matches rows, even ones with NULL prices. we should write WHERE price IS NULL.
>
>
>
>

*(See Section 7 of this week's Theory material.)*

**Q7.** What is a junction table? When is it needed? Give an example.

> [!NOTE]
> ***Your Answer***
>
> A junction table implements a many-to-many relationship by holding pairs of foreign keys, one to each side of the relationship, usually as a composite primary key. It's needed whenever "many rows in A relate to many rows in B" — we can't model that with a single FK column. Example: product_tags(product_id, tag_id) linking products and tags.
>
>
>
>

*(See Section 12.3 of this week's Theory material.)*

**Q8.** Describe the three types of relationships (1:1, 1:N, M:N). For each, give one TrailShop example.

> [!NOTE]
> ***Your Answer***
>
> 1:1 — one row in A relates to exactly one row in B (e.g. products ↔ product_details).
> 
>1:N — one row in A relates to many rows in B (e.g. one categories row has many products). 
>
>M:N — many rows in A relate to many rows in B, via a junction table (e.g. products ↔ tags through product_tags).
>
>
>
>

*(See Section 12 of this week's Theory material.)*

**Q9.** What is the difference between `ON DELETE CASCADE` and `ON DELETE RESTRICT`? When would you use each?


> [!NOTE]
> ***Your Answer***
>
> ON DELETE CASCADE automatically deletes dependent rows when the referenced row is deleted; ON DELETE RESTRICT blocks the deletion entirely if dependents exist. Use CASCADE when child rows have no meaning without the parent (e.g. deleting an order should delete its order_items). Use RESTRICT when deletion should be a deliberate, explicit decision (e.g. don't let deleting a category silently wipe out products).
>
>
>
>

*(See Section 10 of this week's Theory material.)*

**Q10.** Explain what "atomic entries" means in the context of relation properties. Give an example of a violation.

> [!NOTE]
> ***Your Answer***
>
> Atomic entries means each cell holds a single indivisible value, not a list or nested structure. Violation example: a categories column containing "Footwear, Hiking" in one cell for a single product — that's two values crammed into one, making it impossible to query "all footwear products" without string parsing.
>
>
>
>

*(See Section 5.3 of this week's Theory material.)*

### True/False

For each statement, write **True** or **False** and correct any false statements.

1. A superkey is always a candidate key. false
2. A primary key can consist of more than one column. true
3. NULL = NULL evaluates to TRUE in SQL. False
4. A foreign key must always be NOT NULL. False
5. Referential integrity ensures that every FK value matches an existing PK value (or is NULL). True
6. The degree of a relation is the number of rows. False

### Matching Exercise

Match each term (1–12) with its definition (A–L).

| # | Term |
|---|---|
| 1 | Superkey |
| 2 | Candidate key |
| 3 | Composite key |
| 4 | Foreign key |
| 5 | Alternate key |
| 6 | Surrogate key |
| 7 | Natural key |
| 8 | Orphan record |
| 9 | Domain |
| 10 | Junction table |
| 11 | Cardinality |
| 12 | COALESCE |

| Letter | Definition |
|---|---|
| A | The set of all permitted values for an attribute |
| B | A key composed of two or more attributes |
| C | A row whose FK references a non-existent PK — forbidden by referential integrity |
| D | An artificial key with no business meaning (e.g., auto-generated ID) |
| E | A candidate key not chosen as the primary key |
| F | Any set of attributes that uniquely identifies every tuple |
| G | A minimal superkey — no attribute can be removed without losing uniqueness |
| H | A column that references the primary key of another table |
| I | The number of tuples (rows) in a relation |
| J | A key drawn from real-world data with business meaning |
| K | A table implementing a many-to-many relationship |
| L | A SQL function that returns the first non-NULL argument |


> [!NOTE]
> ***Your Answers***
>
> | # | Your Match |
> |---|---|
> | 1 |f |
> | 2 |g |
> | 3 |b |
> | 4 |h |
> | 5 |e |
> | 6 |d |
> | 7 |j |
> | 8 |c |
> | 9 |a |
> | 10 |k |
> | 11 |i |
> | 12 |l |
>

---

## Part 3: SQL Practice — Constraints in Action

These exercises test your understanding of constraints. You do NOT need to run these in PostgreSQL (but you may if you'd like to verify your answers).

### Exercise 3.1: Predict the Outcome

Given the following table definitions:

```sql
CREATE TABLE departments (
    dept_id   INTEGER      PRIMARY KEY,
    dept_name VARCHAR(50)  NOT NULL UNIQUE
);

CREATE TABLE employees (
    emp_id    INTEGER       PRIMARY KEY,
    name      VARCHAR(100)  NOT NULL,
    salary    NUMERIC(10,2) NOT NULL CHECK (salary >= 0),
    dept_id   INTEGER       NOT NULL REFERENCES departments(dept_id)
);
```

Assume these rows already exist:

```sql
INSERT INTO departments VALUES (1, 'Engineering');
INSERT INTO departments VALUES (2, 'Marketing');
INSERT INTO employees VALUES (100, 'Alice', 75000, 1);
INSERT INTO employees VALUES (101, 'Bob', 65000, 2);
```

For each statement below, predict: **SUCCESS** or **FAIL**? If fail, name the violated constraint.

```sql
-- 1
INSERT INTO employees VALUES (102, 'Carol', 70000, 1); SUCCESS

-- 2
INSERT INTO employees VALUES (103, 'Dan', -5000, 1); FAIL — CHECK (salary >= 0) violated

-- 3
INSERT INTO employees VALUES (100, 'Eve', 80000, 2); FAIL — FK violation, dept_id 5 doesn't exist FAIL — duplicate PK emp_id 100

-- 4
INSERT INTO employees VALUES (104, 'Frank', 60000, 5); FAIL — FK violation, dept_id 5 doesn't exist

-- 5
INSERT INTO departments VALUES (3, 'Engineering'); FAILS - dept_name has a UNIQUE constraint

-- 6
INSERT INTO employees VALUES (105, NULL, 55000, 2); FAIL — name is NOT NULL

-- 7
DELETE FROM departments WHERE dept_id = 1; FAIL — department 1 is referenced by employee 100 (Alice); default FK behavior is RESTRICT/NO ACTION

-- 8
INSERT INTO employees VALUES (106, 'Grace', 0, 2); SUCCESS
```

### Exercise 3.2: Write the Constraints

Given these business rules for a **bookstore database**, write the `CREATE TABLE` statements with appropriate constraints:

1. Every book has a unique ISBN (13 characters), a title (required), a price (must be positive), and a publication year.
2. Every author has an ID, a first name (required), and a last name (required).
3. A book can have multiple authors, and an author can write multiple books.
4. Every book belongs to exactly one genre. Genres have an ID and a unique name.
5. Publication year must be between 1450 and the current year.

*(Hint: you'll need at least 4 tables, including a junction table for the M:N relationship.)*

---
```sql
-- 1
CREATE TABLE genres (
    genre_id   INTEGER      PRIMARY KEY,
    genre_name VARCHAR(50)  NOT NULL UNIQUE
);
-- 2
CREATE TABLE books (
    isbn      CHAR(13)      PRIMARY KEY,
    title     VARCHAR(200)  NOT NULL,
    price     NUMERIC(10,2) NOT NULL CHECK (price > 0),
    pub_year  INTEGER       NOT NULL
              CHECK (pub_year BETWEEN 1450 AND EXTRACT(YEAR FROM CURRENT_DATE)),
    genre_id  INTEGER       NOT NULL REFERENCES genres(genre_id)
);
-- 3
CREATE TABLE authors (
    author_id  INTEGER      PRIMARY KEY,
    first_name VARCHAR(50)  NOT NULL,
    last_name  VARCHAR(50)  NOT NULL
);
-- 4
CREATE TABLE book_authors (
    isbn      CHAR(13) REFERENCES books(isbn),
    author_id INTEGER  REFERENCES authors(author_id),
    PRIMARY KEY (isbn, author_id)
);

```

## Part 4: Design Exercise — Library System

A small public library needs a database. Here is a description of their requirements:

> The library has a collection of **books**. Each book has an ISBN, a title, a publication year, and belongs to one genre (Fiction, Non-Fiction, Science, History, etc.). The library may own multiple **copies** of the same book — each copy has a unique barcode sticker.
>
> The library has registered **members**. Each member has a member number, name, email, and phone. Members can **borrow** copies. Each borrowing records which member borrowed which copy, the borrow date, the due date, and the return date (NULL if not yet returned).
>
> **Rules:**
> - A member can borrow at most 5 copies at any given time.
> - The due date is always 14 days after the borrow date.
> - A copy cannot be borrowed if it's currently not returned (return_date IS NULL).

### Your Tasks

1. **Identify the tables** you would need (list them with their columns).
2. **Identify the primary key** for each table. Are they surrogate or natural keys? Justify your choices.
3. **Identify all foreign keys** and the tables they reference.
4. **Identify any candidate keys** beyond the primary key (alternate keys).
5. **List the business rules** from the description and map each to a constraint type. Which rules cannot be enforced by simple constraints?


> [!NOTE]
> ***Your Answer***
>
1. Tables & columns

genres(genre_id, genre_name)
books(isbn, title, pub_year, genre_id)
copies(barcode, isbn)
members(member_id, name, email, phone)
borrowings(borrowing_id, member_id, barcode, borrow_date, due_date, return_date)
>
>
PKs: genre_id (surrogate), isbn (natural — real-world identifier, already unique), barcode (natural — physical sticker ID, already unique per copy), member_id (surrogate), borrowing_id (surrogate — a borrowing event has no natural identifier).
>
>
Foreign keys: books.genre_id → genres.genre_id; copies.isbn → books.isbn; borrowings.member_id → members.member_id; borrowings.barcode → copies.barcode.
>

| Rule | Constraint Type | Enforceable |
|---|---|---|
| Member borrows at most 5 copies at once | — | No — needs a trigger or application check (count of open borrowings per member) |
| Due date = borrow_date + 14 days | DEFAULT / generated column | Partially — could use `due_date DATE GENERATED ALWAYS AS (borrow_date + 14) STORED`, or app logic |
| A copy can't be borrowed if not yet returned | — | No — needs a trigger or app-level check (query for open borrowings on that barcode before insert) |
| Every book belongs to exactly one genre | NOT NULL + FK | Yes |
| Every copy belongs to a valid book | NOT NULL + FK | Yes |

6. **Write the CREATE TABLE statements** for at least the `books`, `copies`, and `borrowings` tables with full constraints.

```sql
CREATE TABLE books (
    isbn     CHAR(13)     PRIMARY KEY,
    title    VARCHAR(200) NOT NULL,
    pub_year INTEGER      NOT NULL CHECK (pub_year BETWEEN 1450 AND 2100),
    genre_id INTEGER      NOT NULL REFERENCES genres(genre_id)
);

CREATE TABLE copies (
    barcode  VARCHAR(20)  PRIMARY KEY,
    isbn     CHAR(13)     NOT NULL REFERENCES books(isbn)
);

CREATE TABLE borrowings (
    borrowing_id SERIAL   PRIMARY KEY,
    member_id    INTEGER  NOT NULL REFERENCES members(member_id),
    barcode      VARCHAR(20) NOT NULL REFERENCES copies(barcode),
    borrow_date  DATE     NOT NULL DEFAULT CURRENT_DATE,
    due_date     DATE     NOT NULL,
    return_date  DATE,
    CHECK (return_date IS NULL OR return_date >= borrow_date)
);
```


## Submission Checklist

- [ ] Task 1: Key identification answers (Part 1)
- [ ] Task 2: Business rules table with 5 rules (Part 1)
- [ ] Task 3: Integrity violation predictions with explanations (Part 1)
- [ ] Task 4: Foreign key action analysis (Part 1)
- [ ] Theory Review Questions answered (Part 2)
- [ ] SQL Practice — constraint predictions and bookstore CREATE TABLE (Part 3)
- [ ] Library System design exercise (Part 4)
