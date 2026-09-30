CREATE TABLE categories (
    category_id   SERIAL       PRIMARY KEY,
    category_name VARCHAR(50)  NOT NULL UNIQUE,
    description   TEXT
);

CREATE TABLE customers (
    customer_id   SERIAL        PRIMARY KEY,
    first_name    VARCHAR(50)   NOT NULL,
    last_name     VARCHAR(50)   NOT NULL,
    email         VARCHAR(254)  NOT NULL UNIQUE,
    phone         VARCHAR(20),
    street        VARCHAR(100)  NOT NULL,
    city          VARCHAR(50)   NOT NULL,
    postal_code   VARCHAR(10)   NOT NULL,
    country       VARCHAR(50)   NOT NULL DEFAULT 'Finland',
    registered_at TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE products (
    product_id     SERIAL         PRIMARY KEY,
    name           VARCHAR(100)   NOT NULL,
    description    TEXT,
    price          NUMERIC(10,2)  NOT NULL
                   CONSTRAINT products_price_positive CHECK (price > 0),
    weight_kg      NUMERIC(6,2)
                   CONSTRAINT products_weight_positive CHECK (weight_kg > 0),
    stock_quantity INTEGER        NOT NULL DEFAULT 0
                   CONSTRAINT products_stock_non_negative CHECK (stock_quantity >= 0),
    created_at     TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    category_id    INTEGER        NOT NULL
                   REFERENCES categories(category_id)
                   ON DELETE RESTRICT
                   ON UPDATE CASCADE
);

CREATE TABLE orders (
    order_id    SERIAL       PRIMARY KEY,
    customer_id INTEGER      NOT NULL
                REFERENCES customers(customer_id)
                ON DELETE RESTRICT
                ON UPDATE CASCADE,
    order_date  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    status      VARCHAR(20)  NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')),
    shipping_street      VARCHAR(100),
    shipping_city        VARCHAR(50),
    shipping_postal_code VARCHAR(10),
    shipping_country     VARCHAR(50)
);

CREATE TABLE order_items (
    order_id   INTEGER        NOT NULL
               REFERENCES orders(order_id)
               ON DELETE CASCADE
               ON UPDATE CASCADE,
    product_id INTEGER        NOT NULL
               REFERENCES products(product_id)
               ON DELETE RESTRICT
               ON UPDATE CASCADE,
    quantity   INTEGER        NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(10,2)  NOT NULL CHECK (unit_price > 0),
    PRIMARY KEY (order_id, product_id)
);