CREATE OR REPLACE PROCEDURE GET_SUPPLIER_ORDER_DETAILS
AS
    CURSOR supplier_cursor IS
        SELECT 
            SUP_OH.supplier_name,
            SUP_OH.supplier_contactname,
            SUP_OH.Contact_1,
            SUP_OH.Contact_2,
            SUP_OH.order_total_amount,
            COUNT(SUP_OH.order_header_id) AS Total_Orders
        FROM (
            SELECT 
                sup.supplier_name,
                sup.supplier_contactname,
                REGEXP_SUBSTR(sup.supplier_contact, '[^,]+', 1, 1) AS Contact_1,
                REGEXP_SUBSTR(sup.supplier_contact, '[^,]+', 1, 2) AS Contact_2,
                oh.order_total_amount,
                oh.order_header_id
            FROM 
                mcb_suppliers sup
            JOIN 
                mcb_order_headers oh ON sup.supplier_id = oh.supplier_id
        ) SUP_OH
        JOIN
            mcb_order_lines OL ON SUP_OH.order_header_id = OL.order_header_id
        GROUP BY 
            SUP_OH.supplier_name,
            SUP_OH.supplier_contactname,
            SUP_OH.Contact_1,
            SUP_OH.Contact_2,
            SUP_OH.order_total_amount;

    supplier_name VARCHAR2(100);
    supplier_contactname VARCHAR2(100);
    contact_1 VARCHAR2(50);
    contact_2 VARCHAR2(50);
    order_total_amount NUMBER;
    total_orders NUMBER;

BEGIN
    -- Print header
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Supplier Name | Supplier Contact Name | Contact No. 1 | Contact No. 2 | Order Total Amount | Total Orders');
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------');

    FOR supplier_rec IN supplier_cursor LOOP
        supplier_name := supplier_rec.supplier_name;
        supplier_contactname := supplier_rec.supplier_contactname;
        contact_1 := supplier_rec.Contact_1;
        contact_2 := supplier_rec.Contact_2;
        order_total_amount := supplier_rec.order_total_amount;
        total_orders := supplier_rec.Total_Orders;
        
        DBMS_OUTPUT.PUT_LINE(
            supplier_name || ' | ' || 
            supplier_contactname || ' | ' || 
            contact_1 || ' | ' || 
            contact_2 || ' | ' || 
            TO_CHAR(order_total_amount, '999,999.99') || ' | ' || 
            total_orders
        );
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------');
END;
/



exec GET_SUPPLIER_ORDER_DETAILS;
