CREATE OR REPLACE PROCEDURE ORDER_SUMMARY_REPORT
IS
    CURSOR c_order_summary IS
        SELECT 
            ORDER_REFERENCE AS "Order Reference",
            ORDER_PERIOD AS "Order Period",
            SUPPLIER_NAME AS "Supplier Name",
            TO_CHAR(ORDER_TOTAL_AMOUNT, '99,999,990.00') AS "Order Total Amount",
            CASE 
                WHEN EXISTS (SELECT 1 FROM MCB_ORDER_HEADERS WHERE ORDER_REF = REGEXP_REPLACE(INVOICE_REFERENCE, 'INV_', '')) 
                    THEN ORDER_STATUS
                WHEN EXISTS (SELECT 1 FROM MCB_ORDER_LINES WHERE ORDER_LINE_REF = REPLACE(SUBSTR(INVOICE_REFERENCE, INSTR(INVOICE_REFERENCE, '_') + 1), '.', '-'))   
                    THEN ORDER_LINESTATUS
                ELSE ORDER_STATUS 
            END AS "Order Status",
            INVOICE_REFERENCE AS "Invoice Reference",
            TO_CHAR(SUM(INVOICE_AMOUNT), '99,999,990.00') AS "Invoice Total Amount",
            CASE 
                WHEN MAX(INVOICE_STATUS) = 'Paid' THEN 'OK'
                WHEN MAX(INVOICE_STATUS) = 'Pending' THEN 'To follow up'
                ELSE 'To verify'
            END AS "Action"
        FROM
            (
                SELECT DISTINCT
                    PO_WITH_INV.ORDER_REFERENCE,
                    PO_WITH_INV.ORDER_PERIOD,
                    PO_WITH_INV.SUPPLIER_NAME,
                    PO_WITH_INV.ORDER_TOTAL_AMOUNT,
                    PO_WITH_INV.ORDER_STATUS,
                    PO_WITH_INV.ORDER_LINESTATUS,
                    INV.INVOICE_REF AS INVOICE_REFERENCE,
                    INV.INVOICE_AMOUNT,
                    INV.INVOICE_STATUS,
                    PO_WITH_INV.PH_HEADER_ID,
                    INV.ORDER_HEADER_ID
                FROM 
                    MCB_INVOICES INV
                JOIN
                    ( 
                        SELECT 
                            REGEXP_REPLACE(SUBSTR(PL.ORDER_LINE_REF, 1, INSTR(PL.ORDER_LINE_REF, '-') - 1), '[^0-9]', '') AS ORDER_REFERENCE,
                            TO_CHAR(TO_DATE(M_PH.ORDER_DATE, 'DD-MM-YY'), 'MON-YYYY') AS ORDER_PERIOD,
                            (SELECT INITCAP(SUPPLIER_NAME) 
                             FROM MCB_SUPPLIERS SUP 
                             WHERE SUP.SUPPLIER_ID = M_PH.SUPPLIER_ID) AS SUPPLIER_NAME,
                            M_PH.ORDER_TOTAL_AMOUNT,
                            M_PH.ORDER_STATUS,
                            PL.ORDER_HEADER_ID,
                            PL.ORDER_LINESTATUS,
                            M_PH.ORDER_HEADER_ID AS PH_HEADER_ID
                        FROM 
                            MCB_ORDER_LINES PL
                        JOIN 
                            MCB_ORDER_HEADERS M_PH 
                        ON 
                            PL.ORDER_HEADER_ID = M_PH.ORDER_HEADER_ID
                    ) PO_WITH_INV
                ON
                    PO_WITH_INV.ORDER_HEADER_ID = INV.ORDER_HEADER_ID
                GROUP BY
                    PO_WITH_INV.ORDER_REFERENCE,
                    PO_WITH_INV.ORDER_PERIOD,
                    PO_WITH_INV.SUPPLIER_NAME,
                    PO_WITH_INV.ORDER_TOTAL_AMOUNT,
                    PO_WITH_INV.ORDER_STATUS,
                    PO_WITH_INV.ORDER_LINESTATUS,
                    INV.INVOICE_REF,
                    INV.INVOICE_AMOUNT,
                    INV.INVOICE_STATUS,
                    PO_WITH_INV.PH_HEADER_ID,
                    INV.ORDER_HEADER_ID
            )
        GROUP BY 
            ORDER_REFERENCE,
            ORDER_PERIOD,
            SUPPLIER_NAME,
            ORDER_TOTAL_AMOUNT,
            ORDER_STATUS,
            ORDER_LINESTATUS,
            INVOICE_REFERENCE,
            PH_HEADER_ID
        ORDER BY TO_DATE(ORDER_PERIOD, 'MON-YYYY') DESC;

BEGIN
    -- Loop through the cursor and display each record in a row and column format
    DBMS_OUTPUT.PUT_LINE(RPAD('Order Reference', 20) || RPAD('Order Period', 15) || RPAD('Supplier Name', 30) || RPAD('Order Total Amount', 20) || 
                         RPAD('Order Status', 20) || RPAD('Invoice Reference', 20) || RPAD('Invoice Total Amount', 20) || RPAD('Action', 20));
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------------------------------------------------------' ||
                         '------------------------------------------------------------------------------------');

    FOR record IN c_order_summary LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(record."Order Reference", 20) || 
                             RPAD(record."Order Period", 15) || 
                             RPAD(record."Supplier Name", 30) || 
                             RPAD(record."Order Total Amount", 20) || 
                             RPAD(record."Order Status", 20) || 
                             RPAD(record."Invoice Reference", 20) || 
                             RPAD(record."Invoice Total Amount", 20) || 
                             RPAD(record."Action", 20));
    END LOOP;
END ORDER_SUMMARY_REPORT;
/

exec ORDER_SUMMARY_REPORT;
