# Week 38 — Conceptual Data Modelling: Exercises

> [!IMPORTANT]
> ***How to Complete These Exercises***
> Write your answers directly in the highlighted **Your Answer** / **Your SQL** fields below each task. Replace the placeholder text with your own work before submitting.

These exercises accompany the Week 38 Theory material. Refer to the theory sections indicated in brackets when you need help.

---

## Exercise 1: TrailShop Project Task — Create the ER Diagram

**Goal:** Create a complete Entity-Relationship diagram for the TrailShop database using crow's foot notation.

### Instructions

Using the entity descriptions from Theory Section 12, create an ER diagram that includes:

1. **All five entities**: Category, Product, Customer, Order, OrderItem
2. **All attributes** for each entity (as listed in Section 12.1)
3. **Primary keys** clearly marked (underline or "PK" label)
4. **Foreign keys** clearly marked (dashed underline or "FK" label)
5. **Relationships** between entities with:
   - Relationship name (verb)
   - Crow's foot notation showing cardinality and participation
6. **Identify weak entities** — mark OrderItem as a weak entity

### Requirements

- Use crow's foot notation (see Theory Section 9)
- You may use any tool: draw.io, Lucidchart, ERDPlus, dbdiagram.io, or even pen and paper (photograph and submit)
- The diagram must be readable — avoid crossing lines where possible
- Include a brief legend explaining your notation if using pen and paper

### Deliverables

- The ER diagram (image or link to online tool)
- A short written paragraph (3–5 sentences) explaining one design decision you made — for example, why OrderItem is a weak entity, or why `unit_price` is stored in OrderItem instead of being looked up from Product.

> [!NOTE]
> ***Your Answer***
>
> The unit_price is stored in OrderItem instead of being looked up from Product, because product prices change over time. If an old order read the current price from the Product table, its total would change every time the price changed, and the order history would be wrong. Storing the price at the moment of purchase keeps each order a correct historical record. This is why unit_price is not a derived attribute, even though it looks like one.
>
>
>
>

---

## Exercise 2: Theory Review Questions

Answer each question in 2–4 sentences. Reference the relevant theory section.

1. Why should you create a conceptual data model before writing SQL? Give two specific reasons. *(Section 1)*

> [!NOTE]
> ***Your Answer***
>
> First, changing a database after it holds production data is expensive and risky, so it is much cheaper to find design mistakes on a diagram. A conceptual model helps to know which data exists, how it relates, and which rules govern it. This prevents problems like duplicated data, overloaded tables, and a schema that can't grow to include new things such as suppliers or reviews.
>
>
>
>

2. What is the difference between the conceptual level and the logical level of a data model? *(Section 2)*

> [!NOTE]
> ***Your Answer***
>
> The conceptual level is a technology-independent view of all the organization's data: entities, attributes, relationships, and business rules. The logical level translates that into a specific type of data model, such as relational tables with columns, data types, primary keys, foreign keys, and constraints. The logical level still doesn't depend on a particular DBMS product.
>
>
>
>

3. Explain logical data independence with an example. *(Section 3)*

> [!NOTE]
> ***Your Answer***
>
> Logical data independence means the conceptual schema can change without breaking users' external views. For example, if products is split into products and product_details, the warehouse view can be redefined to join the two tables. The warehouse staff see exactly the same data as before.
>
>
>
>

4. Explain physical data independence with an example. *(Section 3)*

> [!NOTE]
> ***Your Answer***
>
> Physical data independence means storage details can change without affecting the conceptual schema or the external views. For example, adding an index on products.name or moving the database to a faster disk changes performance, but every existing query and view keeps working unchanged.
>
>
>
>

5. What is the difference between a strong entity and a weak entity? Give one example of each (not from TrailShop). *(Section 5)*

> [!NOTE]
> ***Your Answer***
>
> A strong entity can be uniquely identified by its own attributes, while a weak entity needs its owner entity's key to be identified. A Book (identified by ISBN) is a strong entity. A Room is a weak entity, because "Room 101" exists in many buildings and needs building_id + room_number to be unique.
>
>
>
>

6. What is a composite attribute? How does it differ from a multivalued attribute? Give an example of each. *(Section 6)*

> [!NOTE]
> ***Your Answer***
>
> A composite attribute can be split into meaningful parts but holds one value per instance. For example, address splits into street, city, postal_code, and country. A multivalued attribute can hold several values for one instance, such as a customer with several phone numbers. A composite attribute becomes several columns, while a multivalued attribute becomes a separate table.
>
>
>
>

7. What is a derived attribute? Why is it usually not stored in the database? *(Section 6)*

> [!NOTE]
> ***Your Answer***
>
> A derived attribute is calculated from other attributes, like age from date_of_birth or a line total from quantity × unit_price. It usually isn't stored because the stored value can become inconsistent with its source data. Computing it in a query always gives the correct value.
>
>
>
>

8. Explain the difference between a binary relationship and a unary (recursive) relationship. Give an example of each. *(Section 7)*
> [!NOTE]
> ***Your Answer***
>
> *(Write your answer here.)*
>A binary relationship connects two different entity types, for example Customer places Order. A unary (recursive) relationship connects an entity type to itself, for example Employee manages Employee, where the manager is also an employee.




9. What is the difference between an identifying relationship and a non-identifying relationship? How does this affect the child table's primary key? *(Section 7)*
> [!NOTE]
> ***Your Answer***
>
> *(Write your answer here.)*
>In an identifying relationship, the parent's primary key becomes part of the child's primary key. For example, order_items has the primary key (order_id, product_id). In a non-identifying relationship, the foreign key is just a regular column, for example products.category_id, and the child has its own independent primary key.




10. In crow's foot notation, what does the following endpoint mean: a circle followed by a crow's foot (fork)? *(Section 9)*

> [!NOTE]
> ***Your Answer***
>
> *(Write your answer here.)*
>This endpoint means zero or many: participation is optional (min 0), and the maximum is many (N).
>
>
>

12. Why can't a many-to-many (M:N) relationship be directly implemented in a relational database? What is the solution? *(Section 10)*

> [!NOTE]
> ***Your Answer***
>
> *(Write your answer here.)*
>A single cell can't hold multiple foreign keys. We can't store one order_id in products because a product appears in many orders, and we can't store one product_id in orders because an order has many products. The solution is a junction table, such as OrderItem, that holds foreign keys to both entities. This turns the M:N relationship into two 1:N relationships.
>
>
>

12. A business rule states: "Every employee must belong to exactly one department, and every department must have at least one employee." Express this using min-max notation for both sides. *(Section 8)*

> [!NOTE]
> ***Your Answer***
>
> *(Write your answer here.)*
>Employee (1,1) ──belongs to── (1,N) Department.
Each employee participates exactly once (1,1). Each department participates at least once and possibly many times (1,N).
>
>
>

---

## Exercise 3: ER Diagram Reading Exercise

### Diagram A: Library System

Study the following ER description and answer the questions below.

```
┌──────────┐                        ┌──────────┐
│  AUTHOR  │──||──────O<────────────│   BOOK   │
└──────────┘                        └─────┬────┘
                                          │
                                    ||    │
                                          │
                                    O<    │
                                          │
                                   ┌──────┴─────┐
                                   │    LOAN     │
                                   └──────┬──────┘
                                          │
                                    ||    │
                                          │
                                    O<    │
                                          │
                                   ┌──────┴──────┐
                                   │   MEMBER    │
                                   └─────────────┘
```

Relationships (in crow's foot):
- Author `──||──────O<──` Book
- Book `──||──────O<──` Loan
- Member `──||──────O<──` Loan

**Questions:**

a) Can an author exist without having written any books? Explain using the notation.
> [!NOTE]
> ***Your Answer***
>
> *(Write your answer here.)*
>Yes. The endpoint next to Book is O< (zero or many), so an author can have zero books.
>
>
>

b) Can a book exist without being loaned? Explain using the notation.
> [!NOTE]
> ***Your Answer***
>
> *(Write your answer here.)*
>Yes. The endpoint next to Loan is O< (zero or many), so a book can have zero loans.
>
>
>

c) What type of entity is Loan in this diagram? Is it a junction/associative entity? Why?


> [!NOTE]
> ***Your Answer***
>
> *(Write your answer here.)*
>Loan is an associative (junction) entity. It resolves the M:N relationship between Book and Member: a member can borrow many books, and a book can be borrowed by many members over time. It also holds relationship-specific data such as dates.
>
>
>

d) What is the cardinality of the Author-Book relationship? Is this realistic? What might be a more accurate model?


> [!NOTE]
> ***Your Answer***
>
> *(Write your answer here.)*
>Author–Book is 1:N, so each book has exactly one author. This is unrealistic because many books have co-authors. A better model is M:N with a BookAuthor junction entity, which could include an author_order attribu
>
>
>

e) What attributes would you add to the Loan entity?


> [!NOTE]
> ***Your Answer***
>
> *(Write your answer here.)*
>Loan attributes: loan_id (PK), book_id (FK), member_id (FK), loan_date, due_date, return_date (optional, stays empty until the book is returned), and optionally fine_amount.
>
>
>

### Diagram B: School System

```
STUDENT ──O|──────O<── ENROLLMENT ──>|──||── COURSE
                                        │
                                    ||  │
                                        │
                                    O<  │
                                        │
                                   TEACHER
```

Relationships:
- Student `──O|──────O<──` Enrollment (a student may have zero or many enrollments)
- Enrollment `──||──────||──` Course (each enrollment is for exactly one course)
- Teacher `──||──────O<──` Course (each course has zero or many sections, each taught by exactly one teacher)

**Questions:**

a) Can a student exist without being enrolled in any course?


> [!NOTE]
> ***Your Answer***
>
> *(Write your answer here.)*
>Yes. The endpoint next to Enrollment is O<, so a student can have zero enrollments.
>
>
>

b) Can a course exist without having any enrolled students?


> [!NOTE]
> ***Your Answer***
>
> *(Write your answer here.)*
>No, according to the diagram. The endpoint next to Enrollment on the Course side is >| (one or many), which means every course must have at least one enrollment. 
>
>
>

c) What is the cardinality between Student and Course (through Enrollment)?


> [!NOTE]
> ***Your Answer***
>
> *(Write your answer here.)*
>Many-to-many (M:N). A student can take many courses, and a course can have many students. Enrollment resolves this.
>
>
>

d) Can a teacher exist without teaching any courses?


> [!NOTE]
> ***Your Answer***
>
> *(Write your answer here.)*
>
>Yes. The endpoint next to Course is O< (zero or many), so a teacher can teach zero courses.
>
>

e) Is the Teacher-Course relationship 1:1 or 1:N? What does this imply about team teaching?


> [!NOTE]
> ***Your Answer***
>
> *(Write your answer here.)*
>It is 1:N: one teacher teaches many courses, but each course has exactly one teacher. This means team teaching isn't possible. Supporting it would need an M:N relationship with a CourseTeacher junction entity.
>
>
>

---

## Exercise 4: ER Diagram Creation — Gym/Fitness Center

### Scenario

FitZone is a local gym and fitness center. They need a database to manage their operations. Here are the business rules:

1. The gym has **members**. Each member has an ID, first name, last name, email, phone, date of birth, and membership start date.

2. The gym offers **membership plans** (e.g., "Basic", "Premium", "Student"). Each plan has a plan ID, name, monthly price, and description. Each member subscribes to exactly one plan. A plan can have many members.

3. The gym has **trainers** (employees who lead classes). Each trainer has an ID, first name, last name, specialization (e.g., "Yoga", "CrossFit"), and hire date.

4. The gym offers **classes** (e.g., "Morning Yoga", "HIIT Blast"). Each class has an ID, name, day of the week, start time, end time, and maximum capacity. Each class is led by exactly one trainer, but a trainer can lead many classes.

5. Members can **register** for classes. A member can register for many classes, and a class can have many registered members. The registration records the registration date.

6. The gym has **equipment** (treadmills, dumbbells, etc.). Each piece of equipment has an ID, name, type, purchase date, and status ("working", "maintenance", "retired").

7. When equipment breaks, a **maintenance request** is created. Each request has an ID, request date, description of the problem, status ("open", "in progress", "closed"), and resolution date. Each request is for exactly one piece of equipment. One piece of equipment can have many maintenance requests over time.

### Task

1. Identify all entities and their attributes (including key attributes).

> [!NOTE]
> ***Your Answer***
>
> *(Write your answer here.)*
>Member: member_id (PK), first_name, last_name, email, phone, date_of_birth, membership_start_date, plan_id (FK)
> 
MembershipPlan: plan_id (PK), plan_name, monthly_price, description

Trainer: trainer_id (PK), first_name, last_name, specialization, hire_date

GymClass: class_id (PK), class_name, day_of_week, start_time, end_time, max_capacity, trainer_id (FK)

ClassRegistration: member_id (PK, FK), class_id (PK, FK), registration_date

Equipment: equipment_id (PK), name, type, purchase_date, status

MaintenanceRequest: request_id (PK), request_date, problem_description, status, resolution_date (optional), equipment_id (FK)

>
>
>

2. Identify all relationships with their cardinality and participation constraints.

> [!NOTE]
> ***Your Answer***
>
> *(Write your answer here.)*
>
| Relationship | Crow's foot | Meaning |
|---|---|---|
| MembershipPlan *has* Member | `Plan ──\|\|──O<── Member` | Each member has exactly one plan; a plan has zero or many members |
| Trainer *leads* GymClass | `Trainer ──\|\|──O<── GymClass` | Each class has exactly one trainer; a trainer leads zero or many classes |
| Member *makes* ClassRegistration | `Member ──\|\|──O<── ClassRegistration` | A member has zero or many registrations; each registration belongs to one member |
| GymClass *has* ClassRegistration | `GymClass ──\|\|──O<── ClassRegistration` | A class has zero or many registrations; each registration is for one class |
| Equipment *has* MaintenanceRequest | `Equipment ──\|\|──O<── MaintenanceRequest` | Equipment has zero or many requests; each request is for exactly one piece of equipment |
>
>
>

3. Draw a complete ER diagram using crow's foot notation.

> [!NOTE]
> ***Your Answer***
>
> *(Add a link to your image here)*
>
>
>
>

4. Identify any entity that might be considered a weak entity or a junction/associative entity. Justify your answer.

> [!NOTE]
> ***Your Answer***
>
> *(Write your answer here.)*
>
ClassRegistration is a junction (associative) entity and also a weak entity. It has no identifier of its own: it is identified by (member_id, class_id), and it only exists because of a member and a class. MaintenanceRequest is a dependent entity because it can't exist without equipment. It is not weak, however, because it has its own request_id
>
>
>

5. Are there any M:N relationships? If so, what junction entity resolves them?

> [!NOTE]
> ***Your Answer***
>
> *(Write your answer here.)*
>
> Yes, there is one: Member ↔ GymClass. A member can register for many classes, and a class can have many members. The ClassRegistration junction entity resolves it, and it also stores registration_date.
>
>
>
---

## Exercise 5: Find and Correct the Errors

The following ER diagram description contains **four errors**. Find each error, explain why it's wrong, and provide the correction.

### Scenario: Online Bookstore

**Entities and attributes:**

1. **Books**
   - book_id (PK)
   - title
   - author_name
   - price
   - genres (stores "Fiction, Mystery, Thriller" as a comma-separated string)

2. **Customer**
   - customer_id (PK)
   - full_name
   - address

3. **Purchase**
   - purchase_id (PK)
   - purchase_date
   - total_amount

**Relationships:**
- Books to Customer: M:N (implemented directly — no junction table)
- Customer to Purchase: 1:N (one customer, many purchases)
- Books to Purchase: no relationship defined

### Your Task

Find the four errors in this design and for each one:

a) State what the error is
> [!NOTE]
> ***Your Answer***
>
> *(Write your answer here.)*
>
>
>
>

b) Explain why it's a problem (reference the relevant theory section)

> [!NOTE]
> ***Your Answer***
>
> *(Write your answer here.)*
>Yes. The endpoint next to Enrollment is O<, so a student can have zero enrollments.
>
>
>

c) Describe how to fix it

> [!NOTE]
> ***Your Answer***
>
> *(Write your answer here.)*

**Error 1: Entity named "Books" (plural)**

The entity name is plural. entities should use singular nouns, because an entity type describes one instance.Rename it to Book.

**Error 2: genres stored as a comma-separated string**

A multivalued attribute is stored in a single field.This violates atomicity and 1NF. It becomes hard to query, for example "all Mystery books," and hard to keep consistent. Create a Genre entity and a BookGenre junction table (book_id, genre_id), since this is an M:N relationship.

**Error 3: Books–Customer M:N implemented directly without a junction table**

An M:N relationship is left unresolved. An M:N relationship can't be implemented directly, because there's no place to store multiple foreign keys.
Remove the direct Book–Customer relationship. Customers are already linked to books through their purchases, so no separate link is needed.

Error 4: No relationship between Books and Purchase

A purchase has no way to record which books were bought. A purchase and a book form an M:N relationship: one purchase contains many books, and one book appears in many purchases (Section 10). Without it, the purchase data is useless. Add a PurchaseItem junction entity: purchase_id (PK, FK), book_id (PK, FK), quantity, unit_price.

**Hints:** Think about multivalued attributes, M:N relationships, entity naming conventions, and missing relationships.

---

## Submission Checklist

- [ ] Exercise 1: ER diagram + design decision paragraph
- [ ] Exercise 2: All 12 theory review answers
- [ ] Exercise 3: All questions answered for both Diagram A and Diagram B
- [ ] Exercise 4: Entity list, relationship list, ER diagram, and justifications
- [ ] Exercise 5: Four errors identified with explanations and corrections
