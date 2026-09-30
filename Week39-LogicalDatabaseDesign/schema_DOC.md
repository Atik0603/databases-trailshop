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
